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

    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: notification.title || "Ishi Grocery",
        body: notification.body || "You have a new update.",
      },
      data: {
        notificationId: event.params.notificationId,
        type: notification.type || "",
        relatedId: notification.relatedId || "",
      },
    });
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

    return admins.docs.flatMap((doc) => doc.get("fcmTokens") || []);
  }

  if (!notification.userId) {
    return [];
  }

  const user = await admin
    .firestore()
    .collection("users")
    .doc(notification.userId)
    .get();

  return user.exists ? user.get("fcmTokens") || [] : [];
}
