import 'dart:developer';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sample/src/providers/fuel_trip_controller.dart';
import 'package:sample/src/util/app_routes.dart';

import 'src/util/app_navigation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _fcmToken;
  bool _isInitialized = false;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  // ── Controller reference ──────────────────────────────────────────────────
  FuelTripController? _fuelTripController;

  void attachFuelTripController(FuelTripController controller) {
    _fuelTripController = controller;
    log('✅ FuelTripController attached to FirebaseService');
  }

  void detachFuelTripController() {
    _fuelTripController = null;
    log('🔌 FuelTripController detached from FirebaseService');
  }
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    try {
      log('═══════════════════════════════════════');
      log('🚀 FIREBASE MESSAGING INITIALIZATION START');

      await _initializeLocalNotifications();
      log('✅ Step 1: Local notifications initialized');

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
      log('📋 Permission: ${settings.authorizationStatus}');

      log('🔑 Step 3: Getting FCM token...');
      await getFCMToken();

      if (_fcmToken == null) {
        log('⚠️ FCM token null, retrying in 2 s...');
        await Future.delayed(const Duration(seconds: 2));
        await getFCMToken();
      }

      log('📱 Step 4: Setting up foreground handler...');
      await _setupForegroundHandler();

      log('📨 Step 5: Background handler...');
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // ── Background tap: app is in background, user taps notification ────
      log('🔔 Step 6: onMessageOpenedApp (background tap)...');
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log('📱 APP OPENED FROM BACKGROUND via notification tap');
        log('Data: ${message.data}');
        _handleNotificationTap(message);
      });

      // ── Terminated tap: app was closed, user taps notification ───────────
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        log('📱 APP OPENED FROM TERMINATED STATE via notification tap');
        log('Data: ${initialMessage.data}');
        // Slight delay to ensure Navigator and Provider tree are ready
        await Future.delayed(const Duration(milliseconds: 800));
        _handleNotificationTap(initialMessage);
      }

      log('🔄 Step 7: Token refresh listener...');
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        log('🔄 FCM TOKEN REFRESHED');
        _fcmToken = newToken;
        // TODO: Send updated token to your backend
      });

      _isInitialized = true;
      log('✅ FIREBASE MESSAGING INITIALIZED SUCCESSFULLY');
    } catch (e, stackTrace) {
      log('❌ FIREBASE INIT FAILED: $e\n$stackTrace');
      _isInitialized = false;
    }
  }

  // ── Public: refresh all controller data (bell + assigned trips badge) ─────
  Future<void> refreshControllerData() async {
    if (_fuelTripController == null) {
      log('⚠️ refreshControllerData: controller not attached');
      return;
    }
    log('🔄 Refreshing FuelTripController data...');
    try {
      await Future.wait([
        _fuelTripController!.fetchUnreadCount(),
        _fuelTripController!.getAssignedTrips(),
        _fuelTripController!.getNotifications(),
      ]);
      log('✅ FuelTripController refreshed');
    } catch (e) {
      log('❌ Error refreshing controller: $e');
    }
  }

  // ── Play alert sound ──────────────────────────────────────────────────────
  Future<void> _playAlertSound() async {
    try {
      log('🔊 Playing notification alert sound...');
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.release); // play once only
      await _audioPlayer.play(AssetSource('sounds/alert_sound.mp3'));
      log('✅ Alert sound playing');
    } catch (e) {
      log('❌ Error playing alert sound: $e');
    }
  }
  // ─────────────────────────────────────────────────────────────────────────

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
        log('🔔 LOCAL NOTIFICATION TAPPED – payload: ${response.payload}');
        // User tapped a foreground heads-up banner → refresh then navigate
        _refreshAndNavigate();
      },
    );

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

    final androidImpl =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(channel);
      log('✅ Notification channel created');
    }
  }

  Future<void> _setupForegroundHandler() async {
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    log('✅ Foreground message listener active');
  }

  /// Fires when a notification arrives while the app is OPEN (foreground).
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    log('═══════════════════════════════════════');
    log('📬 FOREGROUND MESSAGE RECEIVED');
    log('Title: ${message.notification?.title ?? "No title"}');
    log('Body:  ${message.notification?.body ?? "No body"}');
    log('Data:  ${message.data}');

    // 1️⃣  Play alert sound immediately
    await _playAlertSound();

    // 2️⃣  Refresh badge counts and trip data immediately
    await refreshControllerData();

    // 3️⃣  Show heads-up notification banner
    if (message.notification != null) {
      await _showLocalNotification(message);
    }

    log('═══════════════════════════════════════');
  }

  /// Fires when the user taps a notification from BACKGROUND or TERMINATED.
  /// Refreshes data BEFORE navigating so the screen already has data on open.
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    log('🔔 _handleNotificationTap – refreshing data then navigating...');

    // Refresh first so NotificationScreen has data ready when it builds
    await refreshControllerData();

    try {
      NavigationService().pushNavigation(
        Screenroutes.notificationsScreen,
        arguments: {
          'notificationData': message.data,
          'title': message.notification?.title,
          'body': message.notification?.body,
          'messageId': message.messageId,
        },
      );
      log('✅ Navigated to notificationsScreen');
    } catch (e) {
      log('❌ Navigation error: $e');
    }
  }

  /// Fires when user taps a FOREGROUND heads-up banner (local notification).
  Future<void> _refreshAndNavigate() async {
    log('🔔 _refreshAndNavigate – local notification tapped');
    await refreshControllerData();
    try {
      NavigationService().pushNavigation(Screenroutes.notificationsScreen);
      log('✅ Navigated to notificationsScreen from local tap');
    } catch (e) {
      log('❌ Navigation error: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'high_importance_channel',
            'Important Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            enableLights: true,
            enableVibration: true,
            playSound: true,
            icon: '@drawable/ic_notification',
            color: const Color(0xFF667eea),
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails platformDetails = NotificationDetails(
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

      log('✅ LOCAL NOTIFICATION SHOWN: ${notification.title}');
    } catch (e, stackTrace) {
      log('❌ ERROR SHOWING LOCAL NOTIFICATION: $e\n$stackTrace');
    }
  }

  Future<String?> getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        log('✅ FCM TOKEN RETRIEVED (length: ${_fcmToken!.length})');
        log('Token: $_fcmToken');
      } else {
        log('❌ FCM Token is NULL');
      }
      return _fcmToken;
    } catch (e, stackTrace) {
      log('❌ ERROR GETTING FCM TOKEN: $e\n$stackTrace');
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      log('✅ FCM token deleted');
    } catch (e) {
      log('❌ Error deleting FCM token: $e');
      rethrow;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      log('✅ Subscribed to: $topic');
    } catch (e) {
      log('❌ Error subscribing to topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      log('✅ Unsubscribed from: $topic');
    } catch (e) {
      log('❌ Error unsubscribing from topic: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This runs in a separate isolate — Provider/FuelTripController not accessible here.
  // Data is refreshed when the user taps the notification (onMessageOpenedApp).
  log('📨 BACKGROUND MESSAGE: ${message.notification?.title ?? "No title"}');
}
