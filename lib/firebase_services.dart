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

  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log('User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        log('User granted provisional notification permission');
      } else {
        log('User declined or has not accepted notification permission');
      }

      // Get FCM token
      await getFCMToken();

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        log('FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        // You might want to send the new token to your server here
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log(
          'Notification clicked (app in background): ${message.notification?.title}',
        );
        _handleNotificationClick(message);
      });

      // Check if app was opened from a terminated state via notification
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(initialMessage);
      }
    } catch (e) {
      log('Error initializing Firebase Messaging: $e');
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    log('Handling notification click');
    log('Notification data: ${message.data}');

    // Navigate to notifications screen
    NavigationService().pushNavigation(
      Screenroutes.notificationScreen, // Your notification screen route
      // arguments: {
      //   'notificationData': message.data,
      //   'title': message.notification?.title,
      //   'body': message.notification?.body,
      // },
    );

    // // Alternative: Navigate based on notification type
    // String? notificationType = message.data['type'];
    // switch (notificationType) {
    //   case 'order':
    //     NavigationService().pushNavigation(
    //       Screenroutes.orderDetails,
    //       arguments: {'orderId': message.data['orderId']},
    //     );
    //     break;
    //   case 'message':
    //     NavigationService().pushNavigation(
    //       Screenroutes.chat,
    //       arguments: {'chatId': message.data['chatId']},
    //     );
    //     break;
    //   default:
    //     NavigationService().pushNavigation(Screenroutes.notifications);
    //     break;
    // }
  }

  /// Get FCM Token
  Future<String?> getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      log('FCM Token: $_fcmToken');
      return _fcmToken;
    } catch (e) {
      log('Error getting FCM token: $e');
      return null;
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    log('Received foreground message: ${message.messageId}');
    log('Title: ${message.notification?.title}');
    log('Body: ${message.notification?.body}');
    log('Data: ${message.data}');

    // You can show a local notification here or update UI
  }

  /// Delete FCM token (useful for logout)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      log('FCM token deleted');
    } catch (e) {
      log('Error deleting FCM token: $e');
    }
  }
}

/// Top-level function for background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Background message received: ${message.messageId}');
  log('Title: ${message.notification?.title}');
  log('Body: ${message.notification?.body}');
}
