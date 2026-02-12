import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'session_notifications.dart';
import 'session_record.dart';
import 'session_storage.dart';

enum SessionPhase { idle, focus, breakTime, ended }

class SessionPreset {
  const SessionPreset({
    required this.focusMinutes,
    required this.breakMinutes,
    required this.label,
  });

  final int focusMinutes;
  final int breakMinutes;
  final String label;

  int get focusSeconds => focusMinutes * 60;
  int get breakSeconds => breakMinutes * 60;
}

class SessionRunState {
  const SessionRunState({
    required this.preset,
    required this.phase,
    required this.sessionTitle,
    required this.driftEvents,
    required this.focusRemainingSeconds,
    required this.breakRemainingSeconds,
    required this.phaseStartedAt,
    required this.startedAt,
    required this.endedAt,
  });

  factory SessionRunState.idle({required SessionPreset preset}) {
    return SessionRunState(
      preset: preset,
      phase: SessionPhase.idle,
      sessionTitle: null,
      driftEvents: const <DriftEvent>[],
      focusRemainingSeconds: preset.focusSeconds,
      breakRemainingSeconds: preset.breakSeconds,
      phaseStartedAt: null,
      startedAt: null,
      endedAt: null,
    );
  }

  final SessionPreset preset;
  final SessionPhase phase;
  final String? sessionTitle;
  final List<DriftEvent> driftEvents;
  final int focusRemainingSeconds;
  final int breakRemainingSeconds;
  final DateTime? phaseStartedAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  SessionRunState copyWith({
    SessionPreset? preset,
    SessionPhase? phase,
    String? sessionTitle,
    List<DriftEvent>? driftEvents,
    int? focusRemainingSeconds,
    int? breakRemainingSeconds,
    DateTime? phaseStartedAt,
    DateTime? startedAt,
    DateTime? endedAt,
    bool clearPhaseStartedAt = false,
    bool clearEndedAt = false,
  }) {
    return SessionRunState(
      preset: preset ?? this.preset,
      phase: phase ?? this.phase,
      sessionTitle: sessionTitle ?? this.sessionTitle,
      driftEvents: driftEvents ?? this.driftEvents,
      focusRemainingSeconds:
          focusRemainingSeconds ?? this.focusRemainingSeconds,
      breakRemainingSeconds:
          breakRemainingSeconds ?? this.breakRemainingSeconds,
      phaseStartedAt: clearPhaseStartedAt
          ? null
          : (phaseStartedAt ?? this.phaseStartedAt),
      startedAt: startedAt ?? this.startedAt,
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
    );
  }
}

class SessionController extends ChangeNotifier {
  SessionController({
    DateTime Function()? nowProvider,
    SessionStorage? storage,
    SessionNotificationService? notifications,
  }) : _selectedPreset = presets.first,
       _runState = SessionRunState.idle(preset: presets.first),
       _now = nowProvider ?? DateTime.now,
       _storage = storage ?? SharedPreferencesSessionStorage(),
       _notifications = notifications ?? NoopSessionNotificationService() {
    unawaited(_bootstrap());
  }

  static const List<SessionPreset> presets = [
    SessionPreset(focusMinutes: 25, breakMinutes: 5, label: '25/5'),
    SessionPreset(focusMinutes: 50, breakMinutes: 10, label: '50/10'),
    SessionPreset(focusMinutes: 1, breakMinutes: 1, label: 'custom'),
  ];
  static const String customPresetLabel = 'custom';
  static const int minCustomFocusMinutes = 1;
  static const int maxCustomFocusMinutes = 180;
  static const int minCustomBreakMinutes = 1;
  static const int maxCustomBreakMinutes = 60;
  static const int historyInsightWindowSize = 7;
  static const List<String> driftCategories = <String>[
    '알림',
    '딴생각',
    '메신저',
    '피로',
    '완벽주의',
    '환경',
  ];

  final List<SessionRecord> _records = [];
  SessionPreset _selectedPreset;
  SessionRunState _runState;
  Timer? _timer;
  final DateTime Function() _now;
  final SessionStorage _storage;
  final SessionNotificationService _notifications;
  bool _disposed = false;
  SessionPreset? _configuredCustomPreset;
  String _pendingSessionTitle = '';

