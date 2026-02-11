class DriftEvent {
  const DriftEvent({
    required this.atEpochMs,
    required this.category,
    this.note,
  });

  final int atEpochMs;
  final String category;
  final String? note;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'atEpochMs': atEpochMs,
      'category': category,
      'note': note,
    };
  }

  factory DriftEvent.fromJson(Map<String, dynamic> json) {
    return DriftEvent(
      atEpochMs: (json['atEpochMs'] as num).toInt(),
      category: json['category'] as String,
      note: json['note'] as String?,
    );
  }
}

class SessionRecord {
  const SessionRecord({
    required this.title,
    required this.startedAt,
    required this.endedAt,
    required this.presetLabel,
    required this.plannedFocus,
    required this.plannedBreak,
    required this.actualFocusSeconds,
    required this.actualBreakSeconds,
    required this.completed,
    this.drifts = const <DriftEvent>[],
  });

  final String? title;
  final DateTime startedAt;
  final DateTime endedAt;
  final String presetLabel;
  final int plannedFocus;
  final int plannedBreak;
  final int actualFocusSeconds;
  final int actualBreakSeconds;
  final bool completed;
  final List<DriftEvent> drifts;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'presetLabel': presetLabel,
      'plannedFocus': plannedFocus,
      'plannedBreak': plannedBreak,
      'actualFocusSeconds': actualFocusSeconds,
      'actualBreakSeconds': actualBreakSeconds,
      'completed': completed,
      'drifts': drifts
          .map((DriftEvent drift) => drift.toJson())
          .toList(growable: false),
    };
  }

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      title: json['title'] as String?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      presetLabel: json['presetLabel'] as String,
      plannedFocus: json['plannedFocus'] as int,
      plannedBreak: json['plannedBreak'] as int,
      actualFocusSeconds:
          (json['actualFocusSeconds'] as int?) ??
          (json['plannedFocus'] as int) * 60,
      actualBreakSeconds:
          (json['actualBreakSeconds'] as int?) ??
          (json['plannedBreak'] as int) * 60,
      completed: json['completed'] as bool,
      drifts: ((json['drifts'] as List<dynamic>?) ?? <dynamic>[])
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> entry) {
            return DriftEvent.fromJson(Map<String, dynamic>.from(entry));
          })
          .toList(growable: false),
    );
  }
}
