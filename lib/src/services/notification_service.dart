import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  NotificationService({required bool firebaseAvailable})
      : _firebaseAvailable = firebaseAvailable;

  final bool _firebaseAvailable;

  Future<void> configureForUser(String uid) async {
    if (!_firebaseAvailable) {
      return;
    }

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    final token = await messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'fcmTokens': FieldValue.arrayUnion([token]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    FirebaseMessaging.onMessage.listen((message) {
      // Foreground messages are intentionally kept in-app for the MVP.
      // Firestore notification documents provide the notification inbox.
    });
  }
}
