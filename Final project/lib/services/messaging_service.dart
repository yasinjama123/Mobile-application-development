import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.notification?.title}');
}

class MessagingService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db  = FirebaseFirestore.instance;

  Future<void> init(String uid) async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission (iOS + Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Save token to Firestore
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveToken(uid, token);
      debugPrint('FCM token saved');
    }

    // Refresh token
    _fcm.onTokenRefresh.listen((t) => _saveToken(uid, t));

    // Foreground messages
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('FCM foreground: ${msg.notification?.title}');
    });

    // App opened via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('FCM opened: ${msg.data}');
    });

    // Subscribe to city alerts
    await subscribeToCity('addis_ababa');
  }

  Future<void> _saveToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  Future<void> subscribeToProduct(String productId) =>
      _fcm.subscribeToTopic('product_$productId');

  Future<void> unsubscribeFromProduct(String productId) =>
      _fcm.unsubscribeFromTopic('product_$productId');

  Future<void> subscribeToCity(String city) =>
      _fcm.subscribeToTopic('city_$city');
}
