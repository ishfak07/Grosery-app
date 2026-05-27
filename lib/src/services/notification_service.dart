import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const _notificationChannelId = 'ishi_grocery_alerts';
const _notificationChannel = AndroidNotificationChannel(
  _notificationChannelId,
  'Ishi Grocery Alerts',
  description: 'Order, support, and account updates.',
  importance: Importance.max,
);

class NotificationService {
  NotificationService({required bool firebaseAvailable})
      : _firebaseAvailable = firebaseAvailable;

  final bool _firebaseAvailable;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  String? _configuredUserId;
  StreamSubscription<String>? _tokenRefreshSubscription;
  var _localNotificationsConfigured = false;
  var _foregroundListenerConfigured = false;

  Future<void> configureForUser(String uid) async {
    if (!_firebaseAvailable || _configuredUserId == uid) {
      return;
    }
    _configuredUserId = uid;
    await _configureLocalNotifications();

    final messaging = FirebaseMessaging.instance;
    try {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      await _trySaveToken(uid, await messaging.getToken());
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen(
        (token) => unawaited(_trySaveToken(uid, token)),
      );
    } catch (_) {
      // FCM can fail on emulators or devices with restricted Google services.
      // Core app flows should continue without push token registration.
    }

    if (!_foregroundListenerConfigured) {
      _foregroundListenerConfigured = true;
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    }
  }

  Future<void> _configureLocalNotifications() async {
    if (_localNotificationsConfigured) {
      return;
    }
    _localNotificationsConfigured = true;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await _localNotifications.initialize(initializationSettings);

    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(
      _notificationChannel,
    );
    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> _saveToken(String uid, String? token) async {
    if (token == null || token.isEmpty) {
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _trySaveToken(String uid, String? token) async {
    try {
      await _saveToken(uid, token);
    } catch (_) {
      // Token persistence is best-effort and should never block app usage.
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (Platform.isIOS || Platform.isMacOS) {
      return;
    }

    final title = message.notification?.title ?? 'Ishi Grocery';
    final body = message.notification?.body ?? 'You have a new update.';
    final notificationId = message.data['notificationId'] ?? message.messageId;
    final localId =
        (notificationId ?? DateTime.now().toIso8601String()).hashCode &
            0x7fffffff;

    await _localNotifications.show(
      localId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _notificationChannelId,
          'Ishi Grocery Alerts',
          channelDescription: 'Order, support, and account updates.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['relatedId'],
    );
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }
}
