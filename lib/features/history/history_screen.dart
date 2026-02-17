import 'package:flutter/material.dart';

import '../session/session_controller.dart';
import '../session/session_record.dart';
import '../../ui/theme/app_tone.dart';

enum _HistoryFilterScope { all, recent7 }

const String _emptyHistoryMessage = 'No records yet.';

extension _HistoryFilterScopeUX on _HistoryFilterScope {
  String get chipLabel {
    return switch (this) {
      _HistoryFilterScope.all => 'All',
      _HistoryFilterScope.recent7 => 'Recent 7',
    };
  }

  String get completionWindowLabel {
    return switch (this) {
      _HistoryFilterScope.all => 'all',
      _HistoryFilterScope.recent7 =>
        'last ${SessionController.historyInsightWindowSize}',
    };
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.controller});

  final SessionController controller;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _HistoryFilterScope _filterScope = _HistoryFilterScope.recent7;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, _) {
        final List<SessionRecord> records =
            _filterScope == _HistoryFilterScope.recent7
            ? widget.controller.records.reversed
                  .take(SessionController.historyInsightWindowSize)
                  .toList()
            : widget.controller.records.reversed.toList();

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
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InsightHeader(
                  controller: widget.controller,
                  filterScope: _filterScope,
                  hasRecords: records.isNotEmpty,
                  onFilterScopeChanged: (_HistoryFilterScope nextScope) {
                    setState(() => _filterScope = nextScope);
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: records.isEmpty
                      ? const Center(
                          child: Text(
                            _emptyHistoryMessage,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7A7A7A),
                            ),
                            key: ValueKey<String>(
                              'history-empty-state-message',
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: records.length,
                          separatorBuilder: (_, int index) => Divider(
                            height: 1,
                            thickness: 1,
                            color: AppTone.surfaceBorder,
                            indent: 12,
                            endIndent: 12,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            final SessionRecord record = records[index];
                            return _RecordCard(
                              record: record,
                              key: ValueKey<String>(
                                'history-record-row-$index',
                              ),
                            );
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
  const _InsightHeader({
    required this.controller,
    required this.filterScope,
    required this.hasRecords,
    required this.onFilterScopeChanged,
  });

  final SessionController controller;
  final _HistoryFilterScope filterScope;
  final bool hasRecords;
  final ValueChanged<_HistoryFilterScope> onFilterScopeChanged;

  @override
  Widget build(BuildContext context) {
    final String completionRateText = hasRecords
        ? (filterScope == _HistoryFilterScope.recent7
              ? controller.historyCompletionRateInsight(
                  window: SessionController.historyInsightWindowSize,
                )
              : controller.historyCompletionRateInsight())
        : 'Completion Rate (${filterScope.completionWindowLabel}): 0% (0/0)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          controller.historyTodaySessionsCountInsight,
          key: const ValueKey<String>('history-insight-today-sessions'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          controller.historyTodayTotalFocusInsight,
          key: const ValueKey<String>('history-insight-today'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          controller.historyAverageFocusInsight,
          key: const ValueKey<String>('history-insight-average'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          controller.historyTopDriftInsight,
          key: const ValueKey<String>('history-insight-top-drift'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: <Widget>[
            ChoiceChip(
              key: const ValueKey<String>('history-filter-all'),
              label: Text(_HistoryFilterScope.all.chipLabel),
              selected: filterScope == _HistoryFilterScope.all,
              onSelected: (_) => onFilterScopeChanged(_HistoryFilterScope.all),
            ),
            ChoiceChip(
              key: const ValueKey<String>('history-filter-recent-7'),
              label: Text(_HistoryFilterScope.recent7.chipLabel),
              selected: filterScope == _HistoryFilterScope.recent7,
              onSelected: (_) =>
                  onFilterScopeChanged(_HistoryFilterScope.recent7),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          completionRateText,
          key: const ValueKey<String>('history-insight-completion-rate'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, super.key});

  final SessionRecord record;

  @override
  Widget build(BuildContext context) {
    final String presetLabel = record.presetLabel;
    final String driftSummary =
        SessionController.summarizeLastDriftSummary(record.drifts) ?? '';
    final String focusDuration = SessionController.formatDurationMMSS(
      record.actualFocusSeconds,
    );
    final String line2 = driftSummary.isEmpty
        ? '$presetLabel • Focus $focusDuration • ${_formatDateTime(record.endedAt)}'
        : '$presetLabel • Focus $focusDuration • $driftSummary • ${_formatDateTime(record.endedAt)}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTone.surface,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(
          BorderSide(color: AppTone.surfaceBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SessionController.displayTitle(record.title),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTone.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            line2,
            style: const TextStyle(
              fontSize: 13,
              color: AppTone.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
          if (driftSummary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTone.surfaceStrong,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      driftSummary,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTone.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
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
