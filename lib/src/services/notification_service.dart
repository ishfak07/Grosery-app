import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';

const _notificationChannelId = 'puttalam_drop_alerts';
const _notificationChannelName = 'Puttalam Drop Alerts';
const _notificationChannelDescription = 'Order, support, and account updates.';
const _notificationChannel = AndroidNotificationChannel(
  _notificationChannelId,
  _notificationChannelName,
  description: _notificationChannelDescription,
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  audioAttributesUsage: AudioAttributesUsage.notification,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    if (message.notification == null) {
      await NotificationService.showLocalNotification(message);
    }
  } catch (_) {
    // Background push handling must never prevent the app from opening.
  }
}

class NotificationService {
  NotificationService({required bool firebaseAvailable})
      : _firebaseAvailable = firebaseAvailable;

  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static var _localNotificationsConfigured = false;
  static var _backgroundHandlerRegistered = false;

  final bool _firebaseAvailable;
  String? _configuredUserId;
  StreamSubscription<String>? _tokenRefreshSubscription;
  var _foregroundListenerConfigured = false;

  static void registerBackgroundHandler() {
    if (_backgroundHandlerRegistered) {
      return;
    }
    _backgroundHandlerRegistered = true;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> initialize({required bool requestPermission}) async {
    if (!_firebaseAvailable) {
      return;
    }

    await _tryConfigureLocalNotifications();
    await _tryConfigureForegroundPresentation();
    if (requestPermission) {
      await _tryRequestPermission();
    }
    _configureForegroundListener();
  }

  Future<void> configureForUser(String uid) async {
    if (!_firebaseAvailable) {
      return;
    }

    await initialize(requestPermission: false);

    if (_configuredUserId != uid) {
      _configuredUserId = uid;
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen(
        (token) {
          _debugPrintToken(token);
          unawaited(_trySaveToken(uid, token));
        },
      );
    }

    await _trySaveCurrentToken(uid);
  }

  Future<void> clearTokenForUser(String uid) async {
    await detachUser();
    if (!_firebaseAvailable) {
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final data = snapshot.data();
        if (data == null || data['fcmToken'] != token) {
          return;
        }
        transaction.update(userRef, {
          'fcmToken': FieldValue.delete(),
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (_) {
      // Token cleanup is best-effort; logout should continue.
    }
  }

  Future<void> detachUser() async {
    _configuredUserId = null;
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  static Future<void> _configureLocalNotifications() async {
    if (_localNotificationsConfigured) {
      return;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );
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
    _localNotificationsConfigured = true;
  }

  Future<void> _tryConfigureLocalNotifications() async {
    try {
      await _configureLocalNotifications();
    } catch (_) {
      // Local notification setup can fail on unsupported devices/emulators.
    }
  }

  Future<void> _tryConfigureForegroundPresentation() async {
    try {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
    } catch (_) {
      // FCM can fail on devices without full messaging support.
    }
  }

  Future<void> _tryRequestPermission() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();

      final iosImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      final macosImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>();
      await macosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {
      // Permission prompts are best-effort and should never block app usage.
    }
  }

  void _configureForegroundListener() {
    if (_foregroundListenerConfigured) {
      return;
    }
    _foregroundListenerConfigured = true;
    FirebaseMessaging.onMessage.listen(
      (message) => unawaited(showLocalNotification(message)),
    );
  }

  Future<void> _saveToken(String uid, String? token) async {
    if (token == null || token.isEmpty) {
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _trySaveCurrentToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      _debugPrintToken(token);
      await _trySaveToken(uid, token);
    } catch (_) {
      unawaited(_retrySaveCurrentToken(uid));
    }
  }

  Future<void> _retrySaveCurrentToken(String uid) async {
    await Future<void>.delayed(const Duration(seconds: 5));
    if (_configuredUserId != uid) {
      return;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      _debugPrintToken(token);
      await _trySaveToken(uid, token);
    } catch (_) {
      // Token persistence is retried once, then left to onTokenRefresh.
    }
  }

  void _debugPrintToken(String? token) {
    if (kDebugMode && token != null && token.isNotEmpty) {
      debugPrint('FCM token: $token');
    }
  }

  Future<void> _trySaveToken(String uid, String? token) async {
    try {
      await _saveToken(uid, token);
    } catch (_) {
      // Token persistence is best-effort and should never block app usage.
    }
  }

  static Future<void> showLocalNotification(RemoteMessage message) async {
    try {
      await _configureLocalNotifications();
      final title = message.notification?.title ??
          message.data['title']?.toString() ??
          'Puttalam Drop';
      final body = message.notification?.body ??
          message.data['body']?.toString() ??
          'You have a new update.';
      final notificationId =
          message.data['notificationId'] ?? message.messageId;
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
            _notificationChannelName,
            channelDescription: _notificationChannelDescription,
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.message,
            audioAttributesUsage: AudioAttributesUsage.notification,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
            presentList: true,
          ),
        ),
        payload: message.data['relatedId']?.toString(),
      );
    } catch (_) {
      // Local foreground display should not interrupt active app flows.
    }
  }

  void dispose() {
    unawaited(detachUser());
  }
}
