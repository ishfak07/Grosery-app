const admin = require("firebase-admin");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {HttpsError, onCall} = require("firebase-functions/v2/https");

admin.initializeApp();

const notificationChannelId = "puttalam_drop_alerts";

exports.sendPushForNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const notification = snapshot.data();
    const title = notification.title || "Puttalam Drop";
    const body = notification.body || "You have a new update.";
    const tokens = await resolveTokens(notification);
    if (tokens.length === 0) {
      return;
    }

    for (const tokenBatch of chunk(tokens, 500)) {
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokenBatch,
        notification: {
          title,
          body,
        },
        android: {
          priority: "high",
          notification: {
            channelId: notificationChannelId,
            defaultSound: true,
            priority: "max",
            visibility: "public",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
            "apns-push-type": "alert",
          },
          payload: {
            aps: {
              alert: {
                title,
                body,
              },
              sound: "default",
            },
          },
        },
        data: {
          notificationId: event.params.notificationId,
          title,
          body,
          type: notification.type || "",
          relatedId: notification.relatedId || "",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      });
      await removeInvalidTokens(
        tokenBatch,
        response.responses,
        notification,
      );
    }
  },
);

exports.requestPasswordReset = onCall(async (request) => {
  const phone = normalizeSriLankanPhone(request.data?.phone || "");
  assertSriLankanMobile(phone);

  const hiddenEmail = hiddenEmailForPhone(phone);
  let userRecord;
  try {
    userRecord = await admin.auth().getUserByEmail(hiddenEmail);
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      throw new HttpsError(
        "not-found",
        "No account exists for that phone number.",
      );
    }
    throw error;
  }

  const active = await findLatestResetRequest(hiddenEmail, [
    "pending",
    "approved",
  ]);
  if (active) {
    return resetStatusPayload(
      active.id,
      active.data(),
      passwordResetStatusMessage(active.data().status),
    );
  }

  const userDoc = await admin
    .firestore()
    .collection("users")
    .doc(userRecord.uid)
    .get();
  const userProfile = userDoc.exists ? userDoc.data() : {};
  const requestRef = admin.firestore().collection("password_reset_requests").doc();
  const now = admin.firestore.Timestamp.now();
  const resetRequest = {
    requestId: requestRef.id,
    userId: userRecord.uid,
    customerName: userProfile.fullName || userRecord.displayName || "",
    phone,
    hiddenEmail,
    status: "pending",
    createdAt: now,
    updatedAt: now,
    approvedBy: "",
    rejectedBy: "",
  };

  const notificationRef = admin.firestore().collection("notifications").doc();
  const batch = admin.firestore().batch();
  batch.set(requestRef, resetRequest);
  batch.set(notificationRef, {
    notificationId: notificationRef.id,
    userId: "",
    recipientRole: "admin",
    title: "Password reset request",
    body: `${resetRequest.customerName || phone} requested password reset`,
    type: "password_reset",
    relatedId: requestRef.id,
    isRead: false,
    createdAt: now,
  });
  await batch.commit();

  return resetStatusPayload(
    requestRef.id,
    resetRequest,
    "Password reset request sent. Wait for admin approval.",
  );
});

exports.getPasswordResetStatus = onCall(async (request) => {
  const phone = normalizeSriLankanPhone(request.data?.phone || "");
  assertSriLankanMobile(phone);

  const hiddenEmail = hiddenEmailForPhone(phone);
  const latest = await findLatestResetRequest(hiddenEmail);
  if (!latest) {
    throw new HttpsError(
      "not-found",
      "No reset request found. Submit a reset request first.",
    );
  }

  const data = latest.data();
  return resetStatusPayload(
    latest.id,
    data,
    passwordResetStatusMessage(data.status),
  );
});

