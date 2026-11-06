import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/formatters.dart';
import 'models.dart';

class AppStore extends ChangeNotifier {
  AppStore._(this._prefs, this._sessions, this._settings);

  final SharedPreferences _prefs;
  List<TallySession> _sessions;
  AppSettings _settings;

  static const _sessionsKey = 'taka_counter.sessions.v1';
  static const _themeKey = 'taka_counter.settings.theme';
  static const _hapticsKey = 'taka_counter.settings.haptics';
  static const _confirmKey = 'taka_counter.settings.confirm';

  static Future<AppStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = <TallySession>[];

    final rawSessions = prefs.getString(_sessionsKey);
    if (rawSessions != null && rawSessions.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSessions);
        if (decoded is List) {
          for (final raw in decoded) {
            if (raw is Map) {
              sessions.add(
                TallySession.fromJson(Map<String, dynamic>.from(raw)),
              );
            }
          }
        }
      } catch (_) {
        // A damaged local record should never block the app from opening.
      }
    }

    if (sessions.isEmpty) {
      sessions.add(_freshSession());
    }

    final settings = AppSettings(
      themeMode: _themeFromStorage(prefs.getString(_themeKey)),
      haptics: prefs.getBool(_hapticsKey) ?? true,
      confirmDeletes: prefs.getBool(_confirmKey) ?? true,
    );

    final store = AppStore._(prefs, sessions, settings);
    if (rawSessions == null) {
      await store._persistSessions();
    }
    return store;
  }

  // ---------------------------------------------------------------------------
  // Public state
  // ---------------------------------------------------------------------------

  List<TallySession> get sessions => List.unmodifiable(_sessions);

  AppSettings get settings => _settings;

  TallySession get activeSession => _sessions.first;

  List<TallySession> get historySessions =>
      _sessions.where((session) => session.entries.isNotEmpty).toList();

  List<TallySession> get recentSessions =>
      historySessions.take(3).toList(growable: false);

  int get lifetimeTotal =>
      _sessions.fold(0, (sum, session) => sum + session.total);

  int get totalSessions => _sessions.length;

  int get totalEntries =>
      _sessions.fold(0, (sum, session) => sum + session.entryCount);

  bool get hasHistory => historySessions.isNotEmpty;

  int get activeEntryCount => activeSession.entryCount;

  // ---------------------------------------------------------------------------
  // Counting
  // ---------------------------------------------------------------------------

  TallyEntry? findEntry(String entryId) {
    for (final session in _sessions) {
      for (final entry in session.entries) {
        if (entry.id == entryId) return entry;
      }
    }
    return null;
  }

  void addEntry(TallyEntry entry, {String? sessionId}) {
    final index = _indexOf(sessionId ?? activeSession.id);
    final session = _sessions[index];
    final entries = [entry, ...session.entries];
    _sessions[index] = session.copyWith(
      entries: entries,
      updatedAt: DateTime.now(),
    );
    _changed();
  }

  void updateEntry(String sessionId, TallyEntry entry) {
    final index = _indexOf(sessionId);
    final session = _sessions[index];
    final entries = session.entries
        .map((current) => current.id == entry.id ? entry : current)
        .toList();
    _sessions[index] = session.copyWith(
      entries: entries,
      updatedAt: DateTime.now(),
    );
    _changed();
  }

  void deleteEntry(String sessionId, String entryId) {
    final index = _indexOf(sessionId);
    final session = _sessions[index];
    _sessions[index] = session.copyWith(
      entries: session.entries.where((entry) => entry.id != entryId).toList(),
      updatedAt: DateTime.now(),
    );
    _changed();
  }

  void clearEntries({bool includeActive = true}) {
    if (includeActive) {
      final active = activeSession;
      _sessions[0] = active.copyWith(
        entries: const [],
        updatedAt: DateTime.now(),
      );
      for (var i = 1; i < _sessions.length; i++) {
        final session = _sessions[i];
        _sessions[i] = session.copyWith(entries: const []);
      }
      _cleanupEmptySessions();
      _changed();
      return;
    }

    for (var i = 1; i < _sessions.length; i++) {
      final session = _sessions[i];
      _sessions[i] = session.copyWith(entries: const []);
    }
    _cleanupEmptySessions();
    _changed();
  }

  void startNewSession({String? title}) {
    final current = activeSession;
    if (current.isEmpty) {
      _sessions[0] = current.copyWith(
        title: title?.trim().isNotEmpty == true
            ? title!.trim()
            : 'Cash count · ${formatDateShort(DateTime.now())}',
        updatedAt: DateTime.now(),
      );
      _changed();
      return;
    }

    final now = DateTime.now();
    _sessions.insert(
      0,
      TallySession(
        id: _newId(),
        title: title?.trim().isNotEmpty == true
            ? title!.trim()
            : 'Cash count · ${formatDateShort(now)}',
        createdAt: now,
        updatedAt: now,
        entries: const [],
      ),
    );
    _changed();
  }

  void renameActiveSession(String title) {
    final clean = title.trim();
    if (clean.isEmpty) return;
    _sessions[0] = _sessions[0].copyWith(
      title: clean,
      updatedAt: DateTime.now(),
    );
    _changed();
  }

  void deleteSession(String sessionId) {
    _sessions.removeWhere((session) => session.id == sessionId);
    if (_sessions.isEmpty) {
      _sessions.add(_freshSession());
    }
    _changed();
  }

  /// Restores imported counts. [replace] swaps the whole ledger (backup
  /// restore); otherwise the imported counts are kept as saved counts while the
  /// count you are working on stays untouched.
  void importSessions(List<TallySession> imported, {required bool replace}) {
    if (imported.isEmpty) return;

    if (replace) {
      // A restore brings back saved counts only. Keep a fresh, empty count at
      // the top so new entries never land inside a restored history item.
      final seenSessions = <String>{};
      final restored = <TallySession>[];
      for (final session in imported) {
        var copy = session;
        if (!seenSessions.add(copy.id)) {
          copy = copy.copyWith(id: _newId());
          seenSessions.add(copy.id);
        }
        restored.add(copy);
      }
      _sessions = restored;
      if (_sessions.first.entries.isNotEmpty) {
        _sessions.insert(0, _freshSession());
      }
    } else {
      // Merging twice must not create duplicate ids: findEntry() and edit
      // actions would otherwise update the wrong copy.
      final sessionIds = _sessions.map((session) => session.id).toSet();
      final entryIds = _sessions
          .expand((session) => session.entries)
          .map((entry) => entry.id)
          .toSet();
      final additions = <TallySession>[];
      for (final session in imported) {
        var copy = session;
        if (!sessionIds.add(copy.id)) {
          copy = copy.copyWith(id: _newId());
          sessionIds.add(copy.id);
        }
        final entries = <TallyEntry>[];
        for (final entry in copy.entries) {
          var nextEntry = entry;
          if (!entryIds.add(nextEntry.id)) {
            nextEntry = nextEntry.copyWith(id: _newId());
            entryIds.add(nextEntry.id);
          }
          entries.add(nextEntry);
        }
        additions.add(copy.copyWith(entries: entries));
      }
      _sessions.insertAll(1, additions);
    }
    _changed();
  }

  void clearHistory() {
    final active = activeSession;
    if (_sessions.length == 1) return;
    _sessions = [active];
    _changed();
  }

  String get activeId => activeSession.id;

  String createId() => _newId();

  int _indexOf(String sessionId) {
    final index = _sessions.indexWhere((session) => session.id == sessionId);
    return index < 0 ? 0 : index;
  }

  void _cleanupEmptySessions() {
    final active = _sessions.first;
    final rest = _sessions
        .skip(1)
        .where((session) => !session.isEmpty)
        .toList();
    _sessions = [active, ...rest];
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  void setThemeMode(ThemeMode mode) {
    if (_settings.themeMode == mode) return;
    _settings = _settings.copyWith(themeMode: mode);
    _prefs.setString(_themeKey, mode.name);
    notifyListeners();
  }

  void setHaptics(bool enabled) {
    _settings = _settings.copyWith(haptics: enabled);
    _prefs.setBool(_hapticsKey, enabled);
    notifyListeners();
  }

  void setConfirmDeletes(bool enabled) {
    _settings = _settings.copyWith(confirmDeletes: enabled);
    _prefs.setBool(_confirmKey, enabled);
    notifyListeners();
  }

  void tapHaptic() {
    if (_settings.haptics) HapticFeedback.lightImpact();
  }

  void mediumHaptic() {
    if (_settings.haptics) HapticFeedback.mediumImpact();
  }

  void successHaptic() {
    if (_settings.haptics) HapticFeedback.selectionClick();
  }

  // ---------------------------------------------------------------------------
  // Demo / development helper
  // ---------------------------------------------------------------------------

  /// Seeds a polished sample count. Used by the web preview (`?demo=1`) and
  /// available from the empty state, never inserted silently on a fresh install.
  void seedDemo() {
    if (_sessions.any((session) => session.entries.isNotEmpty)) return;
    final now = DateTime.now();
    final active = TallySession(
      id: _newId(),
      title: 'Thursday cash count',
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now.subtract(const Duration(minutes: 18)),
      entries: [
        _demoEntry(
          EntryKind.credit,
          5000,
          1,
          'Added from wallet',
          now.subtract(const Duration(hours: 1, minutes: 35)),
        ),
        _demoEntry(
          EntryKind.debit,
          2500,
          1,
          'Tea & snacks',
          now.subtract(const Duration(hours: 1, minutes: 12)),
        ),
        _demoEntry(
          EntryKind.counted,
          1000,
          150,
          '',
          now.subtract(const Duration(minutes: 54)),
        ),
        _demoEntry(
          EntryKind.counted,
          500,
          25,
          '',
          now.subtract(const Duration(minutes: 50)),
        ),
        _demoEntry(
          EntryKind.counted,
          200,
          50,
          '',
          now.subtract(const Duration(minutes: 44)),
        ),
        _demoEntry(
          EntryKind.counted,
          100,
          160,
          '',
          now.subtract(const Duration(minutes: 38)),
        ),
        _demoEntry(
          EntryKind.counted,
          50,
          26,
          '',
          now.subtract(const Duration(minutes: 31)),
        ),
        _demoEntry(
          EntryKind.counted,
          20,
          24,
          '',
          now.subtract(const Duration(minutes: 26)),
        ),
        _demoEntry(
          EntryKind.counted,
          10,
          9,
          '',
          now.subtract(const Duration(minutes: 21)),
        ),
        _demoEntry(
          EntryKind.counted,
          5,
          43,
          '',
          now.subtract(const Duration(minutes: 18)),
        ),
        _demoEntry(
          EntryKind.counted,
          1,
          45,
          '',
          now.subtract(const Duration(minutes: 18)),
        ),
      ],
    );

    final yesterday = TallySession(
      id: _newId(),
      title: 'Shop collection',
      createdAt: now.subtract(const Duration(days: 1, hours: 4)),
      updatedAt: now.subtract(const Duration(days: 1, hours: 2)),
      entries: [
        _demoEntry(
          EntryKind.counted,
          500,
          36,
          '',
          now.subtract(const Duration(days: 1, hours: 3)),
        ),
        _demoEntry(
          EntryKind.counted,
          100,
          56,
          '',
          now.subtract(const Duration(days: 1, hours: 2)),
        ),
        _demoEntry(
          EntryKind.debit,
          1000,
          1,
          'Transport',
          now.subtract(const Duration(days: 1, hours: 2)),
        ),
      ],
    );

    final lastWeek = TallySession(
      id: _newId(),
      title: 'Family fund',
      createdAt: now.subtract(const Duration(days: 9, hours: 5)),
      updatedAt: now.subtract(const Duration(days: 9)),
      entries: [
        _demoEntry(
          EntryKind.counted,
          1000,
          8,
          '',
          now.subtract(const Duration(days: 9, hours: 4)),
        ),
        _demoEntry(
          EntryKind.credit,
          7500,
          1,
          'Monthly savings',
          now.subtract(const Duration(days: 9, hours: 3)),
        ),
      ],
    );

    _sessions = [active, yesterday, lastWeek];
    _changed();
  }

  static TallyEntry _demoEntry(
    EntryKind kind,
    int amount,
    int quantity,
    String note,
    DateTime at,
  ) {
    return TallyEntry(
      id: _newId(),
      kind: kind,
      amount: amount,
      quantity: quantity,
      note: note,
      createdAt: at,
    );
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  void _changed() {
    notifyListeners();
    _persistSessions();
  }

  Future<void> _persistSessions() async {
    try {
      await _prefs.setString(
        _sessionsKey,
        jsonEncode(_sessions.map((session) => session.toJson()).toList()),
      );
    } catch (_) {
      // Keep the in-memory ledger usable if the device cannot write right now.
    }
  }

  static TallySession _freshSession() {
    final now = DateTime.now();
    return TallySession(
      id: _newId(),
      title: 'Cash count · ${formatDateShort(now)}',
      createdAt: now,
      updatedAt: now,
      entries: const [],
    );
  }

  static ThemeMode _themeFromStorage(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static int _idCounter = 0;

  static String _newId() {
    _idCounter++;
    return '${DateTime.now().microsecondsSinceEpoch}-$_idCounter';
  }
}
