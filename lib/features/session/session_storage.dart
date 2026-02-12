import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'session_record.dart';

abstract class SessionStorage {
  Future<List<SessionRecord>> loadRecords();

  Future<void> saveRecords(List<SessionRecord> records);

  Future<Map<String, dynamic>?> loadActiveRun();

  Future<void> saveActiveRun(Map<String, dynamic> activeRun);

  Future<void> clearActiveRun();
}

class SharedPreferencesSessionStorage implements SessionStorage {
  static const String storageKey = 'resession_session_records_v1';
  static const String activeRunKey = 'resession_active_run_state_v1';

  @override
  Future<List<SessionRecord>> loadRecords() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(storageKey);

    if (raw == null || raw.isEmpty) {
      return <SessionRecord>[];
    }

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(SessionRecord.fromJson)
        .toList();
  }

  @override
  Future<void> saveRecords(List<SessionRecord> records) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      records.map((SessionRecord record) => record.toJson()).toList(),
    );
    await prefs.setString(storageKey, encoded);
  }

  @override
  Future<Map<String, dynamic>?> loadActiveRun() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(activeRunKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final Map<dynamic, dynamic> decoded =
        jsonDecode(raw) as Map<dynamic, dynamic>;
    return Map<String, dynamic>.from(decoded);
  }

  @override
  Future<void> saveActiveRun(Map<String, dynamic> activeRun) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(activeRunKey, jsonEncode(activeRun));
  }

  @override
  Future<void> clearActiveRun() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(activeRunKey);
  }
}

class InMemorySessionStorage implements SessionStorage {
  List<SessionRecord> _records;
  Map<String, dynamic>? _activeRun;

  InMemorySessionStorage([List<SessionRecord>? initialRecords])
    : _records = List<SessionRecord>.from(initialRecords ?? <SessionRecord>[]);

  @override
  Future<List<SessionRecord>> loadRecords() async {
    return List<SessionRecord>.from(_records);
  }

  @override
  Future<void> saveRecords(List<SessionRecord> records) async {
    _records = List<SessionRecord>.from(records);
  }

  @override
  Future<Map<String, dynamic>?> loadActiveRun() async {
    if (_activeRun == null) {
      return null;
    }
    return Map<String, dynamic>.from(_activeRun!);
  }

  @override
  Future<void> saveActiveRun(Map<String, dynamic> activeRun) async {
    _activeRun = Map<String, dynamic>.from(activeRun);
  }

  @override
  Future<void> clearActiveRun() async {
    _activeRun = null;
  }
}