exports.approvePasswordReset = onCall(async (request) => {
  const adminUid = await requireAdmin(request);
  const requestId = assertRequestId(request.data?.requestId);
  const requestRef = admin
    .firestore()
    .collection("password_reset_requests")
    .doc(requestId);
  const snapshot = await requestRef.get();
  if (!snapshot.exists) {
    throw new HttpsError("not-found", "Password reset request not found.");
  }
  if (snapshot.get("status") !== "pending") {
    throw new HttpsError(
      "failed-precondition",
      "Only pending reset requests can be approved.",
    );
  }

  const now = admin.firestore.Timestamp.now();
  await requestRef.update({
    status: "approved",
    approvedBy: adminUid,
    approvedAt: now,
    updatedAt: now,
  });
  return {ok: true};
});

exports.rejectPasswordReset = onCall(async (request) => {
  const adminUid = await requireAdmin(request);
  const requestId = assertRequestId(request.data?.requestId);
  const requestRef = admin
    .firestore()
    .collection("password_reset_requests")
    .doc(requestId);
  const snapshot = await requestRef.get();
  if (!snapshot.exists) {
    throw new HttpsError("not-found", "Password reset request not found.");
  }
  if (snapshot.get("status") !== "pending") {
    throw new HttpsError(
      "failed-precondition",
      "Only pending reset requests can be rejected.",
    );
  }

  const now = admin.firestore.Timestamp.now();
  await requestRef.update({
    status: "rejected",
    rejectedBy: adminUid,
    rejectedAt: now,
    updatedAt: now,
  });
  return {ok: true};
});

exports.completeApprovedPasswordReset = onCall(async (request) => {
  const phone = normalizeSriLankanPhone(request.data?.phone || "");
  const newPassword = `${request.data?.newPassword || ""}`;
  assertSriLankanMobile(phone);
  if (newPassword.length < 6) {
    throw new HttpsError(
      "invalid-argument",
      "Password must be at least 6 characters.",
    );
  }

  const hiddenEmail = hiddenEmailForPhone(phone);
  const latest = await findLatestResetRequest(hiddenEmail, ["approved"]);
  if (!latest) {
    throw new HttpsError(
      "failed-precondition",
      "Admin has not approved this password reset yet.",
    );
  }

  const userRecord = await admin.auth().getUserByEmail(hiddenEmail);
  const now = admin.firestore.Timestamp.now();
  await admin.auth().updateUser(userRecord.uid, {password: newPassword});
  await latest.ref.update({
    status: "completed",
    completedAt: now,
    updatedAt: now,
  });
  return {ok: true};
});

exports.createDeliveryBoyAccount = onCall(async (request) => {
  const adminUid = await requireAdmin(request);
  const fullName = assertName(request.data?.fullName);
  const phone = normalizeSriLankanPhone(request.data?.phone || "");
  const password = assertPassword(request.data?.password);
  assertSriLankanMobile(phone);

  const hiddenEmail = hiddenEmailForPhone(phone);
  let userRecord;
  try {
    userRecord = await admin.auth().createUser({
      email: hiddenEmail,
      password,
      displayName: fullName,
      disabled: false,
    });
  } catch (error) {
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError(
        "already-exists",
        "An account already exists for this phone number.",
      );
    }
    throw error;
  }

  const now = admin.firestore.Timestamp.now();
  await admin.firestore().collection("users").doc(userRecord.uid).set({
    uid: userRecord.uid,
    fullName,
    phone,
    hiddenEmail,
    role: "delivery_boy",
    address: "",
    createdAt: now,
    updatedAt: now,
    isPhoneVerified: true,
    isBlocked: false,
    preferredLanguageCode: "en",
    createdBy: adminUid,
  }, {merge: true});

  return {uid: userRecord.uid};
});

exports.createDeliveryBoy = exports.createDeliveryBoyAccount;

