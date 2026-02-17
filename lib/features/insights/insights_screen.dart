import 'dart:math';

import 'package:flutter/material.dart';

import '../session/session_controller.dart';
import '../session/session_record.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final DateTime now = DateTime.now();
        final _WeeklyInsightData data = _buildWeeklyData(
          now: now,
          records: controller.records,
        );

        return Scaffold(
          backgroundColor: const Color(0xFF1C1D20),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This week',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (!data.hasSessions)
                      _InsightsEmptyState(
                        onStartSession: () {
                          if (controller.canStartSession) {
                            Navigator.of(context).pop();
                            controller.startSession(
                              title: controller.pendingSessionTitle,
                            );
                          }
                        },
                        isEnabled: controller.canStartSession,
                      ),
                    if (!data.hasSessions) const SizedBox(height: 12),
                    _SummaryCard(data: data),
                    const SizedBox(height: 12),
                    _DriftChartCard(data: data),
                    const SizedBox(height: 12),
                    Text(
                      'Updated: ${data.dateRangeLabel}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

_WeeklyInsightData _buildWeeklyData({
  required DateTime now,
  required List<SessionRecord> records,
}) {
  final DateTime weekStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final DateTime weekEnd = weekStart.add(const Duration(days: 7));

  List<SessionRecord> weeklyRecords = records
      .where(
        (SessionRecord item) =>
            !item.startedAt.isBefore(weekStart) &&
            item.startedAt.isBefore(weekEnd),
      )
      .toList(growable: false);

  final int focusSeconds = weeklyRecords.fold<int>(
    0,
    (int total, SessionRecord item) => total + item.actualFocusSeconds,
  );
  final List<_DriftBar> driftBars = _buildDriftBars(weeklyRecords);
  final int completedSessions = weeklyRecords
      .where((SessionRecord item) => item.completed)
      .length;

  final int sessionCount = weeklyRecords.length;
  final bool hasSessions = sessionCount > 0;
  final String completion = sessionCount == 0
      ? '—'
      : '${((completedSessions * 100) / sessionCount).round()}% ($completedSessions/$sessionCount)';

  return _WeeklyInsightData(
    hasSessions: hasSessions,
    focusText: hasSessions
        ? SessionController.formatDurationMMSS(focusSeconds)
        : '—',
    sessionsText: '$sessionCount',
    completionText: completion,
    topDriftText: hasSessions ? _topDriftText(driftBars) : '—',
    driftBars: driftBars,
    dateRangeLabel:
        '${_formatMonthDay(weekStart)} - ${_formatMonthDay(weekEnd)}',
  );
}

List<_DriftBar> _buildDriftBars(List<SessionRecord> records) {
  final Map<String, int> counts = <String, int>{};

  for (final SessionRecord record in records) {
    for (final DriftEvent drift in record.drifts) {
      final String category = drift.category.trim();
      if (category.isEmpty) {
        continue;
      }
      counts[category] = (counts[category] ?? 0) + 1;
    }
  }

  final List<_DriftBar> result = counts.entries
      .map(
        (MapEntry<String, int> entry) =>
            _DriftBar(category: entry.key, count: entry.value),
      )
      .toList(growable: false);

  result.sort(
    (_DriftBar a, _DriftBar b) => b.count == a.count
        ? a.category.compareTo(b.category)
        : b.count.compareTo(a.count),
  );

  return result.take(6).toList(growable: false);
}

String _topDriftText(List<_DriftBar> bars) {
  if (bars.isEmpty) {
    return '—';
  }
  return '${bars.first.category} (${bars.first.count})';
}

String _formatMonthDay(DateTime value) {
  final String month = value.month.toString().padLeft(2, '0');
  final String day = value.day.toString().padLeft(2, '0');
  return '$month/$day';
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _WeeklyInsightData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _KpiItem(label: 'Focus Time', value: data.focusText),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _KpiItem(label: 'Sessions', value: data.sessionsText),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _KpiItem(label: 'Completion', value: data.completionText),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _KpiItem(label: 'Top Drift', value: data.topDriftText),
          ),
        ],
      ),
    );
  }
}

class _KpiItem extends StatelessWidget {
  const _KpiItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
        ),
      ],
    );
  }
}

class _DriftChartCard extends StatelessWidget {
  const _DriftChartCard({required this.data});

  final _WeeklyInsightData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Drift distribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: _DriftBarPainter(entries: data.driftBars),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          if (data.driftBars.isEmpty)
            Text(
              data.hasSessions ? 'No drift events yet' : 'No drift data yet',
              style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: data.driftBars
                  .map(
                    (_DriftBar item) => Text(
                      '${item.category}: ${item.count}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF444444),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _DriftBarPainter extends CustomPainter {
  const _DriftBarPainter({required this.entries});

  final List<_DriftBar> entries;

  @override
  void paint(Canvas canvas, Size size) {
    final double left = 14;
    final double right = size.width - 14;
    final double baselineY = size.height - 30;
    final double baseHeight = baselineY;

    final Paint axisPaint = Paint()
      ..color = const Color(0xFFE4E4E4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(left, baselineY),
      Offset(right, baselineY),
      axisPaint,
    );

    if (entries.isEmpty) {
      return;
    }

    final int maxCount = entries
        .map((_DriftBar item) => item.count)
        .reduce((int a, int b) => max(a, b));
    final double availableWidth = (right - left) - 10;
    final double spacing = availableWidth / entries.length;
    final double barWidth = min(10.0, spacing * 0.5);
    final double maxHeight = baseHeight - 18;

    for (int i = 0; i < entries.length; i += 1) {
      final _DriftBar entry = entries[i];
      final double ratio = entry.count / maxCount;
      final double barHeight = maxHeight * ratio;
      final double leftX = left + 5 + spacing * i + (spacing - barWidth) / 2;
      final double barTop = baselineY - barHeight;
      final Rect barRect = Rect.fromLTWH(
        leftX,
        barTop,
        barWidth,
        baselineY - barTop,
      );
      final RRect barRRect = RRect.fromRectAndRadius(
        barRect,
        const Radius.circular(100),
      );
      final Paint barPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF89CBFD);
      canvas.drawRRect(barRRect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DriftBarPainter oldDelegate) {
    return oldDelegate.entries != entries;
  }
}

class _DriftBar {
  const _DriftBar({required this.category, required this.count});

  final String category;
  final int count;
}

class _WeeklyInsightData {
  const _WeeklyInsightData({
    required this.hasSessions,
    required this.focusText,
    required this.sessionsText,
    required this.completionText,
    required this.topDriftText,
    required this.driftBars,
    required this.dateRangeLabel,
  });

  final bool hasSessions;
  final String focusText;
  final String sessionsText;
  final String completionText;
  final String topDriftText;
  final List<_DriftBar> driftBars;
  final String dateRangeLabel;
}

class _InsightsEmptyState extends StatelessWidget {
  const _InsightsEmptyState({
    required this.onStartSession,
    required this.isEnabled,
  });

  final void Function() onStartSession;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'No sessions this week',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Start a session to see your patterns here.',
            style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            key: const ValueKey<String>('insights-start-session-button'),
            onPressed: isEnabled ? onStartSession : null,
            child: const Text('Start session'),
          ),
        ],
      ),
    );
  }
}
