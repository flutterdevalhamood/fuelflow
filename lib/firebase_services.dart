import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sample/src/util/app_routes.dart';

import 'src/util/app_navigation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;
  bool _isInitialized = false;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      log('Starting Firebase Messaging initialization...');

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
        // Still try to get token for Android devices that don't require permission
      }

      // Get FCM token - CRITICAL: Wait for it to complete
      await getFCMToken();

      if (_fcmToken == null) {
        log('⚠️ Warning: FCM token is null after initialization');
        // Retry once after a delay
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
        // TODO: Send the new token to your server here
        // _updateTokenOnServer(newToken);
      });

      _isInitialized = true;
      log('✅ Firebase Messaging initialized successfully');
    } catch (e, stackTrace) {
      log('❌ Error initializing Firebase Messaging: $e');
      log('Stack trace: $stackTrace');
      _isInitialized = false;
    }
  }

  /// Setup foreground message handler with better configuration
  Future<void> _setupForegroundHandler() async {
    // For iOS: Configure how notifications appear in foreground
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true, // Show notification banner
      badge: true, // Update badge count
      sound: true, // Play sound
    );

    // Handle messages received while app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Get FCM Token with retry logic
  Future<String?> getFCMToken() async {
    try {
      log('Requesting FCM token...');

      // For iOS, ensure APNS token is available first
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      if (apnsToken != null) {
        log('APNS Token available: ${apnsToken.substring(0, 20)}...');
      } else {
        log('⚠️ APNS Token not available yet (iOS only)');
      }

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

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    log('📬 Received foreground message: ${message.messageId}');
    log('Title: ${message.notification?.title}');
    log('Body: ${message.notification?.body}');
    log('Data: ${message.data}');

    // You can show a local notification here or update UI
    // For now, just logging the notification

    // TODO: Show in-app notification or update UI
    // _showLocalNotification(message);
  }

  /// Handle notification click
  void _handleNotificationClick(RemoteMessage message) {
    log('🔔 Handling notification click');
    log('Title: ${message.notification?.title}');
    log('Body: ${message.notification?.body}');
    log('Data: ${message.data}');

    // Navigate to notifications screen
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

    // Alternative: Navigate based on notification type
    // String? notificationType = message.data['type'];
    // switch (notificationType) {
    //   case 'order':
    //     NavigationService().pushNavigation(
    //       Screenroutes.orderDetails,
    //       arguments: {'orderId': message.data['orderId']},
    //     );
    //     break;
    //   default:
    //     break;
    // }
  }

  /// Delete FCM token (useful for logout)
  Future<void> deleteToken() async {
    try {
      log('Deleting FCM token...');
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      log('✅ FCM token deleted successfully');
    } catch (e, stackTrace) {
      log('❌ Error deleting FCM token: $e');
      log('Stack trace: $stackTrace');
      throw e; // Re-throw to handle in logout
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
/// This MUST be a top-level function (not a class method)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('📨 Background message received: ${message.messageId}');
  log('Title: ${message.notification?.title}');
  log('Body: ${message.notification?.body}');
  log('Data: ${message.data}');

  // Handle background message here
  // Note: You cannot show dialogs or navigate here
  // You can update local database or show local notifications
}
