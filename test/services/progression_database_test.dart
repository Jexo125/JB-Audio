import 'package:flutter_test/flutter_test.dart';
import 'package:jbaudio/models/models.dart';
import 'package:jbaudio/services/library_database_service.dart';
import 'package:sqflite/sqflite.dart';

class FakeDatabase extends Fake implements Database {
  final Map<String, List<Map<String, dynamic>>> tables = {
    'user_progression': [],
    'xp_transactions': [],
    'unlocked_titles': [],
  };

  FakeDatabase() {
    // Initial state
    tables['user_progression']!.add({'id': 1, 'total_xp': 0, 'pending_seconds': 0});
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    final rows = tables[table]!;
    
    if (table == 'xp_transactions') {
      final type = values['source_type'];
      final id = values['source_id'];
      final exists = rows.any((r) => r['source_type'] == type && r['source_id'] == id);
      if (exists) {
        if (conflictAlgorithm == ConflictAlgorithm.ignore) {
          return 0;
        }
        return -1;
      }
    }

    if (table == 'user_progression') {
      if (conflictAlgorithm == ConflictAlgorithm.replace || conflictAlgorithm == ConflictAlgorithm.ignore) {
        rows.removeWhere((r) => r['id'] == values['id']);
      }
    }

    rows.add(Map<String, dynamic>.from(values));
    return 1;
  }

  @override
  Future<List<Map<String, Object?>>> query(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) async {
    var rows = tables[table]!;
    if (where == 'id = 1') {
      return rows.where((r) => r['id'] == 1).toList();
    }
    return rows;
  }

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {}
}

class TestLibraryDatabaseService extends LibraryDatabaseService {
  final Database _mockDb;
  TestLibraryDatabaseService(this._mockDb);

  @override
  Future<Database> get database async => _mockDb;
}

void main() {
  group('LibraryDatabaseService V5 Progression Logic', () {
    late FakeDatabase fakeDb;
    late TestLibraryDatabaseService service;

    setUp(() {
      fakeDb = FakeDatabase();
      service = TestLibraryDatabaseService(fakeDb);
    });

    test('Initial progression should be 0/0', () async {
      final progression = await service.getUserProgression();
      expect(progression.totalXp, 0);
      expect(progression.pendingSeconds, 0);
    });

    test('updateUserProgression should persist values', () async {
      const p = UserProgression(totalXp: 100, pendingSeconds: 30);
      await service.updateUserProgression(p);
      
      final updated = await service.getUserProgression();
      expect(updated.totalXp, 100);
      expect(updated.pendingSeconds, 30);
    });

    test('insertXpTransaction should be idempotent', () async {
      final now = DateTime.now().toIso8601String();
      
      // First insertion
      final first = await service.insertXpTransaction(
        sourceType: 'val',
        sourceId: 'val_song1_12345',
        amount: 2,
        timestamp: now,
      );
      expect(first, true);

      // Second identical insertion
      final second = await service.insertXpTransaction(
        sourceType: 'val',
        sourceId: 'val_song1_12345',
        amount: 2,
        timestamp: now,
      );
      expect(second, false); // Should be ignored by logic or conflict algorithm

      // Same song, different timestamp
      final third = await service.insertXpTransaction(
        sourceType: 'val',
        sourceId: 'val_song1_12346',
        amount: 2,
        timestamp: now,
      );
      expect(third, true);
    });

    test('insertUnlockedTitle should persist titles', () async {
      final now = DateTime.now().toIso8601String();
      await service.insertUnlockedTitle('explorer', now);
      
      final titles = await service.getUnlockedTitles();
      expect(titles.length, 1);
      expect(titles.first['title_key'], 'explorer');
      expect(titles.first['unlocked_at'], now);
    });
  });
}
