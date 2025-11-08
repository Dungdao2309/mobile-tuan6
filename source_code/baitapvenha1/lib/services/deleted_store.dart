// lib/services/deleted_store.dart
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class DeletedStore {
  static const _key = 'deleted_task_ids_v1';

  static final Set<int> _inMemory = <int>{};
  static bool _inited = false;

  static Future<void> _ensureInit() async {
    if (_inited) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key) ?? <String>[];
      _inMemory.clear();
      for (final s in list) {
        final v = int.tryParse(s);
        if (v != null) _inMemory.add(v);
      }
      _inited = true;
      print('[DeletedStore] Initialized from prefs: $_inMemory');
    } catch (e) {
      _inited = true;
      print('[DeletedStore] SharedPreferences init failed: $e (using in-memory only)');
    }
  }

  static Future<Set<int>> getDeletedIds() async {
    await _ensureInit();
    return Set<int>.from(_inMemory);
  }

  static Future<bool> _persistSet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _inMemory.map((e) => e.toString()).toList();
      final ok = await prefs.setStringList(_key, list);
      print('[DeletedStore] Persist set result: $ok -> $_inMemory');
      return ok;
    } catch (e) {
      print('[DeletedStore] Persist failed: $e');
      return false;
    }
  }

  static Future<void> addDeletedId(int id) async {
    await _ensureInit();
    _inMemory.add(id);
    final ok = await _persistSet();
    if (!ok) {
      print('[DeletedStore] addDeletedId: persist failed, but kept in-memory: $id');
    }
  }

  static Future<void> removeDeletedId(int id) async {
    await _ensureInit();
    _inMemory.remove(id);
    final ok = await _persistSet();
    if (!ok) {
      print('[DeletedStore] removeDeletedId: persist failed, but in-memory removed: $id');
    }
  }

  static Future<void> reset() async {
    _inMemory.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      print('[DeletedStore] reset: prefs cleared');
    } catch (e) {
      print('[DeletedStore] reset: failed to clear prefs: $e (in-memory cleared)');
    }
  }
}
