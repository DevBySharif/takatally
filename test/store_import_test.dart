import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taka_counter/data/models.dart';
import 'package:taka_counter/data/store.dart';

TallySession _session(String id, {int amount = 500}) {
  final now = DateTime(2026, 11, 5, 12);
  return TallySession(
    id: id,
    title: 'Restored $id',
    createdAt: now,
    updatedAt: now,
    entries: [
      TallyEntry(
        id: 'entry-$id',
        kind: EntryKind.counted,
        amount: amount,
        quantity: 2,
        note: '',
        createdAt: now,
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restoring a backup keeps a fresh count on top', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    store.addEntry(
      TallyEntry(
        id: 'current-entry',
        kind: EntryKind.counted,
        amount: 100,
        quantity: 1,
        note: '',
        createdAt: DateTime(2026, 11, 5),
      ),
    );

    store.importSessions([_session('a'), _session('b')], replace: true);

    expect(store.activeSession.entries, isEmpty);
    expect(store.historySessions.map((session) => session.id), ['a', 'b']);
    expect(store.totalSessions, 3);
  });

  test('merging the same backup twice never duplicates ids', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();

    store.importSessions([_session('a')], replace: false);
    store.importSessions([_session('a')], replace: false);

    final ids = store.sessions.map((session) => session.id).toList();
    final entryIds = store.sessions
        .expand((session) => session.entries)
        .map((entry) => entry.id)
        .toList();

    expect(ids.toSet(), hasLength(ids.length));
    expect(entryIds.toSet(), hasLength(entryIds.length));
    expect(store.historySessions, hasLength(2));
  });

  test('a restored backup survives a reload', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await AppStore.load();
    store.importSessions([_session('a', amount: 1200)], replace: true);

    final reloaded = await AppStore.load();

    expect(reloaded.historySessions.single.entries.single.amount, 1200);
  });
}
