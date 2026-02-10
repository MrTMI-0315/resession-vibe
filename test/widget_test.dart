import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resession/app/app.dart';
import 'package:resession/features/session/session_controller.dart';

class _TestClock {
  _TestClock(this.now);

  DateTime now;

  void advance(Duration duration) {
    now = now.add(duration);
  }
}

void main() {
  testWidgets('App boots to idle home and supports preset selection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ResessionApp());

    expect(find.text('Resession'), findsOneWidget);
    expect(find.text('Idle'), findsOneWidget);
    expect(find.text('Start session'), findsOneWidget);
    expect(find.text('Focus • Break 5m'), findsOneWidget);

    await tester.ensureVisible(find.text('50/10'));
    await tester.tap(find.text('50/10'));
    await tester.pump();

    expect(find.text('Focus • Break 10m'), findsOneWidget);

    await tester.ensureVisible(find.text('custom'));
    await tester.tap(find.text('custom'));
    await tester.pump();

    expect(find.text('01:00'), findsOneWidget);
  });

  testWidgets('Focus pauses during break and break budget does not reset', (
    WidgetTester tester,
  ) async {
    final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 0, 0, 0));
    final SessionController controller = SessionController(
      nowProvider: () => clock.now,
    );

    await tester.pumpWidget(ResessionApp(controller: controller));

    await tester.ensureVisible(find.text('Start session'));
    await tester.tap(find.text('Start session'));
    await tester.pump();

    clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('24:59'), findsOneWidget);

    await tester.ensureVisible(find.text('Pause'));
    await tester.tap(find.text('Pause'));
    await tester.pump();

    expect(find.text('Break'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);

    clock.advance(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('04:58'), findsOneWidget);

    await tester.ensureVisible(find.text('Resume'));
    await tester.tap(find.text('Resume'));
    await tester.pump();

    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('24:59'), findsOneWidget);

    await tester.ensureVisible(find.text('Pause'));
    await tester.tap(find.text('Pause'));
    await tester.pump();

    expect(find.text('Break'), findsOneWidget);
    expect(find.text('05:00'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('Session flow transitions focus, end, and reset', (
    WidgetTester tester,
  ) async {
    final _TestClock clock = _TestClock(DateTime(2026, 1, 1, 0, 0, 0));
    final SessionController controller = SessionController(
      nowProvider: () => clock.now,
    );

    await tester.pumpWidget(ResessionApp(controller: controller));

    await tester.ensureVisible(find.text('custom'));
    await tester.tap(find.text('custom'));
    await tester.pump();

    await tester.ensureVisible(find.text('Start session'));
    await tester.tap(find.text('Start session'));
    await tester.pump();

    expect(find.text('Focus'), findsOneWidget);

    clock.advance(const Duration(seconds: 65));
    await tester.pump(const Duration(seconds: 65));

    expect(find.text('End'), findsOneWidget);
    expect(find.text('Log / Save'), findsOneWidget);

    await tester.ensureVisible(find.text('Log / Save'));
    await tester.tap(find.text('Log / Save'));
    await tester.pump();

    expect(find.text('Idle'), findsOneWidget);
    expect(find.text('Start session'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
