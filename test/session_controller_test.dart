import 'package:flutter_test/flutter_test.dart';
import 'package:resession/features/session/session_controller.dart';
import 'package:resession/features/session/session_notifications.dart';
import 'package:resession/features/session/session_storage.dart';

class _MutableClock {
  _MutableClock(this._now);

  DateTime _now;

  DateTime call() => _now;

  void advance(Duration delta) {
    _now = _now.add(delta);
  }
}

Future<void> _drainAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('SessionController state transitions', () {
    test('transitions idle->focus->break->focus->ended', () async {
      final _MutableClock clock = _MutableClock(DateTime(2026, 2, 13, 10));
      final InMemorySessionStorage storage = InMemorySessionStorage();
      final SessionController controller = SessionController(
        nowProvider: clock.call,
        storage: storage,
        notifications: NoopSessionNotificationService(),
      );
      addTearDown(controller.dispose);
      await _drainAsyncWork();

      expect(controller.runState.phase, SessionPhase.idle);

      controller.selectCustomPreset(1, 1);
      controller.startSession(title: 'focus block');
      expect(controller.runState.phase, SessionPhase.focus);

      clock.advance(const Duration(seconds: 5));
      controller.pauseForBreak();
      expect(controller.runState.phase, SessionPhase.breakTime);
      expect(
        controller.runState.focusRemainingSeconds,
        lessThan(const Duration(minutes: 1).inSeconds),
      );

      clock.advance(const Duration(seconds: 3));
      controller.resumeFocus();
      expect(controller.runState.phase, SessionPhase.focus);
      expect(
        controller.runState.breakRemainingSeconds,
        lessThan(const Duration(minutes: 1).inSeconds),
      );

      clock.advance(const Duration(seconds: 120));
      controller.handleAppResumed();

      expect(controller.runState.phase, SessionPhase.ended);
      expect(controller.runState.endedAt, isNotNull);
    });

    test('restores persisted active run consistently', () async {
      final _MutableClock clock = _MutableClock(DateTime(2026, 2, 13, 11));
      final InMemorySessionStorage storage = InMemorySessionStorage();

      final SessionController firstController = SessionController(
        nowProvider: clock.call,
        storage: storage,
        notifications: NoopSessionNotificationService(),
      );
      await _drainAsyncWork();
      firstController.selectCustomPreset(1, 1);
      firstController.startSession(title: 'restore me');
      clock.advance(const Duration(seconds: 10));
      firstController.pauseForBreak();
      await _drainAsyncWork();

      final SessionPhase savedPhase = firstController.runState.phase;
      final int savedFocusRemaining =
          firstController.runState.focusRemainingSeconds;
      final int savedBreakRemaining =
          firstController.runState.breakRemainingSeconds;
      final String? savedTitle = firstController.runState.sessionTitle;
      firstController.dispose();

      final SessionController restoredController = SessionController(
        nowProvider: clock.call,
        storage: storage,
        notifications: NoopSessionNotificationService(),
      );
      addTearDown(restoredController.dispose);
      await _drainAsyncWork();

      expect(restoredController.runState.phase, savedPhase);
      expect(
        restoredController.runState.focusRemainingSeconds,
        savedFocusRemaining,
      );
      expect(
        restoredController.runState.breakRemainingSeconds,
        savedBreakRemaining,
      );
      expect(restoredController.runState.sessionTitle, savedTitle);
    });
  });
}
