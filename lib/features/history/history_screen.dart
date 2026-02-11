import 'package:flutter/material.dart';

import '../session/session_controller.dart';
import '../session/session_record.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final List<SessionRecord> records = controller.records.reversed
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFF1C1D20),
          appBar: AppBar(
            title: const Text('History'),
            backgroundColor: const Color(0xFF1C1D20),
            foregroundColor: Colors.white,
          ),
          body: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InsightHeader(records: records),
                const SizedBox(height: 12),
                Expanded(
                  child: records.isEmpty
                      ? const Center(
                          child: Text(
                            'No records yet.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7A7A7A),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: records.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (BuildContext context, int index) {
                            final SessionRecord record = records[index];
                            return _RecordCard(record: record);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InsightHeader extends StatelessWidget {
  const _InsightHeader({required this.records});

  final List<SessionRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Text(
        'Insight: no data yet.',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      );
    }

    final List<SessionRecord> recent = records.take(7).toList();
    final int focusSum = recent.fold<int>(
      0,
      (int total, SessionRecord item) => total + item.actualFocusSeconds,
    );
    final int avgFocus = focusSum ~/ recent.length;

    return Text(
      'Average Focus (last ${recent.length}): ${SessionController.formatDurationMMSS(avgFocus)}',
      key: const ValueKey<String>('history-insight'),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});

  final SessionRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SessionController.displayTitle(record.title),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Preset: ${record.presetLabel}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Focus: ${SessionController.formatDurationMMSS(record.actualFocusSeconds)}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Break: ${SessionController.formatDurationMMSS(record.actualBreakSeconds)}',
            style: const TextStyle(fontSize: 12),
          ),
          if (SessionController.summarizeLastDriftCategory(record.drifts) !=
              null)
            Text(
              'Drift: ${SessionController.summarizeLastDriftCategory(record.drifts)}',
              style: const TextStyle(fontSize: 12),
            ),
          Text(
            'Start: ${_formatDateTime(record.startedAt)}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }
}