exports.updateDeliveryBoyAccount = onCall(async (request) => {
  await requireAdmin(request);
  const uid = assertUid(request.data?.uid);
  const fullName = assertName(request.data?.fullName);
  const phone = normalizeSriLankanPhone(request.data?.phone || "");
  const password = `${request.data?.password || ""}`;
  const hasActiveStatus =
    typeof request.data?.isActive === "boolean" ||
    typeof request.data?.isBlocked === "boolean";
  const isActive = typeof request.data?.isActive === "boolean" ?
    request.data.isActive === true :
    request.data?.isBlocked !== true;
  assertSriLankanMobile(phone);
  if (password && password.length < 6) {
    throw new HttpsError(
      "invalid-argument",
      "Password must be at least 6 characters.",
    );
  }

  const userRef = admin.firestore().collection("users").doc(uid);
  const userDoc = await userRef.get();
  if (!userDoc.exists || userDoc.get("role") !== "delivery_boy") {
    throw new HttpsError("not-found", "Delivery boy account not found.");
  }

  const hiddenEmail = hiddenEmailForPhone(phone);
  const authUpdate = {
    email: hiddenEmail,
    displayName: fullName,
  };
  if (password) {
    authUpdate.password = password;
  }
  if (hasActiveStatus) {
    authUpdate.disabled = !isActive;
  }
  try {
    await admin.auth().updateUser(uid, authUpdate);
  } catch (error) {
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError(
        "already-exists",
        "Another account already uses this phone number.",
      );
    }
    throw error;
  }

  const profileUpdate = {
    fullName,
    phone,
    hiddenEmail,
    updatedAt: admin.firestore.Timestamp.now(),
  };
  if (hasActiveStatus) {
    profileUpdate.isBlocked = !isActive;
  }
  await userRef.update(profileUpdate);
  return {ok: true};
});

exports.updateDeliveryBoy = exports.updateDeliveryBoyAccount;

exports.setDeliveryBoyActive = onCall(async (request) => {
  await requireAdmin(request);
  const uid = assertUid(request.data?.uid);
  const isActive = request.data?.isActive === true;

  const userRef = admin.firestore().collection("users").doc(uid);
  const userDoc = await userRef.get();
  if (!userDoc.exists || userDoc.get("role") !== "delivery_boy") {
    throw new HttpsError("not-found", "Delivery boy account not found.");
  }

  await Promise.all([
    admin.auth().updateUser(uid, {disabled: !isActive}),
    userRef.update({
      isBlocked: !isActive,
      updatedAt: admin.firestore.Timestamp.now(),
    }),
  ]);
  return {ok: true};
});

exports.markAssignedOrderDelivered = onCall(async (request) => {
  const deliveryBoy = await requireDeliveryBoy(request);
  const orderId = assertRequiredText(request.data?.orderId, "Order");
  const orderRef = admin.firestore().collection("orders").doc(orderId);
  const orderDoc = await orderRef.get();
  if (!orderDoc.exists) {
    throw new HttpsError("not-found", "Order not found.");
  }
  const order = orderDoc.data();
  if (order.assignedDeliveryBoyId !== deliveryBoy.uid) {
    throw new HttpsError(
      "permission-denied",
      "This order is not assigned to you.",
    );
  }
  if (order.orderStatus !== "Out for Delivery") {
    throw new HttpsError(
      "failed-precondition",
      "Only out-for-delivery orders can be marked delivered.",
    );
  }

  const now = admin.firestore.Timestamp.now();
  const deliveredOrder = {
    ...order,
    orderId: order.orderId || orderDoc.id,
    orderStatus: "Delivered",
    updatedAt: now,
  };
  const accountRecord = accountSaleRecordFromOrder(deliveredOrder, now);
  const notificationRef = admin.firestore().collection("notifications").doc();
  const batch = admin.firestore().batch();
  batch.update(orderRef, {
    orderStatus: "Delivered",
    updatedAt: now,
  });
  batch.set(
    admin.firestore().collection("account_sales").doc(orderDoc.id),
    accountRecord,
    {merge: true},
  );
  batch.set(notificationRef, {
    notificationId: notificationRef.id,
    userId: order.userId || "",
    recipientRole: "user",
    title: `Order ${orderDoc.id} delivered`,
    body: "Your order has been delivered.",
    type: "order",
    relatedId: orderDoc.id,
    isRead: false,
    createdAt: now,
  });
  await batch.commit();
  return {ok: true};
});

