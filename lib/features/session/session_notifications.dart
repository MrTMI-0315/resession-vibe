import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:resession/services/notification_service.dart';

abstract class SessionNotificationService {
  Future<void> initialize();

  Future<void> scheduleFocusToBreak({required int inSeconds});

  Future<void> scheduleBreakToFocus({required int inSeconds});

  Future<void> scheduleFocusComplete({required int inSeconds});

  Future<void> cancelFocusComplete();

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
  Future<void> scheduleFocusComplete({required int inSeconds}) async {}

  @override
  Future<void> cancelFocusComplete() async {}

  @override
  Future<void> cancelAll() async {}
}

class LocalSessionNotificationService implements SessionNotificationService {
  static const int _focusCompleteNotificationId = 2001;
  static const int _breakToFocusNotificationId = 11002;

  LocalSessionNotificationService({NotificationService? notificationService})
    : _notificationService = notificationService ?? NotificationService() {
    _plugin = _notificationService.plugin;
  }

  late final NotificationService _notificationService;
  late final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _permissionGranted = false;

  @override
  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }
    try {
      tz.initializeTimeZones();
      await _notificationService.init();
      _permissionGranted = await _notificationService.requestPermissions();
      _initialized = true;
    } catch (_) {
      _initialized = true;
      _permissionGranted = false;
    }
  }

  @override
  Future<void> scheduleFocusToBreak({required int inSeconds}) async {
    await scheduleFocusComplete(inSeconds: inSeconds);
  }

  @override
  Future<void> scheduleFocusComplete({required int inSeconds}) async {
    await _scheduleTransition(
      id: _focusCompleteNotificationId,
      title: 'Focus complete',
      body: 'Break has started.',
      inSeconds: inSeconds,
      sound: 'default',
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
      await cancelFocusComplete();
      await _plugin.cancel(id: _breakToFocusNotificationId);
    } catch (_) {}
  }

  @override
  Future<void> cancelFocusComplete() async {
    if (kIsWeb) {
      return;
    }
    try {
      await _plugin.cancel(id: _focusCompleteNotificationId);
    } catch (_) {}
  }

  Future<void> _scheduleTransition({
    required int id,
    required String title,
    required String body,
    required int inSeconds,
    String? sound,
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
      final NotificationDetails details = NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
          sound: sound,
        ),
      );
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: at,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {}
  }
}
