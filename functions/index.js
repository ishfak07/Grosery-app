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

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
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
        type: notification.type || "",
        relatedId: notification.relatedId || "",
      },
    });
    await removeInvalidTokens(tokens, response.responses, notification);
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

async function resolveTokens(notification) {
  if (notification.recipientRole === "admin") {
    const admins = await admin
      .firestore()
      .collection("users")
      .where("role", "==", "admin")
      .where("isBlocked", "==", false)
      .get();

    return uniqueTokens(
      admins.docs.flatMap((doc) => doc.get("fcmTokens") || []),
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

  return user.exists ? uniqueTokens(user.get("fcmTokens") || []) : [];
}

function uniqueTokens(tokens) {
  return [
    ...new Set(
      tokens.filter((token) => typeof token === "string" && token),
    ),
  ];
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

  const tokenRemoval = admin.firestore.FieldValue.arrayRemove(...invalidTokens);
  if (notification.recipientRole === "admin") {
    const admins = await admin
      .firestore()
      .collection("users")
      .where("role", "==", "admin")
      .get();

    await Promise.all(
      admins.docs.map((doc) => doc.ref.update({fcmTokens: tokenRemoval})),
    );
    return;
  }

  if (notification.userId) {
    await admin
      .firestore()
      .collection("users")
      .doc(notification.userId)
      .update({fcmTokens: tokenRemoval});
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
      "Only admins can approve password reset requests.",
    );
  }
  return request.auth.uid;
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
