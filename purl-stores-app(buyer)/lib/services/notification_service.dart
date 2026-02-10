import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Background message received: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    print('🔔 Initializing Notification Service...');

    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token
    await _getFCMToken();

    // Setup message handlers
    _setupMessageHandlers();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    print('✅ Notification Service initialized');
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('📋 Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ User granted provisional permission');
    } else {
      print('❌ User declined or has not accepted permission');
    }
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android with custom sound
    const androidChannel = AndroidNotificationChannel(
      'purl_seller_channel_v2',
      'Purl Seller Notifications',
      description: 'Notifications for store owners',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification'),
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    print('✅ Local notifications initialized with custom sound');
  }

  /// Get FCM token and save to Firestore
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      print('📱 FCM Token: $_fcmToken');

      if (_fcmToken != null) {
        await _saveFCMToken(_fcmToken!);
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  /// Save FCM token to Firestore (supports multiple devices)
  Future<void> _saveFCMToken(String token) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('⚠️ No user logged in, skipping token save');
      return;
    }

    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      
      if (userDoc.exists) {
        // Get existing tokens array
        final data = userDoc.data();
        final List<dynamic> existingTokens = data?['fcmTokens'] ?? [];
        
        // Only add if token doesn't exist
        if (!existingTokens.contains(token)) {
          await userRef.update({
            'fcmTokens': FieldValue.arrayUnion([token]),
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            'platform': defaultTargetPlatform.name,
          });
          print('✅ FCM token added to array');
        } else {
          print('ℹ️ FCM token already exists');
        }
      } else {
        // Create new user document with tokens array
        await userRef.set({
          'fcmTokens': [token],
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'platform': defaultTargetPlatform.name,
        });
        print('✅ FCM token saved (new user)');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Handle token refresh
  Future<void> _onTokenRefresh(String token) async {
    print('🔄 FCM Token refreshed: $token');
    _fcmToken = token;
    await _saveFCMToken(token);
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle notification tap when app was terminated
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        print('📱 App opened from terminated state via notification');
        _handleMessageOpenedApp(message);
      }
    });

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Handle foreground messages (show local notification)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📱 Foreground message received: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // Save to Firestore
    await _saveNotificationToFirestore(message);

    // Show local notification
    await _showLocalNotification(message);
  }

  /// Handle message opened from background/terminated state
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('📱 Notification tapped: ${message.messageId}');
    print('Data: ${message.data}');

    // TODO: Navigate to appropriate screen based on notification type
    final type = message.data['type'];
    switch (type) {
      case 'new_order':
        print('Navigate to orders screen');
        break;
      case 'message':
        print('Navigate to messages screen');
        break;
      case 'low_stock':
        print('Navigate to inventory screen');
        break;
      default:
        print('Navigate to notifications screen');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'purl_seller_channel_v2',
      'Purl Seller Notifications',
      channelDescription: 'Notifications for store owners',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification'),
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification.mp3',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Local notification tapped: ${response.payload}');
    // TODO: Navigate based on payload
  }

  /// Save notification to Firestore
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('stores')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': message.notification?.title ?? '',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'type': message.data['type'] ?? 'general',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'messageId': message.messageId,
      });

      print('✅ Notification saved to Firestore');
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  /// Get unread notification count
  Stream<int> getUnreadCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _firestore
        .collection('stores')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('stores')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('stores')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  /// Delete FCM token (call on logout) - removes only this device's token
  Future<void> deleteFCMToken() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || _fcmToken == null) return;

    try {
      await _messaging.deleteToken();
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayRemove([_fcmToken]),
      });
      _fcmToken = null;
      print('✅ FCM token removed from array');
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    }
  }
}
