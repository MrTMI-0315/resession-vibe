import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resession/app/app.dart';
import 'package:resession/features/session/session_controller.dart';
import 'package:resession/features/session/session_record.dart';
import 'package:resession/features/session/session_storage.dart';

class _TestClock {
  _TestClock(this.now);

  DateTime now;

  void advance(Duration duration) {
    now = now.add(duration);
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

    final SessionController controller = SessionController(storage: storage);

    await tester.pumpWidget(ResessionApp(controller: controller));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('history-nav-button')));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('history-insight')),
      findsOneWidget,
    );
    expect(find.text('Average Focus (last 2): 01:00'), findsOneWidget);
    expect(find.text('Untitled'), findsOneWidget);
    expect(find.text('Deep work'), findsOneWidget);
    expect(find.text('Focus: 00:45'), findsOneWidget);
    expect(find.text('Break: 00:15'), findsOneWidget);

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
}
