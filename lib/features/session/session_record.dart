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
    );
  }
}