async function resolveTokens(notification) {
  if (notification.recipientRole === "admin") {
    const admins = await admin
      .firestore()
      .collection("users")
      .where("role", "==", "admin")
      .get();

    return uniqueTokens(
      admins.docs
        .filter((doc) => doc.get("isBlocked") !== true)
        .flatMap((doc) => tokensForUserDoc(doc)),
    );
  }

  if (
    notification.recipientRole === "broadcast" ||
    notification.recipientRole === "all"
  ) {
    const users = await admin
      .firestore()
      .collection("users")
      .where("role", "==", "user")
      .get();

    return uniqueTokens(
      users.docs
        .filter((doc) => doc.get("isBlocked") !== true)
        .flatMap((doc) => tokensForUserDoc(doc)),
    );
  }

  if (!notification.userId) {
    return [];
  }

  const user = await admin
    .firestore()
    .collection("users")
    .doc(notification.userId)
    .get();

  if (!user.exists || user.get("isBlocked") === true) {
    return [];
  }
  return uniqueTokens(tokensForUserDoc(user));
}

function tokensForUserDoc(doc) {
  const token = doc.get("fcmToken");
  const legacyTokens = doc.get("fcmTokens") || [];
  const savedTokens = Array.isArray(legacyTokens) ?
    legacyTokens :
    [legacyTokens];
  return [
    token,
    ...savedTokens,
  ];
}

function uniqueTokens(tokens) {
  return [
    ...new Set(
      tokens.filter((token) => typeof token === "string" && token),
    ),
  ];
}

function chunk(items, size) {
  const chunks = [];
  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }
  return chunks;
}

async function removeInvalidTokens(tokens, responses, notification) {
  const invalidTokens = tokens.filter((token, index) => {
    const errorCode = responses[index].error?.code;
    return errorCode === "messaging/registration-token-not-registered" ||
      errorCode === "messaging/invalid-registration-token";
  });

  if (invalidTokens.length === 0) {
    return;
  }

  if (notification.recipientRole === "admin") {
    const admins = await admin
      .firestore()
      .collection("users")
      .where("role", "==", "admin")
      .get();

    await Promise.all(
      admins.docs.map((doc) => removeInvalidTokensFromUserDoc(
        doc,
        invalidTokens,
      )),
    );
    return;
  }

  if (
    notification.recipientRole === "broadcast" ||
    notification.recipientRole === "all"
  ) {
    const users = await admin
      .firestore()
      .collection("users")
      .where("role", "==", "user")
      .get();

    await Promise.all(
      users.docs.map((doc) => removeInvalidTokensFromUserDoc(
        doc,
        invalidTokens,
      )),
    );
    return;
  }

  if (notification.userId) {
    const user = await admin
      .firestore()
      .collection("users")
      .doc(notification.userId)
      .get();
    if (user.exists) {
      await removeInvalidTokensFromUserDoc(user, invalidTokens);
    }
  }
}

async function removeInvalidTokensFromUserDoc(doc, invalidTokens) {
  const updates = {};
  if (invalidTokens.includes(doc.get("fcmToken"))) {
    updates.fcmToken = admin.firestore.FieldValue.delete();
  }

  const legacyTokens = doc.get("fcmTokens") || [];
  if (Array.isArray(legacyTokens) && legacyTokens.length > 0) {
    updates.fcmTokens = admin.firestore.FieldValue.arrayRemove(
      ...invalidTokens,
    );
  }

  if (Object.keys(updates).length > 0) {
    await doc.ref.update(updates);
  }
}