  SessionPreset get selectedPreset => _selectedPreset;
  SessionRunState get runState => _runState;
  List<SessionRecord> get records => List.unmodifiable(_records);
  String get pendingSessionTitle => _pendingSessionTitle;
  bool get isCustomSelected => _isCustomPreset(_selectedPreset);
  bool get isCustomConfigured => _configuredCustomPreset != null;
  bool get canStartSession => !isCustomSelected || isCustomConfigured;
  String? get startGuardrailMessage {
    if (!canStartSession) {
      return 'Set custom minutes to start.';
    }
    return null;
  }

  int? get configuredCustomFocusMinutes =>
      _configuredCustomPreset?.focusMinutes;
  int? get configuredCustomBreakMinutes =>
      _configuredCustomPreset?.breakMinutes;

  int get currentFocusRemainingSeconds {
    if (_runState.phase == SessionPhase.focus &&
        _runState.phaseStartedAt != null) {
      return max(
        0,
        _computeRemaining(
          _runState.focusRemainingSeconds,
          _runState.phaseStartedAt!,
        ),
      );
    }
    return _runState.focusRemainingSeconds;
  }

  int get currentBreakRemainingSeconds {
    if (_runState.phase == SessionPhase.breakTime &&
        _runState.phaseStartedAt != null) {
      return max(
        0,
        _computeRemaining(
          _runState.breakRemainingSeconds,
          _runState.phaseStartedAt!,
        ),
      );
    }
    return _runState.breakRemainingSeconds;
  }

  int get actualFocusElapsedSeconds {
    final int planned = _runState.preset.focusSeconds;
    final int remaining = _runState.phase == SessionPhase.focus
        ? currentFocusRemainingSeconds
        : _runState.focusRemainingSeconds;
    return max(0, planned - remaining);
  }

  int get actualBreakElapsedSeconds {
    final int planned = _runState.preset.breakSeconds;
    final int remaining = _runState.phase == SessionPhase.breakTime
        ? currentBreakRemainingSeconds
        : _runState.breakRemainingSeconds;
    return max(0, planned - remaining);
  }

  String? get currentLastDriftCategory {
    return summarizeLastDriftCategory(_runState.driftEvents);
  }

  String get historyAverageFocusInsight {
    final List<SessionRecord> recent = _historyInsightRecords;
    if (recent.isEmpty) {
      return 'Average Focus (last $historyInsightWindowSize): 00:00';
    }

    final int focusSum = recent.fold<int>(
      0,
      (int total, SessionRecord item) => total + item.actualFocusSeconds,
    );
    final int averageFocus = focusSum ~/ recent.length;
    return 'Average Focus (last $historyInsightWindowSize): ${formatDurationMMSS(averageFocus)}';
  }

  String get historyTodayTotalFocusInsight {
    final DateTime now = _now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    final DateTime todayEnd = todayStart.add(const Duration(days: 1));

    int totalFocusSeconds = 0;
    for (final SessionRecord record in _records) {
      final DateTime recordTime = _recordTimestampForToday(record);
      if (!recordTime.isBefore(todayStart) && recordTime.isBefore(todayEnd)) {
        totalFocusSeconds += record.actualFocusSeconds;
      }
    }

    return 'Today Total Focus: ${formatDurationMMSS(totalFocusSeconds)}';
  }

  String get historyTodaySessionsCountInsight {
    final DateTime now = _now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    final DateTime todayEnd = todayStart.add(const Duration(days: 1));

    int todaySessions = 0;
    for (final SessionRecord record in _records) {
      final DateTime recordTime = _recordTimestampForToday(record);
      if (!recordTime.isBefore(todayStart) && recordTime.isBefore(todayEnd)) {
        todaySessions += 1;
      }
    }

    return 'Today Sessions: $todaySessions';
  }

