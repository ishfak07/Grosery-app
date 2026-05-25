const admin = require("firebase-admin");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");

admin.initializeApp();

exports.sendPushForNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const notification = snapshot.data();
    const tokens = await resolveTokens(notification);
    if (tokens.length === 0) {
      return;
    }

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: notification.title || "Ishi Grocery",
        body: notification.body || "You have a new update.",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "ishi_grocery_alerts",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
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