function normalizeSriLankanPhone(raw) {
  const compact = `${raw}`.trim().replace(/[\s\-()]/g, "");
  if (!compact) {
    return "";
  }
  if (compact.startsWith("+")) {
    return `+${compact.substring(1).replace(/[^0-9]/g, "")}`;
  }

  const digits = compact.replace(/[^0-9]/g, "");
  if (digits.length === 9) {
    return `+94${digits}`;
  }
  if (digits.startsWith("0") && digits.length >= 9) {
    return `+94${digits.substring(1)}`;
  }
  if (digits.startsWith("94")) {
    return `+${digits}`;
  }
  return `+${digits}`;
}

function localSriLankanDigits(phone) {
  const digits = normalizeSriLankanPhone(phone).replace(/[^0-9]/g, "");
  if (digits.startsWith("94") && digits.length > 2) {
    return digits.substring(2);
  }
  if (digits.startsWith("0") && digits.length > 1) {
    return digits.substring(1);
  }
  return digits;
}

function assertSriLankanMobile(phone) {
  if (!/^7[0-9]{8}$/.test(localSriLankanDigits(phone))) {
    throw new HttpsError(
      "invalid-argument",
      "Enter a valid Sri Lankan mobile number starting with 7.",
    );
  }
}

function assertRequiredText(value, label) {
  const text = `${value || ""}`.trim();
  if (!text) {
    throw new HttpsError("invalid-argument", `${label} is required.`);
  }
  return text;
}

function hiddenEmailForPhone(phone) {
  return `${normalizeSriLankanPhone(phone).replace(/[^0-9]/g, "")}@app.local`;
}

function assertRequestId(value) {
  const requestId = `${value || ""}`.trim();
  if (!requestId) {
    throw new HttpsError("invalid-argument", "Missing reset request.");
  }
  return requestId;
}

function assertUid(value) {
  const uid = `${value || ""}`.trim();
  if (!uid) {
    throw new HttpsError("invalid-argument", "Missing account id.");
  }
  return uid;
}

function assertName(value) {
  const name = `${value || ""}`.trim();
  if (!name) {
    throw new HttpsError("invalid-argument", "Full name is required.");
  }
  return name;
}

function assertPassword(value) {
  const password = `${value || ""}`;
  if (password.length < 6) {
    throw new HttpsError(
      "invalid-argument",
      "Password must be at least 6 characters.",
    );
  }
  return password;
}

async function requireAdmin(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Admin login is required.");
  }

  const adminDoc = await admin
    .firestore()
    .collection("users")
    .doc(request.auth.uid)
    .get();
  if (
    !adminDoc.exists ||
    adminDoc.get("role") !== "admin" ||
    adminDoc.get("isBlocked") === true
  ) {
    throw new HttpsError(
      "permission-denied",
      "Only admins can perform this action.",
    );
  }
  return request.auth.uid;
}

async function requireDeliveryBoy(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Delivery boy login is required.");
  }

  const userDoc = await admin
    .firestore()
    .collection("users")
    .doc(request.auth.uid)
    .get();
  if (
    !userDoc.exists ||
    userDoc.get("role") !== "delivery_boy" ||
    userDoc.get("isBlocked") === true
  ) {
    throw new HttpsError(
      "permission-denied",
      "Only assigned delivery boys can update delivery orders.",
    );
  }
  return {uid: request.auth.uid, profile: userDoc.data()};
}

