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
      log('═══════════════════════════════════════');
      log('🚀 FIREBASE MESSAGING INITIALIZATION START');
      log('═══════════════════════════════════════');
      log('Timestamp: ${DateTime.now()}');

      // Initialize local notifications first
      await _initializeLocalNotifications();
      log('✅ Step 1: Local notifications initialized');

      // Request permission for iOS (and Android 13+)
      log('📋 Step 2: Requesting notification permissions...');
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        announcement: false,
      );

      log('📋 Permission result: ${settings.authorizationStatus}');
      log('   - Authorization Status: ${settings.authorizationStatus.name}');
      log('   - Alert: ${settings.alert}');
      log('   - Badge: ${settings.badge}');
      log('   - Sound: ${settings.sound}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log('✅ User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        log('⚠️ User granted provisional notification permission');
      } else {
        log('❌ User declined or has not accepted notification permission');
        log('⚠️ Notifications will NOT work until permission is granted!');
      }

      // Get FCM token
      log('🔑 Step 3: Getting FCM token...');
      await getFCMToken();

      if (_fcmToken == null) {
        log('⚠️ Warning: FCM token is null after first attempt');
        log('⏳ Waiting 2 seconds and retrying...');
        await Future.delayed(Duration(seconds: 2));
        await getFCMToken();

        if (_fcmToken == null) {
          log('❌ CRITICAL: FCM token is still null after retry!');
          log('❌ Push notifications will NOT work!');
        }
      }

      // Setup foreground notification handler
      log('📱 Step 4: Setting up foreground handler...');
      await _setupForegroundHandler();
      log('✅ Foreground handler set up');

      // Setup background notification handler
      log('📨 Step 5: Setting up background handler...');
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      log('✅ Background handler set up');

      // Handle notification when app is opened from background
      log('🔔 Step 6: Setting up notification click handlers...');
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log('═══════════════════════════════════════');
        log('📱 NOTIFICATION CLICKED (APP IN BACKGROUND)');
        log('═══════════════════════════════════════');
        log('Message ID: ${message.messageId}');
        log('Title: ${message.notification?.title}');
        log('Body: ${message.notification?.body}');
        log('Data: ${message.data}');
        log('Timestamp: ${DateTime.now()}');
        _handleNotificationClick(message);
      });

      // Check if app was opened from a terminated state via notification
      RemoteMessage? initialMessage =
      await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        log('═══════════════════════════════════════');
        log('📱 APP OPENED FROM TERMINATED STATE VIA NOTIFICATION');
        log('═══════════════════════════════════════');
        log('Message ID: ${initialMessage.messageId}');
        log('Title: ${initialMessage.notification?.title}');
        log('Body: ${initialMessage.notification?.body}');
        log('Data: ${initialMessage.data}');
        _handleNotificationClick(initialMessage);
      } else {
        log('ℹ️ App was NOT opened from a notification');
      }

      // Listen to token refresh
      log('🔄 Step 7: Setting up token refresh listener...');
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        log('═══════════════════════════════════════');
        log('🔄 FCM TOKEN REFRESHED');
        log('═══════════════════════════════════════');
        log('New Token: $newToken');
        log('Token Length: ${newToken.length}');
        log('Timestamp: ${DateTime.now()}');
        _fcmToken = newToken;
        // TODO: Send updated token to your backend server
      });
      log('✅ Token refresh listener set up');

      _isInitialized = true;
      log('═══════════════════════════════════════');
      log('✅ FIREBASE MESSAGING INITIALIZED SUCCESSFULLY');
      log('═══════════════════════════════════════');
      log('Is Initialized: $_isInitialized');
      log('Has FCM Token: ${_fcmToken != null}');
      log('Timestamp: ${DateTime.now()}');
    } catch (e, stackTrace) {
      log('═══════════════════════════════════════');
      log('❌ FIREBASE MESSAGING INITIALIZATION FAILED');
      log('═══════════════════════════════════════');
      log('Error: $e');
      log('Stack trace: $stackTrace');
      log('Timestamp: ${DateTime.now()}');
      _isInitialized = false;
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    log('🔧 Initializing local notifications plugin...');

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

    final initialized = await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        log('═══════════════════════════════════════');
        log('🔔 LOCAL NOTIFICATION TAPPED');
        log('═══════════════════════════════════════');
        log('Notification ID: ${response.id}');
        log('Action ID: ${response.actionId}');
        log('Input: ${response.input}');
        log('Payload: ${response.payload}');
        log('Timestamp: ${DateTime.now()}');

        if (response.payload != null) {
          log('➡️ Navigating to notification screen...');
          NavigationService().pushNavigation(Screenroutes.notificationScreen);
        } else {
          log('⚠️ No payload to handle');
        }
      },
    );

    log('Local notifications initialized: $initialized');

    // Create Android notification channel - FIX HERE
    log('📢 Creating Android notification channel...');
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Important Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      enableLights: true,
      enableVibration: true,
      showBadge: true,
      playSound: true,
    );

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
      log('✅ Notification channel created: ${channel.id}');
      log('   - Name: ${channel.name}');
      log('   - Importance: ${channel.importance}');
      log('   - Sound: ${channel.playSound}');
      log('   - Vibration: ${channel.enableVibration}');
    } else {
      log('⚠️ Android implementation not available (probably running on iOS)');
    }

    log('✅ Local notifications setup complete');
  }

  /// Setup foreground message handler
  Future<void> _setupForegroundHandler() async {
    log('📱 Setting up foreground notification presentation options...');

    // For iOS: Configure how notifications appear in foreground
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    log('✅ iOS foreground options set (alert, badge, sound)');

    // Handle messages received while app is in foreground
    log('👂 Setting up foreground message listener...');
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    log('✅ Foreground message listener active');
  }

  /// Handle foreground messages by showing local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    log('═══════════════════════════════════════');
    log('📬 FOREGROUND MESSAGE RECEIVED');
    log('═══════════════════════════════════════');
    log('Message ID: ${message.messageId}');
    log('Sent Time: ${message.sentTime}');
    log('Title: ${message.notification?.title ?? "No title"}');
    log('Body: ${message.notification?.body ?? "No body"}');
    log('Data: ${message.data}');
    log('Category: ${message.category}');
    log('Collapse Key: ${message.collapseKey}');
    log('Content Available: ${message.contentAvailable}');
    log('From: ${message.from}');
    log('Message Type: ${message.messageType}');
    log('Thread ID: ${message.threadId}');
    log('TTL: ${message.ttl}');
    log('Timestamp: ${DateTime.now()}');

    // ✅ CRITICAL: Show local notification when app is in foreground
    if (message.notification != null) {
      log('📲 Notification data present, showing local notification...');
      await _showLocalNotification(message);
    } else {
      log('⚠️ No notification data in message (data-only message)');
    }

    log('═══════════════════════════════════════');
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      log('🔔 Preparing to show local notification...');

      final notification = message.notification;
      final android = message.notification?.android;

      if (notification == null) {
        log('❌ Notification object is null, cannot show');
        return;
      }

      log('Notification details:');
      log('   - Title: ${notification.title}');
      log('   - Body: ${notification.body}');
      log('   - Android Image URL: ${android?.imageUrl}');
      log('   - Android Channel ID: ${android?.channelId}');

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

      log('Android notification details configured');
      log('   - Channel: high_importance_channel');
      log('   - Importance: High');
      log('   - Sound: Enabled');
      log('   - Vibration: Enabled');

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = notification.hashCode;
      log('📤 Showing notification with ID: $notificationId');

      await _localNotifications.show(
        notificationId,
        notification.title,
        notification.body,
        platformDetails,
        payload: message.data.toString(),
      );

      log('✅ LOCAL NOTIFICATION SHOWN SUCCESSFULLY');
      log('   - ID: $notificationId');
      log('   - Title: ${notification.title}');
      log('   - Body: ${notification.body}');
      log('   - Payload: ${message.data}');
      log('   - Timestamp: ${DateTime.now()}');
    } catch (e, stackTrace) {
      log('═══════════════════════════════════════');
      log('❌ ERROR SHOWING LOCAL NOTIFICATION');
      log('═══════════════════════════════════════');
      log('Error: $e');
      log('Stack trace: $stackTrace');
      log('Timestamp: ${DateTime.now()}');
    }
  }

  /// Get FCM Token with retry logic
  Future<String?> getFCMToken() async {
    try {
      log('🔑 Requesting FCM token from Firebase...');
      log('Timestamp: ${DateTime.now()}');

      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null) {
        log('═══════════════════════════════════════');
        log('✅ FCM TOKEN RETRIEVED SUCCESSFULLY');
        log('═══════════════════════════════════════');
        log('Full Token: $_fcmToken');
        log('Token Length: ${_fcmToken!.length}');
        log('First 50 chars: ${_fcmToken!.substring(0, _fcmToken!.length > 50 ? 50 : _fcmToken!.length)}...');
        log('Timestamp: ${DateTime.now()}');
        log('═══════════════════════════════════════');
        log('📋 COPY THIS TOKEN TO TEST IN FIREBASE CONSOLE:');
        log('$_fcmToken');
        log('═══════════════════════════════════════');
      } else {
        log('❌ FCM Token is NULL');
        log('Possible reasons:');
        log('   1. Google Play Services not available');
        log('   2. Network connection issue');
        log('   3. Firebase not properly configured');
        log('   4. App not registered with FCM');
      }

      return _fcmToken;
    } catch (e, stackTrace) {
      log('═══════════════════════════════════════');
      log('❌ ERROR GETTING FCM TOKEN');
      log('═══════════════════════════════════════');
      log('Error: $e');
      log('Stack trace: $stackTrace');
      log('Timestamp: ${DateTime.now()}');
      return null;
    }
  }

  /// Handle notification click
  void _handleNotificationClick(RemoteMessage message) {
    log('═══════════════════════════════════════');
    log('🔔 HANDLING NOTIFICATION CLICK');
    log('═══════════════════════════════════════');
    log('Message ID: ${message.messageId}');
    log('Title: ${message.notification?.title}');
    log('Body: ${message.notification?.body}');
    log('Data: ${message.data}');
    log('Timestamp: ${DateTime.now()}');

    try {
      log('➡️ Navigating to notification screen...');
      NavigationService().pushNavigation(
        Screenroutes.notificationScreen,
        arguments: {
          'notificationData': message.data,
          'title': message.notification?.title,
          'body': message.notification?.body,
          'messageId': message.messageId,
        },
      );
      log('✅ Navigation successful');
    } catch (e) {
      log('❌ Error navigating from notification: $e');
    }
    log('═══════════════════════════════════════');
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      log('═══════════════════════════════════════');
      log('🗑️ DELETING FCM TOKEN');
      log('═══════════════════════════════════════');
      log('Current token: ${_fcmToken?.substring(0, 20)}...');

      await _firebaseMessaging.deleteToken();
      _fcmToken = null;

      log('✅ FCM token deleted successfully');
      log('Token is now: $_fcmToken');
      log('Timestamp: ${DateTime.now()}');
    } catch (e, stackTrace) {
      log('❌ Error deleting FCM token: $e');
      log('Stack trace: $stackTrace');
      throw e;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      log('📢 Subscribing to topic: $topic');
      await _firebaseMessaging.subscribeToTopic(topic);
      log('✅ Subscribed to topic: $topic');
    } catch (e) {
      log('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      log('📢 Unsubscribing from topic: $topic');
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
  log('═══════════════════════════════════════');
  log('📨 BACKGROUND MESSAGE RECEIVED');
  log('═══════════════════════════════════════');
  log('Message ID: ${message.messageId}');
  log('Sent Time: ${message.sentTime}');
  log('Title: ${message.notification?.title ?? "No title"}');
  log('Body: ${message.notification?.body ?? "No body"}');
  log('Data: ${message.data}');
  log('From: ${message.from}');
  log('Timestamp: ${DateTime.now()}');
  log('═══════════════════════════════════════');

  // Note: You can perform background tasks here
  // But avoid heavy operations as this runs in isolate
}