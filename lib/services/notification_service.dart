import 'dart:io';
import 'package:pdf_signy/services/app_logger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  factory NotificationService() => instance;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notification service (iOS only)
  Future<void> init() async {
    // Skip initialization for Android
    if (!Platform.isIOS) {
      AppLogger().info('Notification service skipped for Android');
      return;
    }

    if (_isInitialized) return;

    try {
      // Request permissions for iOS only
      final initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final initializationSettings = InitializationSettings(iOS: initializationSettingsIOS);

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      AppLogger().info('Notification service initialized (iOS)');
    } catch (e) {
      AppLogger().error('Error initializing notification service: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    AppLogger().info('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions (iOS only)
  Future<bool> requestPermissions() async {
    // Skip for Android
    if (!Platform.isIOS) {
      return false;
    }

    try {
      if (!_isInitialized) {
        await init();
      }

      final result = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      return result ?? false;
    } catch (e) {
      AppLogger().error('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Schedule daily notification (iOS only)
  Future<void> scheduleDailyNotification() async {
    // Skip for Android
    if (!Platform.isIOS) {
      return;
    }

    try {
      if (!_isInitialized) {
        await init();
      }

      // Cancel existing notification
      await _notifications.cancel(1);

      // Note: iOS doesn't support periodic notifications well,
      // so we check on app open instead
      AppLogger().info('Daily notification check will happen on app open (iOS)');
    } catch (e) {
      AppLogger().error('Error scheduling daily notification: $e');
    }
  }

  /// Cancel daily notification (iOS only)
  Future<void> cancelDailyNotification() async {
    // Skip for Android
    if (!Platform.isIOS) {
      return;
    }

    try {
      await _notifications.cancel(1);
      AppLogger().info('Daily notification cancelled');
    } catch (e) {
      AppLogger().error('Error cancelling notification: $e');
    }
  }

  /// Show immediate notification (iOS only)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Skip for Android
    if (!Platform.isIOS) {
      return;
    }

    try {
      if (!_isInitialized) {
        await init();
      }

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(iOS: iosDetails);

      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      AppLogger().info('Notification shown (iOS): $title');
    } catch (e) {
      AppLogger().error('Error showing notification: $e');
    }
  }

  /// Show document signed notification (iOS only)
  Future<void> showDocumentSignedNotification(String documentName) async {
    await showNotification(
      id: 2,
      title: 'Document signed! 📄',
      body: '$documentName has been successfully signed',
      payload: documentName,
    );
  }

  /// Cancel notification by ID (iOS only)
  Future<void> cancelNotification(int id) async {
    if (!Platform.isIOS) {
      return;
    }

    try {
      await _notifications.cancel(id);
      AppLogger().info('Notification cancelled: $id');
    } catch (e) {
      AppLogger().error('Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications (iOS only)
  Future<void> cancelAllNotifications() async {
    if (!Platform.isIOS) {
      return;
    }

    try {
      await _notifications.cancelAll();
      AppLogger().info('All notifications cancelled');
    } catch (e) {
      AppLogger().error('Error cancelling all notifications: $e');
    }
  }
}