function accountSaleRecordFromOrder(order, now) {
  const items = Array.isArray(order.items) ? order.items : [];
  const hasCartItems = items.length > 0;
  const hasPhotoList = !!order.uploadedImageUrl;
  const manualListText = `${order.manualListText || ""}`.trim();
  const hasManualList =
    manualListText.length > 0 ||
    `${order.orderNotes || ""}`.toLowerCase().includes("manual grocery list:");
  const hasShoppingList = hasPhotoList || hasManualList;
  const cartSalesAmount = nonNegativeNumber(order.cartItemsAmount);
  const photoListSalesAmount = nonNegativeNumber(order.photoListAmount);
  const manualListSalesAmount = nonNegativeNumber(order.manualListAmount);
  const manualSalesAmount = photoListSalesAmount + manualListSalesAmount;
  const deliveryCharge = nonNegativeNumber(order.deliveryCharge);
  const serviceCharge = nonNegativeNumber(order.serviceCharge);
  const itemSalesAmount = cartSalesAmount + manualSalesAmount;
  const chargeAmount = deliveryCharge + serviceCharge;
  const totalSalesAmount = itemSalesAmount + chargeAmount;
  const costAmount = 0;
  const expenseAmount = 0;

  return {
    recordId: order.orderId,
    orderId: order.orderId,
    userId: order.userId || "",
    customerName: order.customerName || "",
    customerPhone: order.customerPhone || "",
    customerAddress: order.customerAddress || "",
    orderMethod: orderMethodLabel(hasCartItems, hasPhotoList, hasManualList),
    hasCartItems,
    hasPhotoList,
    hasManualList,
    hasShoppingList,
    itemCount: items.reduce(
      (total, item) => total + Math.max(Number(item.quantity || 0), 0),
      0,
    ),
    cartSalesAmount,
    photoListSalesAmount,
    manualListSalesAmount,
    manualSalesAmount,
    manualSalesReviewed: !hasShoppingList ||
      order.listAmountsReviewed === true ||
      manualSalesAmount > 0,
    deliveryCharge,
    serviceCharge,
    itemSalesAmount,
    chargeAmount,
    totalSalesAmount,
    costAmount,
    expenseAmount,
    totalCostAmount: costAmount + expenseAmount,
    profitOrLoss: totalSalesAmount - costAmount - expenseAmount,
    paymentMethod: order.paymentMethod || "COD",
    paymentStatus: order.paymentStatus || "pending",
    orderStatus: "Delivered",
    adminNotes: order.adminNotes || "",
    accountNotes: "",
    orderCreatedAt: order.createdAt || now,
    deliveredAt: now,
    createdAt: now,
    updatedAt: now,
  };
}

function orderMethodLabel(hasCartItems, hasPhotoList, hasManualList) {
  const methods = [];
  if (hasCartItems) {
    methods.push("Cart checkout");
  }
  if (hasPhotoList) {
    methods.push("Photo list");
  }
  if (hasManualList) {
    methods.push("Typed list");
  }
  return methods.length > 0 ? methods.join(" + ") : "Custom order";
}

function nonNegativeNumber(value) {
  const number = Number(value || 0);
  return Number.isFinite(number) && number > 0 ? number : 0;
}

async function findLatestResetRequest(hiddenEmail, statuses) {
  const snapshot = await admin
    .firestore()
    .collection("password_reset_requests")
    .where("hiddenEmail", "==", hiddenEmail)
    .get();

  const docs = snapshot.docs
    .filter((doc) => !statuses || statuses.includes(doc.get("status")))
    .sort((a, b) => timestampMillis(b.get("createdAt")) -
      timestampMillis(a.get("createdAt")));
  return docs[0] || null;
}

function timestampMillis(value) {
  return value && typeof value.toMillis === "function" ? value.toMillis() : 0;
}

function resetStatusPayload(requestId, data, message) {
  return {
    requestId,
    status: data.status || "pending",
    phone: data.phone || "",
    customerName: data.customerName || "",
    message,
  };
}

function passwordResetStatusMessage(status) {
  switch (status) {
    case "approved":
      return "Admin approved your reset. Set a new password.";
    case "rejected":
      return "Admin rejected this reset request. Contact support.";
    case "completed":
      return "Password already updated. Login with the new password.";
    default:
      return "Waiting for admin approval.";
  }
}
