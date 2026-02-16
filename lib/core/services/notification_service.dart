import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background notification: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ Notifications already initialized');
      return;
    }

    debugPrint('🔔 Initializing Notification Service...');

    try {
      // 1. Request permission
      await _requestPermission();

      // 2. Initialize local notifications
      await _initializeLocalNotifications();

      // 3. Background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 4. Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token: $_fcmToken');

      // 5. Token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 Token refreshed: $newToken');
        _fcmToken = newToken;
      });

      // 6. Foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 7. Notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // 8. Initial message
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // 9. Subscribe to topic
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notificationsEnabled') ?? true;
      if (enabled) {
        await subscribeToTopic('all_users');
      }

      _isInitialized = true;
      debugPrint('✅ Notifications initialized');
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing notifications: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 Permission: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (details) {
        debugPrint('🔔 Notification tapped: ${details.payload}');
      },
    );

    // Create Android notification channel (REMOVED showBadge)
    const channel = AndroidNotificationChannel(
      'agriguard_channel',
      'AgriGuard Notifications',
      description: 'Plant health alerts and updates',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('✅ Local notifications initialized');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Foreground: ${message.notification?.title}');

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notificationsEnabled') ?? true;

    if (!enabled) {
      debugPrint('🔕 Notifications disabled');
      return;
    }

    final notification = message.notification;
    if (notification != null) {
      // REMOVED showBadge from here too
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'agriguard_channel',
            'AgriGuard Notifications',
            channelDescription: 'Plant health alerts and updates',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF10B981),
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped: ${message.data}');
    // TODO: Add navigation logic
  }

  Future<void> showTestNotification() async {
    // REMOVED showBadge from test notification too
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🌿 Plant Health Alert',
      'Your tomato plant needs attention! Check the diagnosis now.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'agriguard_channel',
          'AgriGuard Notifications',
          channelDescription: 'Plant health alerts and updates',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF10B981),
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
    debugPrint('✅ Test notification sent');
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to: $topic');
    } catch (e) {
      debugPrint('❌ Subscribe error: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('🔕 Unsubscribed from: $topic');
    } catch (e) {
      debugPrint('❌ Unsubscribe error: $e');
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificationsEnabled', enabled);

      if (enabled) {
        await subscribeToTopic('all_users');
        debugPrint('🔔 Notifications enabled');
      } else {
        await unsubscribeFromTopic('all_users');
        debugPrint('🔕 Notifications disabled');
      }
    } catch (e) {
      debugPrint('❌ Toggle error: $e');
    }
  }
}