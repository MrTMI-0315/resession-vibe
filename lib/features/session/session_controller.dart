import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

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
      focusRemainingSeconds: preset.focusSeconds,
      breakRemainingSeconds: preset.breakSeconds,
      phaseStartedAt: null,
      startedAt: null,
      endedAt: null,
    );
  }

  final SessionPreset preset;
  final SessionPhase phase;
  final int focusRemainingSeconds;
  final int breakRemainingSeconds;
  final DateTime? phaseStartedAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  SessionRunState copyWith({
    SessionPreset? preset,
    SessionPhase? phase,
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

class SessionRecord {
  const SessionRecord({
    required this.startedAt,
    required this.endedAt,
    required this.presetLabel,
    required this.plannedFocus,
    required this.plannedBreak,
    required this.completed,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final String presetLabel;
  final int plannedFocus;
  final int plannedBreak;
  final bool completed;
}

class SessionController extends ChangeNotifier {
  SessionController({DateTime Function()? nowProvider})
    : _selectedPreset = presets.first,
      _runState = SessionRunState.idle(preset: presets.first),
      _now = nowProvider ?? DateTime.now;

  static const List<SessionPreset> presets = [
    SessionPreset(focusMinutes: 25, breakMinutes: 5, label: '25/5'),
    SessionPreset(focusMinutes: 50, breakMinutes: 10, label: '50/10'),
    SessionPreset(focusMinutes: 1, breakMinutes: 1, label: 'custom'),
  ];

  final List<SessionRecord> _records = [];
  SessionPreset _selectedPreset;
  SessionRunState _runState;
  Timer? _timer;
  final DateTime Function() _now;

  SessionPreset get selectedPreset => _selectedPreset;
  SessionRunState get runState => _runState;
  List<SessionRecord> get records => List.unmodifiable(_records);

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

  static String formatClock(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void selectPreset(SessionPreset preset) {
    if (_runState.phase != SessionPhase.idle) {
      return;
    }
    _selectedPreset = preset;
    _runState = SessionRunState.idle(preset: preset);
    notifyListeners();
  }

  void startSession() {
    if (_runState.phase != SessionPhase.idle) {
      return;
    }
    final DateTime now = _now();
    _runState = SessionRunState(
      preset: _selectedPreset,
      phase: SessionPhase.focus,
      focusRemainingSeconds: _selectedPreset.focusSeconds,
      breakRemainingSeconds: _selectedPreset.breakSeconds,
      phaseStartedAt: now,
      startedAt: now,
      endedAt: null,
    );
    _startTicker();
    notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
  }

  void saveAndReset() {
    if (_runState.phase != SessionPhase.ended) {
      return;
    }
    final DateTime now = _now();
    _records.add(
      SessionRecord(
        startedAt: _runState.startedAt ?? now,
        endedAt: _runState.endedAt ?? now,
        presetLabel: _runState.preset.label,
        plannedFocus: _runState.preset.focusMinutes,
        plannedBreak: _runState.preset.breakMinutes,
        completed: true,
      ),
    );
    _timer?.cancel();
    _runState = SessionRunState.idle(preset: _selectedPreset);
    notifyListeners();
  }

  int _computeRemaining(int baseRemaining, DateTime startedAt) {
    return baseRemaining - _now().difference(startedAt).inSeconds;
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

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_runState.phase == SessionPhase.focus) {
      if (currentFocusRemainingSeconds <= 0) {
        _completeSession();
        return;
      }
      notifyListeners();
      return;
    }

    if (_runState.phase == SessionPhase.breakTime) {
      if (currentBreakRemainingSeconds <= 0) {
        _runState = _runState.copyWith(
          breakRemainingSeconds: 0,
          phaseStartedAt: _now(),
        );
        _timer?.cancel();
        notifyListeners();
        return;
      }
      notifyListeners();
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
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
