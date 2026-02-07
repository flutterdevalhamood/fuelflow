import 'dart:developer';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sample/src/util/app_routes.dart';

import 'src/util/app_navigation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase Messaging and Local Notifications
  Future<void> initialize() async {
    try {
      log('Starting Firebase Messaging initialization...');

      // Initialize local notifications first
      await _initializeLocalNotifications();

      // Request permission for iOS (and Android 13+)
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
            criticalAlert: false,
            announcement: false,
          );

      log('Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log('✅ User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        log('⚠️ User granted provisional notification permission');
      } else {
        log('❌ User declined or has not accepted notification permission');
      }

      // Get FCM token
      await getFCMToken();

      if (_fcmToken == null) {
        log('⚠️ Warning: FCM token is null after initialization');
        await Future.delayed(Duration(seconds: 2));
        await getFCMToken();
      }

      // Setup foreground notification handler
      await _setupForegroundHandler();

      // Setup background notification handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle notification when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log(
          '📱 Notification clicked (app in background): ${message.notification?.title}',
        );
        _handleNotificationClick(message);
      });

      // Check if app was opened from a terminated state via notification
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        log('📱 App opened from terminated state via notification');
        _handleNotificationClick(initialMessage);
      }

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        log('🔄 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
      });

      _isInitialized = true;
      log('✅ Firebase Messaging initialized successfully');
    } catch (e, stackTrace) {
      log('❌ Error initializing Firebase Messaging: $e');
      log('Stack trace: $stackTrace');
      _isInitialized = false;
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        log('🔔 Local notification tapped: ${response.payload}');
        // Handle notification tap here
        if (response.payload != null) {
          // You can parse the payload and navigate accordingly
          NavigationService().pushNavigation(Screenroutes.notificationScreen);
        }
      },
    );

    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // Must match AndroidManifest.xml
      'Important Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      enableLights: true,
      enableVibration: true,
      showBadge: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    log('✅ Local notifications initialized');
  }

  /// Setup foreground message handler
  Future<void> _setupForegroundHandler() async {
    // For iOS: Configure how notifications appear in foreground
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle messages received while app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Handle foreground messages by showing local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    log('📬 Received foreground message: ${message.messageId}');
    log('Title: ${message.notification?.title}');
    log('Body: ${message.notification?.body}');
    log('Data: ${message.data}');

    // ✅ CRITICAL: Show local notification when app is in foreground
    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification == null) {
        log('⚠️ Notification is null, cannot show');
        return;
      }

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'Important Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        icon: '@drawable/ic_notification',
        color: Color(0xFF667eea),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
        payload: message.data.toString(),
      );

      log('✅ Local notification shown: ${notification.title}');
    } catch (e, stackTrace) {
      log('❌ Error showing local notification: $e');
      log('Stack trace: $stackTrace');
    }
  }

  /// Get FCM Token with retry logic
  Future<String?> getFCMToken() async {
    try {
      log('Requesting FCM token...');

      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null) {
        log('✅ FCM Token retrieved successfully');
        log('Token: $_fcmToken');
        log('Token length: ${_fcmToken!.length}');
      } else {
        log('⚠️ FCM Token is null');
      }

      return _fcmToken;
    } catch (e, stackTrace) {
      log('❌ Error getting FCM token: $e');
      log('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Handle notification click
  void _handleNotificationClick(RemoteMessage message) {
    log('🔔 Handling notification click');
    log('Title: ${message.notification?.title}');
    log('Body: ${message.notification?.body}');
    log('Data: ${message.data}');

    try {
      NavigationService().pushNavigation(
        Screenroutes.notificationScreen,
        arguments: {
          'notificationData': message.data,
          'title': message.notification?.title,
          'body': message.notification?.body,
          'messageId': message.messageId,
        },
      );
    } catch (e) {
      log('Error navigating from notification: $e');
    }
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      log('Deleting FCM token...');
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      log('✅ FCM token deleted successfully');
    } catch (e, stackTrace) {
      log('❌ Error deleting FCM token: $e');
      log('Stack trace: $stackTrace');
      throw e;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      log('✅ Subscribed to topic: $topic');
    } catch (e) {
      log('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      log('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      log('❌ Error unsubscribing from topic: $e');
    }
  }
}

/// Top-level function for background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('📨 Background message received: ${message.messageId}');
  log('Title: ${message.notification?.title}');
  log('Body: ${message.notification?.body}');
  log('Data: ${message.data}');
}
