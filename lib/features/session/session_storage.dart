import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'session_record.dart';

abstract class SessionStorage {
  Future<List<SessionRecord>> loadRecords();

  Future<void> saveRecords(List<SessionRecord> records);
}

class SharedPreferencesSessionStorage implements SessionStorage {
  static const String storageKey = 'resession_session_records_v1';

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
}

class InMemorySessionStorage implements SessionStorage {
  List<SessionRecord> _records;

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
}