  String get historyTopDriftInsight {
    final List<SessionRecord> recent = _historyInsightRecords;
    final Map<String, int> counts = <String, int>{};

    for (final SessionRecord record in recent) {
      for (final DriftEvent drift in record.drifts) {
        counts[drift.category] = (counts[drift.category] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) {
      return 'Top Drift (last $historyInsightWindowSize): none';
    }

    String? topCategory;
    int topCount = -1;
    for (final MapEntry<String, int> entry in counts.entries) {
      if (entry.value > topCount) {
        topCategory = entry.key;
        topCount = entry.value;
        continue;
      }

      if (entry.value == topCount &&
          topCategory != null &&
          entry.key.compareTo(topCategory) < 0) {
        topCategory = entry.key;
      }
    }

    return 'Top Drift (last $historyInsightWindowSize): ${topCategory!} ($topCount)';
  }

  static String formatDurationMMSS(int totalSeconds) {
    final int normalized = max(0, totalSeconds);
    final int minutes = normalized ~/ 60;
    final int seconds = normalized % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String formatClock(int totalSeconds) {
    return formatDurationMMSS(totalSeconds);
  }

  static String displayTitle(String? title) {
    final String normalized = title?.trim() ?? '';
    return normalized.isEmpty ? 'Untitled' : normalized;
  }

  static String? summarizeLastDriftCategory(List<DriftEvent> drifts) {
    if (drifts.isEmpty) {
      return null;
    }
    return drifts.last.category;
  }

  String presetDisplayLabel(SessionPreset preset) {
    if (!_isCustomPreset(preset)) {
      return preset.label;
    }
    if (_configuredCustomPreset == null) {
      return customPresetLabel;
    }
    return 'Custom (${_configuredCustomPreset!.focusMinutes}/${_configuredCustomPreset!.breakMinutes})';
  }

  void selectCustomPreset(int focusMinutes, int breakMinutes) {
    if (_runState.phase != SessionPhase.idle) {
      return;
    }
    final SessionPreset configured = SessionPreset(
      focusMinutes: focusMinutes.clamp(
        minCustomFocusMinutes,
        maxCustomFocusMinutes,
      ),
      breakMinutes: breakMinutes.clamp(
        minCustomBreakMinutes,
        maxCustomBreakMinutes,
      ),
      label: customPresetLabel,
    );
    _configuredCustomPreset = configured;
    _selectedPreset = configured;
    _runState = SessionRunState.idle(preset: configured);
    _queuePersistActiveRun();
    unawaited(_notifications.cancelAll());
    _safeNotifyListeners();
  }

  Future<void> _bootstrap() async {
    await _notifications.initialize();
    await _hydrateRecords();
    await _hydrateActiveRun();
  }

  Future<void> _hydrateRecords() async {
    final List<SessionRecord> loaded = await _storage.loadRecords();
    _records
      ..clear()
      ..addAll(loaded);
    _safeNotifyListeners();
  }

  Future<void> _hydrateActiveRun() async {
    final Map<String, dynamic>? raw = await _storage.loadActiveRun();
    if (raw == null) {
      return;
    }

    final SessionRunState? restored = _runStateFromJson(raw);
    if (restored == null) {
      await _storage.clearActiveRun();
      return;
    }

    _selectedPreset = restored.preset;
    _runState = restored;
    _synchronizePhaseAfterResume();
  }

  Future<void> _persistRecords() async {
    await _storage.saveRecords(_records);
  }

  Future<void> _persistActiveRun() async {
    if (_runState.phase == SessionPhase.idle) {
      await _storage.clearActiveRun();
      return;
    }
    await _storage.saveActiveRun(_runStateToJson(_runState));
  }

  void _queuePersistActiveRun() {
    unawaited(_persistActiveRun());
  }

  Map<String, dynamic> _runStateToJson(SessionRunState state) {
    return <String, dynamic>{
      'phase': state.phase.name,
      'preset': <String, dynamic>{
        'focusMinutes': state.preset.focusMinutes,
        'breakMinutes': state.preset.breakMinutes,
        'label': state.preset.label,
      },
      'sessionTitle': state.sessionTitle,
      'focusRemainingSeconds': state.focusRemainingSeconds,
      'breakRemainingSeconds': state.breakRemainingSeconds,
      'phaseStartedAt': state.phaseStartedAt?.toIso8601String(),
      'startedAt': state.startedAt?.toIso8601String(),
      'endedAt': state.endedAt?.toIso8601String(),
      'driftEvents': state.driftEvents
          .map((DriftEvent event) => event.toJson())
          .toList(growable: false),
    };
  }

  SessionRunState? _runStateFromJson(Map<String, dynamic> json) {
    try {
      final Map<dynamic, dynamic> presetJson =
          json['preset'] as Map<dynamic, dynamic>;
      final SessionPreset preset = SessionPreset(
        focusMinutes: (presetJson['focusMinutes'] as num).toInt(),
        breakMinutes: (presetJson['breakMinutes'] as num).toInt(),
        label: presetJson['label'] as String,
      );
      final String phaseName = json['phase'] as String;
      final SessionPhase phase = SessionPhase.values.firstWhere(
        (SessionPhase item) => item.name == phaseName,
      );
      final List<DriftEvent> drifts =
          ((json['driftEvents'] as List<dynamic>?) ?? <dynamic>[])
              .whereType<Map<dynamic, dynamic>>()
              .map((Map<dynamic, dynamic> entry) {
                return DriftEvent.fromJson(Map<String, dynamic>.from(entry));
              })
              .toList(growable: false);

      return SessionRunState(
        preset: preset,
        phase: phase,
        sessionTitle: json['sessionTitle'] as String?,
        driftEvents: drifts,
        focusRemainingSeconds: (json['focusRemainingSeconds'] as num).toInt(),
        breakRemainingSeconds: (json['breakRemainingSeconds'] as num).toInt(),
        phaseStartedAt: _parseDateTimeOrNull(json['phaseStartedAt']),
        startedAt: _parseDateTimeOrNull(json['startedAt']),
        endedAt: _parseDateTimeOrNull(json['endedAt']),
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDateTimeOrNull(dynamic raw) {
    final String? value = raw as String?;
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.parse(value);
  }

  void selectPreset(SessionPreset preset) {
    if (_runState.phase != SessionPhase.idle) {
      return;
    }
    if (_isCustomPreset(preset) && _configuredCustomPreset != null) {
      _selectedPreset = _configuredCustomPreset!;
    } else {
      _selectedPreset = preset;
    }
    _runState = SessionRunState.idle(preset: _selectedPreset);
    _queuePersistActiveRun();
    unawaited(_notifications.cancelAll());
    _safeNotifyListeners();
  }

  void updatePendingSessionTitle(String value) {
    _pendingSessionTitle = value;
  }

  void startSession({String? title}) {
    if (_runState.phase != SessionPhase.idle || !canStartSession) {
      return;
    }
    final DateTime now = _now();
    final String normalizedTitle = (title ?? _pendingSessionTitle).trim();
    _runState = SessionRunState(
      preset: _selectedPreset,
      phase: SessionPhase.focus,
      sessionTitle: normalizedTitle.isEmpty ? null : normalizedTitle,
      driftEvents: const <DriftEvent>[],
      focusRemainingSeconds: _selectedPreset.focusSeconds,
      breakRemainingSeconds: _selectedPreset.breakSeconds,
      phaseStartedAt: now,
      startedAt: now,
      endedAt: null,
    );
    _startTicker();
    _queuePersistActiveRun();
    _scheduleNotificationForCurrentPhase();
    _safeNotifyListeners();
  }

  void logDrift({required String category, String? note}) {
    if (_runState.phase != SessionPhase.focus) {
      return;
    }

    final String normalizedCategory = category.trim();
    if (normalizedCategory.isEmpty) {
      return;
    }

    final String? normalizedNote = (note ?? '').trim().isEmpty
        ? null
        : note!.trim();

    final List<DriftEvent> nextDrifts =
        List<DriftEvent>.from(_runState.driftEvents)..add(
          DriftEvent(
            atEpochMs: _now().millisecondsSinceEpoch,
            category: normalizedCategory,
            note: normalizedNote,
          ),
        );

    _runState = _runState.copyWith(driftEvents: nextDrifts);
    _queuePersistActiveRun();
    _safeNotifyListeners();
  }

  void handleAppBackgrounded() {
    _timer?.cancel();
  }

  void handleAppResumed() {
    _synchronizePhaseAfterResume();
  }

  void pauseForBreak() {
    if (_runState.phase != SessionPhase.focus) {
      return;
    }
    final DateTime now = _now();
    final int frozenFocus = max(
      0,
      _computeRemainingAt(
        _runState.focusRemainingSeconds,
        _runState.phaseStartedAt,
        now,
      ),
    );

    _runState = _runState.copyWith(
      phase: SessionPhase.breakTime,
      focusRemainingSeconds: frozenFocus,
      phaseStartedAt: now,
    );
    _startTicker();
    _queuePersistActiveRun();
    _scheduleNotificationForCurrentPhase();
    _safeNotifyListeners();
  }

  void resumeFocus() {
    if (_runState.phase != SessionPhase.breakTime) {
      return;
    }
    final DateTime now = _now();
    final int frozenBreak = max(
      0,
      _computeRemainingAt(
        _runState.breakRemainingSeconds,
        _runState.phaseStartedAt,
        now,
      ),
    );

    _runState = _runState.copyWith(
      phase: SessionPhase.focus,
      breakRemainingSeconds: frozenBreak,
      phaseStartedAt: now,
    );
    _startTicker();
    _queuePersistActiveRun();
    _scheduleNotificationForCurrentPhase();
    _safeNotifyListeners();
  }

  void saveAndReset() {
    if (_runState.phase != SessionPhase.ended) {
      return;
    }
    final DateTime now = _now();
    _records.add(
      SessionRecord(
        title: _runState.sessionTitle,
        startedAt: _runState.startedAt ?? now,
        endedAt: _runState.endedAt ?? now,
        presetLabel: presetDisplayLabel(_runState.preset),
        plannedFocus: _runState.preset.focusMinutes,
        plannedBreak: _runState.preset.breakMinutes,
        actualFocusSeconds: actualFocusElapsedSeconds,
        actualBreakSeconds: actualBreakElapsedSeconds,
        completed: true,
        drifts: List<DriftEvent>.from(_runState.driftEvents),
      ),
    );
    unawaited(_persistRecords());
    _timer?.cancel();
    _runState = SessionRunState.idle(preset: _selectedPreset);
    _queuePersistActiveRun();
    unawaited(_notifications.cancelAll());
    _safeNotifyListeners();
  }

  bool _isCustomPreset(SessionPreset preset) {
    return preset.label == customPresetLabel;
  }

  int _computeRemaining(int baseRemaining, DateTime startedAt) {
    return baseRemaining - _now().difference(startedAt).inSeconds;
  }

  void _synchronizePhaseAfterResume() {
    if (_runState.phase == SessionPhase.focus) {
      final int remaining = currentFocusRemainingSeconds;
      if (remaining <= 0) {
        _completeSession();
        return;
      }
      _runState = _runState.copyWith(
        focusRemainingSeconds: remaining,
        phaseStartedAt: _now(),
      );
      _ensureTickerRunning();
      _queuePersistActiveRun();
      _scheduleNotificationForCurrentPhase();
      _safeNotifyListeners();
      return;
    }

    if (_runState.phase == SessionPhase.breakTime) {
      final int remaining = currentBreakRemainingSeconds;
      if (remaining <= 0) {
        resumeFocus();
        return;
      }
      _runState = _runState.copyWith(
        breakRemainingSeconds: remaining,
        phaseStartedAt: _now(),
      );
      _ensureTickerRunning();
      _queuePersistActiveRun();
      _scheduleNotificationForCurrentPhase();
      _safeNotifyListeners();
      return;
    }

    if (_runState.phase == SessionPhase.ended) {
      _timer?.cancel();
      unawaited(_notifications.cancelAll());
      _queuePersistActiveRun();
      _safeNotifyListeners();
      return;
    }

    _timer?.cancel();
    _queuePersistActiveRun();
    unawaited(_notifications.cancelAll());
    _safeNotifyListeners();
  }

  List<SessionRecord> get _historyInsightRecords {
    return _records.reversed.take(historyInsightWindowSize).toList();
  }

  DateTime _recordTimestampForToday(SessionRecord record) {
    // SessionRecord currently always has startedAt; this is the primary
    // timestamp for day-boundary aggregation.
    return record.startedAt;
  }

  int _computeRemainingAt(
    int baseRemaining,
    DateTime? startedAt,
    DateTime now,
  ) {
    if (startedAt == null) {
      return baseRemaining;
    }
    return baseRemaining - now.difference(startedAt).inSeconds;
  }

  void _scheduleNotificationForCurrentPhase() {
    if (_runState.phase == SessionPhase.focus) {
      unawaited(
        _notifications.scheduleFocusToBreak(
          inSeconds: currentFocusRemainingSeconds,
        ),
      );
      return;
    }
    if (_runState.phase == SessionPhase.breakTime) {
      unawaited(
        _notifications.scheduleBreakToFocus(
          inSeconds: currentBreakRemainingSeconds,
        ),
      );
      return;
    }
    unawaited(_notifications.cancelAll());
  }

  void _startTicker() {
    _timer?.cancel();
    _ensureTickerRunning();
  }

  void _ensureTickerRunning() {
    if (_timer?.isActive ?? false) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_runState.phase == SessionPhase.focus) {
      if (currentFocusRemainingSeconds <= 0) {
        _completeSession();
        return;
      }
      _safeNotifyListeners();
      return;
    }

    if (_runState.phase == SessionPhase.breakTime) {
      if (currentBreakRemainingSeconds <= 0) {
        resumeFocus();
        return;
      }
      _safeNotifyListeners();
      return;
    }

    _timer?.cancel();
  }

  void _completeSession() {
    _timer?.cancel();
    _runState = _runState.copyWith(
      phase: SessionPhase.ended,
      focusRemainingSeconds: 0,
      clearPhaseStartedAt: true,
      endedAt: _now(),
    );
    _queuePersistActiveRun();
    unawaited(_notifications.cancelAll());
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_notifications.cancelAll());
    super.dispose();
  }
}
