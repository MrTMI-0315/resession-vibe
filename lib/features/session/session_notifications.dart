import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

abstract class SessionNotificationService {
  Future<void> initialize();

  Future<void> scheduleFocusToBreak({required int inSeconds});

  Future<void> scheduleBreakToFocus({required int inSeconds});

  Future<void> cancelAll();
}

class NoopSessionNotificationService implements SessionNotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleFocusToBreak({required int inSeconds}) async {}

  @override
  Future<void> scheduleBreakToFocus({required int inSeconds}) async {}

  @override
  Future<void> cancelAll() async {}
}

class LocalSessionNotificationService implements SessionNotificationService {
  static const int _focusToBreakNotificationId = 11001;
  static const int _breakToFocusNotificationId = 11002;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionGranted = false;

  @override
  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }
    try {
      tz.initializeTimeZones();
      const DarwinInitializationSettings darwinSettings =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );
      const InitializationSettings settings = InitializationSettings(
        iOS: darwinSettings,
      );
      await _plugin.initialize(settings);
      final IOSFlutterLocalNotificationsPlugin? darwin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      _permissionGranted =
          await darwin?.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          ) ??
          false;
      _initialized = true;
    } catch (_) {
      _initialized = true;
      _permissionGranted = false;
    }
  }

  @override
  Future<void> scheduleFocusToBreak({required int inSeconds}) async {
    await _scheduleTransition(
      id: _focusToBreakNotificationId,
      title: 'Focus complete',
      body: 'Break has started.',
      inSeconds: inSeconds,
    );
  }

  @override
  Future<void> scheduleBreakToFocus({required int inSeconds}) async {
    await _scheduleTransition(
      id: _breakToFocusNotificationId,
      title: 'Break complete',
      body: 'Focus has resumed.',
      inSeconds: inSeconds,
    );
  }

  @override
  Future<void> cancelAll() async {
    if (kIsWeb) {
      return;
    }
    try {
      await _plugin.cancel(_focusToBreakNotificationId);
      await _plugin.cancel(_breakToFocusNotificationId);
    } catch (_) {}
  }

  Future<void> _scheduleTransition({
    required int id,
    required String title,
    required String body,
    required int inSeconds,
  }) async {
    if (kIsWeb) {
      return;
    }
    await initialize();
    await cancelAll();
    if (!_permissionGranted || inSeconds <= 0) {
      return;
    }
    try {
      final tz.TZDateTime at = tz.TZDateTime.now(
        tz.local,
      ).add(Duration(seconds: inSeconds));
      const NotificationDetails details = NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      );
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        at,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {}
  }
}
