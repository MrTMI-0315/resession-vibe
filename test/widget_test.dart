import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resession/app/app.dart';
import 'package:resession/features/session/session_controller.dart';
import 'package:resession/features/session/session_notifications.dart';
import 'package:resession/features/session/session_record.dart';
import 'package:resession/features/session/session_storage.dart';

class _TestClock {
  _TestClock(this.now);

  DateTime now;

  void advance(Duration duration) {
    now = now.add(duration);
  }
}

class _FakeNotificationService implements SessionNotificationService {
  int initializeCalls = 0;
  int cancelCalls = 0;
  final List<String> scheduledEvents = <String>[];

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
  }

  @override
  Future<void> scheduleBreakToFocus({required int inSeconds}) async {
    scheduledEvents.add('break:$inSeconds');
  }

  @override
  Future<void> scheduleFocusToBreak({required int inSeconds}) async {
    scheduledEvents.add('focus:$inSeconds');
  }

  @override
  Future<void> cancelAll() async {
    cancelCalls += 1;
  }
}

void main() {
  testWidgets('App boots to idle home and supports 50/10 preset selection', (
    WidgetTester tester,
  ) async {
    final SessionController controller = SessionController(
      storage: InMemorySessionStorage(),
    );

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    expect(find.text('Resession'), findsOneWidget);
    expect(find.text('Idle'), findsOneWidget);
    expect(find.text('Start session'), findsOneWidget);
    expect(find.text('Focus • Break 5m'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('preset-check-25/5')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('preset-50/10')));
    await tester.pump();

    expect(find.text('Focus • Break 10m'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('preset-check-50/10')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('preset-check-25/5')),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets(
    'Custom bottom sheet applies 40/8 and starts with clamped seconds',
    (WidgetTester tester) async {
      final SessionController controller = SessionController(
        storage: InMemorySessionStorage(),
      );

      await tester.pumpWidget(ResessionApp(controller: controller));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey<String>('preset-custom')));
      await tester.pumpAndSettle();

      expect(find.text('Custom preset'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('custom-focus-input')),
        '40',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('custom-break-input')),
        '8',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('custom-confirm-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom (40/8)'), findsOneWidget);

      await tester.tap(find.text('Start session'));
      await tester.pump();

      expect(controller.runState.phase, SessionPhase.focus);
      expect(controller.runState.focusRemainingSeconds, 40 * 60);
      expect(controller.runState.breakRemainingSeconds, 8 * 60);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets('Start is disabled when custom is selected but not configured', (
    WidgetTester tester,
  ) async {
    final SessionController controller = SessionController(
      storage: InMemorySessionStorage(),
    );
    controller.selectPreset(SessionController.presets.last);

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    expect(find.text('Set custom minutes to start.'), findsOneWidget);

    final ElevatedButton button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Start session'),
    );
    expect(button.onPressed, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('Focus pauses during break and break budget does not reset', (
    WidgetTester tester,
  ) async {
    final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 0, 0, 0));
    final SessionController controller = SessionController(
      nowProvider: () => clock.now,
      storage: InMemorySessionStorage(),
    );

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    await tester.tap(find.text('Start session'));
    await tester.pump();

    clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('24:59'), findsOneWidget);

    await tester.tap(find.text('Pause'));
    await tester.pump();

    expect(find.text('Break'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);

    clock.advance(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('04:58'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await tester.pump();

    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('24:59'), findsOneWidget);

    await tester.tap(find.text('Pause'));
    await tester.pump();

    expect(find.text('Break'), findsOneWidget);
    expect(find.text('05:00'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('Break auto-resumes to focus when break reaches zero', (
    WidgetTester tester,
  ) async {
    final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 0, 0, 0));
    final SessionController controller = SessionController(
      nowProvider: () => clock.now,
      storage: InMemorySessionStorage(),
    );
    controller.selectCustomPreset(1, 1);

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    await tester.tap(find.text('Start session'));
    await tester.pump();
    await tester.tap(find.text('Pause'));
    await tester.pump();

    expect(controller.runState.phase, SessionPhase.breakTime);
    expect(find.text('Break'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);

    clock.advance(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 61));

    expect(controller.runState.phase, SessionPhase.focus);
    expect(controller.currentBreakRemainingSeconds, 0);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Resume'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('Notification schedule updates across focus and break phases', (
    WidgetTester tester,
  ) async {
    final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 0, 0, 0));
    final _FakeNotificationService notifications = _FakeNotificationService();
    final SessionController controller = SessionController(
      nowProvider: () => clock.now,
      storage: InMemorySessionStorage(),
      notifications: notifications,
    );
    controller.selectCustomPreset(1, 1);

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    await tester.tap(find.text('Start session'));
    await tester.pump();
    expect(notifications.scheduledEvents.last, 'focus:60');

    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(notifications.scheduledEvents.last, 'break:60');

    clock.advance(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 61));
    expect(controller.runState.phase, SessionPhase.focus);
    expect(notifications.scheduledEvents.last, 'focus:60');

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('Active session restores after controller recreation', (
    WidgetTester tester,
  ) async {
    final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 0, 0, 0));
    final InMemorySessionStorage storage = InMemorySessionStorage();

    final SessionController firstController = SessionController(
      nowProvider: () => clock.now,
      storage: storage,
      notifications: NoopSessionNotificationService(),
    );
    firstController.selectCustomPreset(1, 1);
    firstController.startSession();

    await tester.pumpWidget(ResessionApp(controller: firstController));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    firstController.dispose();

    clock.advance(const Duration(seconds: 30));

    final SessionController secondController = SessionController(
      nowProvider: () => clock.now,
      storage: storage,
      notifications: NoopSessionNotificationService(),
    );

    await tester.pumpWidget(ResessionApp(controller: secondController));
    await tester.pump();
    await tester.pump();

    expect(secondController.runState.phase, SessionPhase.focus);
    expect(
      secondController.currentFocusRemainingSeconds,
      inInclusiveRange(29, 30),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    secondController.dispose();
  });

  testWidgets('Drift bottom sheet logs category during focus', (
    WidgetTester tester,
  ) async {
    final SessionController controller = SessionController(
      storage: InMemorySessionStorage(),
    );

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    await tester.tap(find.text('Start session'));
    await tester.pump();
    expect(controller.runState.phase, SessionPhase.focus);

    await tester.tap(find.byKey(const ValueKey<String>('drift-open-button')));
    await tester.pumpAndSettle();

    expect(find.text('Drift log'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('drift-category-알림')));
    await tester.enterText(
      find.byKey(const ValueKey<String>('drift-note-input')),
      'ping',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('drift-confirm-button')),
    );
    await tester.pumpAndSettle();

    expect(controller.runState.phase, SessionPhase.focus);
    expect(controller.runState.driftEvents.length, 1);
    expect(controller.runState.driftEvents.last.category, '알림');
    expect(controller.runState.driftEvents.last.note, 'ping');

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets(
    'Large time jump clamps remaining to zero and transitions safely',
    (WidgetTester tester) async {
      final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 0, 0, 0));
      final SessionController controller = SessionController(
        nowProvider: () => clock.now,
        storage: InMemorySessionStorage(),
      );
      controller.selectCustomPreset(1, 1);

      await tester.pumpWidget(ResessionApp(controller: controller));
      await tester.pump();

      await tester.tap(find.text('Start session'));
      await tester.pump();

      expect(controller.runState.phase, SessionPhase.focus);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      clock.advance(const Duration(minutes: 90));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(controller.currentFocusRemainingSeconds, 0);
      expect(controller.runState.phase, SessionPhase.ended);
      expect(find.text('End'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets('Lifecycle resume refreshes UI immediately', (
    WidgetTester tester,
  ) async {
    final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 0, 0, 0));
    final SessionController controller = SessionController(
      nowProvider: () => clock.now,
      storage: InMemorySessionStorage(),
    );

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    await tester.tap(find.text('Start session'));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    clock.advance(const Duration(seconds: 5));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('24:55'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('Save persists and reloads recent sessions', (
    WidgetTester tester,
  ) async {
    final InMemorySessionStorage storage = InMemorySessionStorage();
    final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 0, 0, 0));

    final SessionController firstController = SessionController(
      nowProvider: () => clock.now,
      storage: storage,
    );
    firstController.selectCustomPreset(1, 1);

    await tester.pumpWidget(ResessionApp(controller: firstController));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey<String>('session-title-input')),
      'Write report',
    );
    await tester.pump();

    await tester.tap(find.text('Start session'));
    await tester.pump();

    clock.advance(const Duration(seconds: 65));
    await tester.pump(const Duration(seconds: 65));

    await tester.tap(find.text('Log / Save'));
    await tester.pump();

    expect(find.text('Recent Sessions'), findsOneWidget);
    expect(
      find.textContaining('Write report • Custom (1/1) •'),
      findsOneWidget,
    );
    expect(find.text('Session Summary'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    firstController.dispose();

    final SessionController secondController = SessionController(
      nowProvider: () => clock.now,
      storage: storage,
    );

    await tester.pumpWidget(ResessionApp(controller: secondController));
    await tester.pump();

    expect(find.text('Recent Sessions'), findsOneWidget);
    expect(
      find.textContaining('Write report • Custom (1/1) •'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    secondController.dispose();
  });

  testWidgets('Drift summary persists to home, end, and history', (
    WidgetTester tester,
  ) async {
    final InMemorySessionStorage storage = InMemorySessionStorage();
    final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 8, 0, 0));

    final SessionController firstController = SessionController(
      nowProvider: () => clock.now,
      storage: storage,
    );
    firstController.selectCustomPreset(1, 1);

    await tester.pumpWidget(ResessionApp(controller: firstController));
    await tester.pump();

    await tester.tap(find.text('Start session'));
    await tester.pump();

    firstController.logDrift(category: '알림');
    expect(firstController.runState.driftEvents.length, 1);

    clock.advance(const Duration(seconds: 65));
    await tester.pump(const Duration(seconds: 65));

    expect(find.text('Drift: 알림'), findsOneWidget);

    await tester.tap(find.text('Log / Save'));
    await tester.pump();
    expect(find.textContaining('Drift: 알림'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    firstController.dispose();

    final SessionController secondController = SessionController(
      nowProvider: () => clock.now,
      storage: storage,
    );

    await tester.pumpWidget(ResessionApp(controller: secondController));
    await tester.pump();

    expect(find.textContaining('Drift: 알림'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('history-nav-button')));
    await tester.pumpAndSettle();
    expect(find.text('Drift: 알림'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    secondController.dispose();
  });

  testWidgets('Drift note persists across end, home, and history', (
    WidgetTester tester,
  ) async {
    final InMemorySessionStorage storage = InMemorySessionStorage();
    final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 9, 0, 0));

    final SessionController firstController = SessionController(
      nowProvider: () => clock.now,
      storage: storage,
    );
    firstController.selectCustomPreset(1, 1);

    await tester.pumpWidget(ResessionApp(controller: firstController));
    await tester.pump();

    await tester.tap(find.text('Start session'));
    await tester.pump();

    firstController.logDrift(category: '메신저', note: 'quick check');
    expect(firstController.runState.driftEvents.length, 1);

    clock.advance(const Duration(seconds: 65));
    await tester.pump(const Duration(seconds: 65));

    expect(find.text('Drift: 메신저 (quick check)'), findsOneWidget);

    await tester.tap(find.text('Log / Save'));
    await tester.pump();
    expect(find.textContaining('Drift: 메신저 (quick check)'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    firstController.dispose();

    final SessionController secondController = SessionController(
      nowProvider: () => clock.now,
      storage: storage,
    );

    await tester.pumpWidget(ResessionApp(controller: secondController));
    await tester.pump();

    expect(find.textContaining('Drift: 메신저 (quick check)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('history-nav-button')));
    await tester.pumpAndSettle();
    expect(find.text('Drift: 메신저 (quick check)'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    secondController.dispose();
  });

  testWidgets('Drift format is identical across end, home, and history', (
    WidgetTester tester,
  ) async {
    final InMemorySessionStorage storage = InMemorySessionStorage();
    final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 10, 0, 0));
    final String driftText = 'Drift: 환경 (focus drift)';

    final SessionController controller = SessionController(
      nowProvider: () => clock.now,
      storage: storage,
    );
    controller.selectCustomPreset(1, 1);

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    await tester.tap(find.text('Start session'));
    await tester.pump();

    controller.logDrift(category: '환경', note: 'focus drift');
    clock.advance(const Duration(seconds: 65));
    await tester.pump(const Duration(seconds: 65));

    expect(find.text(driftText), findsOneWidget);

    await tester.tap(find.text('Log / Save'));
    await tester.pump();

    expect(find.textContaining(' • $driftText'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('history-nav-button')));
    await tester.pumpAndSettle();
    expect(find.text(driftText), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('Drift note empty and empty history keep drift format stable', (
    WidgetTester tester,
  ) async {
    final InMemorySessionStorage storage = InMemorySessionStorage();

    final SessionController emptyHistoryController = SessionController(
      storage: storage,
    );
    await tester.pumpWidget(ResessionApp(controller: emptyHistoryController));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('history-nav-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('history-empty-state-message')),
      findsOneWidget,
    );
    expect(find.textContaining('Drift: '), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    emptyHistoryController.dispose();

    final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 11, 0, 0));
    final SessionController controller = SessionController(
      nowProvider: () => clock.now,
      storage: storage,
    );
    controller.selectCustomPreset(1, 1);

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    await tester.tap(find.text('Start session'));
    await tester.pump();

    controller.logDrift(category: '완벽주의', note: '   ');
    clock.advance(const Duration(seconds: 65));
    await tester.pump(const Duration(seconds: 65));

    expect(find.text('Drift: 완벽주의'), findsOneWidget);

    await tester.tap(find.text('Log / Save'));
    await tester.pump();
    expect(find.textContaining(' • Drift: 완벽주의'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('history-nav-button')));
    await tester.pumpAndSettle();
    expect(find.text('Drift: 완벽주의'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets(
    'Drift empty and whitespace values render with stable formatting',
    (WidgetTester tester) async {
      final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 12, 0, 0));
      final SessionController controller = SessionController(
        nowProvider: () => clock.now,
        storage: InMemorySessionStorage(),
      );
      controller.selectCustomPreset(1, 1);

      await tester.pumpWidget(ResessionApp(controller: controller));
      await tester.pump();

      await tester.tap(find.text('Start session'));
      await tester.pump();

      controller.logDrift(category: '   ', note: 'ignored');
      clock.advance(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 10));
      expect(
        find.text('Drift: '),
        findsNothing,
        reason: 'blank category should not produce drift summary',
      );

      controller.logDrift(category: ' 알림 ', note: '   ');
      expect(controller.runState.driftEvents.length, 1);

      clock.advance(const Duration(seconds: 60));
      await tester.pump(const Duration(seconds: 60));
      expect(find.text('End'), findsOneWidget);
      expect(find.text('Drift: 알림'), findsOneWidget);

      await tester.tap(find.text('Log / Save'));
      await tester.pump();
      expect(find.textContaining(' • Drift: 알림'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('history-nav-button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Drift: 알림'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets(
    'Drift whitespace boundary formats stay stable as a snapshot across screens',
    (WidgetTester tester) async {
      final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 13, 0, 0));
      const String expectedSnapshot = 'Drift: 알림';

      final SessionController controller = SessionController(
        nowProvider: () => clock.now,
        storage: InMemorySessionStorage(),
      );
      controller.selectCustomPreset(1, 1);

      await tester.pumpWidget(ResessionApp(controller: controller));
      await tester.pump();

      await tester.tap(find.text('Start session'));
      await tester.pump();

      controller.logDrift(category: '   ', note: 'ignored');
      expect(controller.runState.driftEvents.length, 0);
      clock.advance(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));

      controller.logDrift(category: ' 알림 ', note: '  ');
      expect(controller.runState.driftEvents.length, 1);
      await tester.pump();

      clock.advance(const Duration(seconds: 65));
      await tester.pump(const Duration(seconds: 65));
      expect(find.text('End'), findsOneWidget);
      expect(find.text(expectedSnapshot), findsOneWidget);

      await tester.tap(find.text('Log / Save'));
      await tester.pump();
      expect(find.textContaining(' • $expectedSnapshot'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('history-nav-button')),
      );
      await tester.pumpAndSettle();
      expect(find.text(expectedSnapshot), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets(
    'Drift whitespace-normalized snapshot is identical across end, home, and history',
    (WidgetTester tester) async {
      final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 14, 0, 0));
      const String expectedSnapshot = 'Drift: 알림 (focus drift)';

      final SessionController controller = SessionController(
        nowProvider: () => clock.now,
        storage: InMemorySessionStorage(),
      );
      controller.selectCustomPreset(1, 1);

      await tester.pumpWidget(ResessionApp(controller: controller));
      await tester.pump();

      await tester.tap(find.text('Start session'));
      await tester.pump();

      controller.logDrift(category: '   ', note: 'ignored');
      expect(controller.runState.driftEvents.length, 0);

      controller.logDrift(category: ' 알림 ', note: '  focus drift  ');
      expect(controller.runState.driftEvents.length, 1);
      await tester.pump();

      clock.advance(const Duration(seconds: 65));
      await tester.pump(const Duration(seconds: 65));

      expect(find.text('End'), findsOneWidget);
      expect(find.text(expectedSnapshot), findsOneWidget);

      await tester.tap(find.text('Log / Save'));
      await tester.pump();
      expect(find.textContaining(' • $expectedSnapshot'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('history-nav-button')),
      );
      await tester.pumpAndSettle();
      expect(find.text(expectedSnapshot), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets(
    'Drift newline and trim snapshot is identical across end, home, and history',
    (WidgetTester tester) async {
      final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 15, 0, 0));
      const String expectedSnapshot = 'Drift: 알림 (focus\ndrift)';

      final SessionController controller = SessionController(
        nowProvider: () => clock.now,
        storage: InMemorySessionStorage(),
      );
      controller.selectCustomPreset(1, 1);

      await tester.pumpWidget(ResessionApp(controller: controller));
      await tester.pump();

      await tester.tap(find.text('Start session'));
      await tester.pump();

      controller.logDrift(category: '  알림 ', note: '  focus\ndrift  ');
      expect(controller.runState.driftEvents.length, 1);
      await tester.pump();

      clock.advance(const Duration(seconds: 65));
      await tester.pump(const Duration(seconds: 65));

      expect(find.text('End'), findsOneWidget);
      expect(find.textContaining(expectedSnapshot), findsOneWidget);

      await tester.tap(find.text('Log / Save'));
      await tester.pump();
      expect(find.textContaining(' • $expectedSnapshot'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('history-nav-button')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining(expectedSnapshot), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets(
    'Drift input/save path keeps identical summary on end, home, and history',
    (WidgetTester tester) async {
      final InMemorySessionStorage storage = InMemorySessionStorage();
      final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 16, 0, 0));
      const String expectedSnapshot = 'Drift: 알림 (focus\\ndrift)';

      final SessionController firstController = SessionController(
        nowProvider: () => clock.now,
        storage: storage,
      );
      firstController.selectCustomPreset(1, 1);

      await tester.pumpWidget(ResessionApp(controller: firstController));
      await tester.pump();

      await tester.tap(find.text('Start session'));
      await tester.pump();

      firstController.logDrift(category: '  알림 ', note: '  focus\\ndrift  ');
      expect(firstController.runState.driftEvents.length, 1);

      clock.advance(const Duration(seconds: 65));
      await tester.pump(const Duration(seconds: 65));
      expect(find.text('End'), findsOneWidget);
      expect(find.text(expectedSnapshot), findsOneWidget);

      await tester.tap(find.text('Log / Save'));
      await tester.pump();
      expect(find.textContaining(' • $expectedSnapshot'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      firstController.dispose();

      final SessionController secondController = SessionController(
        nowProvider: () => clock.now,
        storage: storage,
      );

      await tester.pumpWidget(ResessionApp(controller: secondController));
      await tester.pump();

      expect(find.textContaining(' • $expectedSnapshot'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('history-nav-button')),
      );
      await tester.pumpAndSettle();
      expect(find.text(expectedSnapshot), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      secondController.dispose();
    },
  );

  testWidgets(
    'Drift blank-note trim mix keeps summary consistent through end/home/history',
    (WidgetTester tester) async {
      final InMemorySessionStorage storage = InMemorySessionStorage();
      final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 17, 0, 0));
      const String expectedSnapshot = 'Drift: 알림';

      final SessionController firstController = SessionController(
        nowProvider: () => clock.now,
        storage: storage,
      );
      firstController.selectCustomPreset(1, 1);

      await tester.pumpWidget(ResessionApp(controller: firstController));
      await tester.pump();

      await tester.tap(find.text('Start session'));
      await tester.pump();

      firstController.logDrift(category: '   알림   ', note: '   ');
      expect(firstController.runState.driftEvents.length, 1);

      clock.advance(const Duration(seconds: 65));
      await tester.pump(const Duration(seconds: 65));
      expect(find.text('End'), findsOneWidget);
      expect(find.text(expectedSnapshot), findsOneWidget);

      await tester.tap(find.text('Log / Save'));
      await tester.pump();
      expect(find.textContaining(' • $expectedSnapshot'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      firstController.dispose();

      final SessionController secondController = SessionController(
        nowProvider: () => clock.now,
        storage: storage,
      );

      await tester.pumpWidget(ResessionApp(controller: secondController));
      await tester.pump();

      expect(find.textContaining(' • $expectedSnapshot'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('history-nav-button')),
      );
      await tester.pumpAndSettle();
      expect(find.text(expectedSnapshot), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      secondController.dispose();
    },
  );

  testWidgets(
    'Drift blank note keeps formatted snapshot through end, home, and history',
    (WidgetTester tester) async {
      final InMemorySessionStorage storage = InMemorySessionStorage();
      final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 18, 0, 0));
      const String expectedSnapshot = 'Drift: 알림';

      final SessionController firstController = SessionController(
        nowProvider: () => clock.now,
        storage: storage,
      );
      firstController.selectCustomPreset(1, 1);

      await tester.pumpWidget(ResessionApp(controller: firstController));
      await tester.pump();

      await tester.tap(find.text('Start session'));
      await tester.pump();

      firstController.logDrift(category: ' \n알림\n ', note: '   \n \t  ');
      expect(firstController.runState.driftEvents.length, 1);

      clock.advance(const Duration(seconds: 65));
      await tester.pump(const Duration(seconds: 65));
      expect(find.text('End'), findsOneWidget);
      expect(find.text(expectedSnapshot), findsOneWidget);

      await tester.tap(find.text('Log / Save'));
      await tester.pump();
      expect(find.textContaining(' • $expectedSnapshot'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      firstController.dispose();

      final SessionController secondController = SessionController(
        nowProvider: () => clock.now,
        storage: storage,
      );

      await tester.pumpWidget(ResessionApp(controller: secondController));
      await tester.pump();

      expect(find.textContaining(' • $expectedSnapshot'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('history-nav-button')),
      );
      await tester.pumpAndSettle();
      expect(find.text(expectedSnapshot), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      secondController.dispose();
    },
  );

  testWidgets('End screen shows session summary details', (
    WidgetTester tester,
  ) async {
    final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 9, 0, 0));
    final SessionController controller = SessionController(
      nowProvider: () => clock.now,
      storage: InMemorySessionStorage(),
    );
    controller.selectCustomPreset(1, 1);

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    await tester.tap(find.text('Start session'));
    await tester.pump();

    clock.advance(const Duration(seconds: 65));
    await tester.pump(const Duration(seconds: 65));

    expect(find.text('End'), findsOneWidget);
    expect(find.text('Session Summary'), findsOneWidget);
    expect(find.text('Title: Untitled'), findsOneWidget);
    expect(find.textContaining('Preset:'), findsOneWidget);
    expect(find.text('Planned: Focus 01:00 • Break 01:00'), findsOneWidget);
    expect(find.text('Actual: Focus 01:00 • Break 00:00'), findsOneWidget);
    expect(find.textContaining('Start:'), findsOneWidget);
    expect(find.textContaining('End:'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('History shows records in mm:ss with insight', (
    WidgetTester tester,
  ) async {
    final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 12, 0, 0));
    final InMemorySessionStorage storage = InMemorySessionStorage([
      SessionRecord(
        title: null,
        startedAt: DateTime(2026, 1, 1, 9, 0, 0),
        endedAt: DateTime(2026, 1, 1, 9, 30, 0),
        presetLabel: '25/5',
        plannedFocus: 25,
        plannedBreak: 5,
        actualFocusSeconds: 45,
        actualBreakSeconds: 15,
        completed: true,
      ),
      SessionRecord(
        title: 'Deep work',
        startedAt: DateTime(2026, 1, 1, 10, 0, 0),
        endedAt: DateTime(2026, 1, 1, 10, 35, 0),
        presetLabel: 'Custom (40/8)',
        plannedFocus: 40,
        plannedBreak: 8,
        actualFocusSeconds: 75,
        actualBreakSeconds: 20,
        completed: true,
      ),
    ]);

    final SessionController controller = SessionController(
      storage: storage,
      nowProvider: () => clock.now,
    );

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('history-nav-button')));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('history-insight-today-sessions')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('history-insight-today')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('history-insight-average')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('history-insight-top-drift')),
      findsOneWidget,
    );
    expect(find.text('Today Sessions: 2'), findsOneWidget);
    expect(find.text('Today Total Focus: 02:00'), findsOneWidget);
    expect(find.text('Average Focus (last 7): 01:00'), findsOneWidget);
    expect(find.text('Top Drift (last 7): none'), findsOneWidget);
    expect(find.text('Untitled'), findsOneWidget);
    expect(find.text('Deep work'), findsOneWidget);
    expect(find.text('Focus: 00:45'), findsOneWidget);
    expect(find.text('Break: 00:15'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('History completion insight and filter toggle', (
    WidgetTester tester,
  ) async {
    final InMemorySessionStorage storage = InMemorySessionStorage(
      List<SessionRecord>.generate(
        8,
        (int index) => SessionRecord(
          title: 'Session ${index + 1}',
          startedAt: DateTime(2026, 1, 1, 8, index, 0),
          endedAt: DateTime(2026, 1, 1, 8, index, 30),
          presetLabel: '25/5',
          plannedFocus: 25,
          plannedBreak: 5,
          actualFocusSeconds: 1500,
          actualBreakSeconds: 300,
          completed: index != 0,
        ),
      ),
    );

    final SessionController controller = SessionController(storage: storage);

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('history-nav-button')));
    await tester.pumpAndSettle();

    expect(find.text('Completion Rate (last 7): 100% (7/7)'), findsOneWidget);
    expect(find.text('Session 1'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('history-filter-all')));
    await tester.pumpAndSettle();

    expect(find.text('Completion Rate (all): 88% (7/8)'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Session 1'),
      find.byType(ListView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    expect(find.text('Session 1'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets(
    'History empty state aligns toggle labels with baseline strings',
    (WidgetTester tester) async {
      final SessionController controller = SessionController(
        storage: InMemorySessionStorage(),
      );

      await tester.pumpWidget(ResessionApp(controller: controller));
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('history-nav-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('history-empty-state-message')),
        findsOneWidget,
      );
      expect(find.text('Completion Rate (last 7): 0% (0/0)'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('history-filter-all')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('history-filter-recent-7')),
        findsOneWidget,
      );
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Recent 7'), findsOneWidget);

      final ChoiceChip allChip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey<String>('history-filter-all')),
      );
      final ChoiceChip recentChip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey<String>('history-filter-recent-7')),
      );
      expect(allChip.selected, isFalse);
      expect(recentChip.selected, isTrue);

      await tester.tap(
        find.byKey(const ValueKey<String>('history-filter-all')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('history-empty-state-message')),
        findsOneWidget,
      );
      expect(find.text('Completion Rate (all): 0% (0/0)'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('history-filter-recent-7')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('history-empty-state-message')),
        findsOneWidget,
      );
      expect(find.text('Completion Rate (last 7): 0% (0/0)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets('History filter state remains stable on long list scrolling', (
    WidgetTester tester,
  ) async {
    const int totalSessions = 30;
    const int recentWindow = 7;
    final List<SessionRecord> records = List<SessionRecord>.generate(
      totalSessions,
      (int index) => SessionRecord(
        title: 'Session ${index + 1}',
        startedAt: DateTime(2026, 1, 1, 9, index, 0),
        endedAt: DateTime(2026, 1, 1, 9, index, 30),
        presetLabel: '25/5',
        plannedFocus: 25,
        plannedBreak: 5,
        actualFocusSeconds: 1500,
        actualBreakSeconds: 300,
        completed: ((index + 1) % 3) != 0,
      ),
    );
    final List<SessionRecord> newestFirst = records.reversed.toList();
    final int allCompleted = records
        .where((SessionRecord item) => item.completed)
        .length;
    final int recentCompleted = newestFirst
        .take(recentWindow)
        .where((SessionRecord item) => item.completed)
        .length;

    String completionRate(int completed, int total) {
      if (total == 0) {
        return '0% (0/0)';
      }
      final int rate = ((completed * 100) / total).round();
      return '$rate% ($completed/$total)';
    }

    final InMemorySessionStorage storage = InMemorySessionStorage(records);

    final SessionController controller = SessionController(storage: storage);
    final Finder listFinder = find.byType(ListView);

    Future<void> revealSession(String title) async {
      for (int i = 0; i < 10; i++) {
        if (find.text(title).evaluate().isNotEmpty) {
          return;
        }
        await tester.drag(listFinder, const Offset(0, 300));
        await tester.pumpAndSettle();
      }
      for (int i = 0; i < 10; i++) {
        if (find.text(title).evaluate().isNotEmpty) {
          return;
        }
        await tester.drag(listFinder, const Offset(0, -300));
        await tester.pumpAndSettle();
      }
    }

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('history-nav-button')));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Session $totalSessions'),
      listFinder,
      const Offset(0, 300),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Completion Rate (last 7): ${completionRate(recentCompleted, recentWindow)}',
      ),
      findsOneWidget,
    );
    expect(find.text('Session $totalSessions'), findsOneWidget);
    expect(find.text('Session 1'), findsNothing);
    await revealSession('Session ${totalSessions - recentWindow + 1}');
    expect(
      find.text('Session ${totalSessions - recentWindow + 1}'),
      findsOneWidget,
    );
    expect(find.text('Session ${totalSessions - recentWindow}'), findsNothing);

    for (int turn = 0; turn < 2; turn += 1) {
      await tester.tap(
        find.byKey(const ValueKey<String>('history-filter-all')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Completion Rate (all): ${completionRate(allCompleted, totalSessions)}',
        ),
        findsOneWidget,
      );

      for (int i = 0; i < 6; i++) {
        await tester.drag(listFinder, const Offset(0, -300));
        await tester.pumpAndSettle();
      }

      await tester.dragUntilVisible(
        find.text('Session 1'),
        listFinder,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Session 1'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('history-filter-recent-7')),
      );
      await tester.pumpAndSettle();
      await revealSession('Session $totalSessions');
      expect(
        find.text(
          'Completion Rate (last 7): ${completionRate(recentCompleted, recentWindow)}',
        ),
        findsOneWidget,
      );
      await tester.dragUntilVisible(
        find.text('Session $totalSessions'),
        listFinder,
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Session 1'), findsNothing);
      expect(find.text('Session $totalSessions'), findsOneWidget);
      await revealSession('Session ${totalSessions - recentWindow + 1}');
      expect(
        find.text('Session ${totalSessions - recentWindow + 1}'),
        findsOneWidget,
      );
      expect(
        find.text('Session ${totalSessions - recentWindow}'),
        findsNothing,
      );
    }

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('History today focus excludes previous day records', (
    WidgetTester tester,
  ) async {
    final _TestClock clock = _TestClock(DateTime(2026, 1, 2, 9, 0, 0));
    final InMemorySessionStorage storage = InMemorySessionStorage([
      SessionRecord(
        title: 'Yesterday',
        startedAt: DateTime(2026, 1, 1, 10, 0, 0),
        endedAt: DateTime(2026, 1, 1, 10, 30, 0),
        presetLabel: '25/5',
        plannedFocus: 25,
        plannedBreak: 5,
        actualFocusSeconds: 600,
        actualBreakSeconds: 60,
        completed: true,
      ),
    ]);

    final SessionController controller = SessionController(
      storage: storage,
      nowProvider: () => clock.now,
    );

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('history-nav-button')));
    await tester.pumpAndSettle();

    expect(find.text('Today Sessions: 0'), findsOneWidget);
    expect(find.text('Today Total Focus: 00:00'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('History today sessions includes today and excludes yesterday', (
    WidgetTester tester,
  ) async {
    final _TestClock clock = _TestClock(DateTime(2026, 1, 2, 9, 0, 0));
    final InMemorySessionStorage storage = InMemorySessionStorage([
      SessionRecord(
        title: 'Today 1',
        startedAt: DateTime(2026, 1, 2, 7, 0, 0),
        endedAt: DateTime(2026, 1, 2, 7, 20, 0),
        presetLabel: '25/5',
        plannedFocus: 25,
        plannedBreak: 5,
        actualFocusSeconds: 300,
        actualBreakSeconds: 20,
        completed: true,
      ),
      SessionRecord(
        title: 'Today 2',
        startedAt: DateTime(2026, 1, 2, 8, 0, 0),
        endedAt: DateTime(2026, 1, 2, 8, 20, 0),
        presetLabel: '25/5',
        plannedFocus: 25,
        plannedBreak: 5,
        actualFocusSeconds: 400,
        actualBreakSeconds: 25,
        completed: true,
      ),
      SessionRecord(
        title: 'Yesterday',
        startedAt: DateTime(2026, 1, 1, 8, 0, 0),
        endedAt: DateTime(2026, 1, 1, 8, 20, 0),
        presetLabel: '25/5',
        plannedFocus: 25,
        plannedBreak: 5,
        actualFocusSeconds: 500,
        actualBreakSeconds: 30,
        completed: true,
      ),
    ]);

    final SessionController controller = SessionController(
      storage: storage,
      nowProvider: () => clock.now,
    );

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('history-nav-button')));
    await tester.pumpAndSettle();

    expect(find.text('Today Sessions: 2'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('History top drift insight shows deterministic tie-break', (
    WidgetTester tester,
  ) async {
    final InMemorySessionStorage storage = InMemorySessionStorage([
      SessionRecord(
        title: 'One',
        startedAt: DateTime(2026, 1, 1, 9, 0, 0),
        endedAt: DateTime(2026, 1, 1, 9, 10, 0),
        presetLabel: '25/5',
        plannedFocus: 25,
        plannedBreak: 5,
        actualFocusSeconds: 60,
        actualBreakSeconds: 10,
        completed: true,
        drifts: const [
          DriftEvent(atEpochMs: 1, category: 'A'),
          DriftEvent(atEpochMs: 2, category: 'B'),
        ],
      ),
      SessionRecord(
        title: 'Two',
        startedAt: DateTime(2026, 1, 1, 10, 0, 0),
        endedAt: DateTime(2026, 1, 1, 10, 10, 0),
        presetLabel: '25/5',
        plannedFocus: 25,
        plannedBreak: 5,
        actualFocusSeconds: 70,
        actualBreakSeconds: 20,
        completed: true,
        drifts: const [DriftEvent(atEpochMs: 3, category: 'B')],
      ),
      SessionRecord(
        title: 'Three',
        startedAt: DateTime(2026, 1, 1, 11, 0, 0),
        endedAt: DateTime(2026, 1, 1, 11, 10, 0),
        presetLabel: '25/5',
        plannedFocus: 25,
        plannedBreak: 5,
        actualFocusSeconds: 80,
        actualBreakSeconds: 30,
        completed: true,
        drifts: const [DriftEvent(atEpochMs: 4, category: 'A')],
      ),
    ]);

    final SessionController controller = SessionController(storage: storage);

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('history-nav-button')));
    await tester.pumpAndSettle();

    expect(find.text('Top Drift (last 7): A (2)'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('Title fallback is Untitled when session title is empty', (
    WidgetTester tester,
  ) async {
    final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 0, 0, 0));
    final SessionController controller = SessionController(
      nowProvider: () => clock.now,
      storage: InMemorySessionStorage(),
    );
    controller.selectCustomPreset(1, 1);

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey<String>('session-title-input')),
      '',
    );
    await tester.pump();

    await tester.tap(find.text('Start session'));
    await tester.pump();

    clock.advance(const Duration(seconds: 65));
    await tester.pump(const Duration(seconds: 65));
    await tester.tap(find.text('Log / Save'));
    await tester.pump();

    expect(find.textContaining('Untitled • Custom (1/1) •'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('history-nav-button')));
    await tester.pumpAndSettle();
    expect(find.text('Untitled'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('Session title whitespace is normalized in UI and controller', (
    WidgetTester tester,
  ) async {
    final SessionController controller = SessionController(
      storage: InMemorySessionStorage(),
      notifications: NoopSessionNotificationService(),
    );
    const String noisyTitle = '   deep    work   ';

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey<String>('session-title-input')),
      noisyTitle,
    );
    await tester.pump();

    expect(controller.pendingSessionTitle, 'deep work');

    controller.startSession();
    expect(controller.runState.sessionTitle, 'deep work');

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('Session title clamps to 40 chars after whitespace normalization', (
    WidgetTester tester,
  ) async {
    final SessionController controller = SessionController(
      storage: InMemorySessionStorage(),
      notifications: NoopSessionNotificationService(),
    );
    const String noisyTitle =
        '  1234567890    1234567890    1234567890    1234567890    1234567890  ';
    const String expected = '1234567890 1234567890 1234567890 1234567';

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey<String>('session-title-input')),
      noisyTitle,
    );
    await tester.pump();

    expect(controller.pendingSessionTitle, expected);
    expect(controller.pendingSessionTitle.length, 40);

    controller.startSession();
    expect(controller.runState.sessionTitle, expected);
    expect(controller.runState.sessionTitle?.length, 40);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
