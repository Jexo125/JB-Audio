import 'package:flutter_test/flutter_test.dart';
import 'package:jbaudio/models/quest.dart';
import 'package:jbaudio/services/library_database_service.dart';
import 'package:sqflite/sqflite.dart';

class FakeDatabase extends Fake implements Database {
  final List<Map<String, dynamic>> inserts = [];
  final List<Map<String, dynamic>> updates = [];
  final List<Map<String, dynamic>> deletes = [];
  final List<Map<String, dynamic>> queries = [];

  @override
  Future<int> insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    inserts.add({'table': table, 'values': values});
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
    queries.add({'table': table, 'where': where, 'whereArgs': whereArgs});
    return [];
  }

  @override
  Future<int> update(String table, Map<String, Object?> values,
      {String? where,
      List<Object?>? whereArgs,
      ConflictAlgorithm? conflictAlgorithm}) async {
    updates.add({
      'table': table,
      'values': values,
      'where': where,
      'whereArgs': whereArgs
    });
    return 1;
  }

  @override
  Future<int> delete(String table,
      {String? where, List<Object?>? whereArgs}) async {
    deletes.add({'table': table, 'where': where, 'whereArgs': whereArgs});
    return 1;
  }

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    // No-op
  }
}

class TestLibraryDatabaseService extends LibraryDatabaseService {
  final Database _mockDb;
  TestLibraryDatabaseService(this._mockDb);

  @override
  Future<Database> get database async => _mockDb;
}

void main() {
  group('LibraryDatabaseService Quest Tests', () {
    late FakeDatabase fakeDb;
    late TestLibraryDatabaseService service;

    setUp(() {
      fakeDb = FakeDatabase();
      service = TestLibraryDatabaseService(fakeDb);
    });

    test('insertQuestInstance should call db.insert with correct values',
        () async {
      final start = DateTime(2026, 9, 13);
      final end = DateTime(2026, 9, 14);
      final instance = MusicQuestInstance(
        definitionId: 'test_def',
        periodStart: start,
        periodEnd: end,
        status: QuestStatus.active,
      );

      await service.insertQuestInstance(instance);

      expect(fakeDb.inserts.length, 1);
      final call = fakeDb.inserts.first;
      expect(call['table'], 'quest_instances');
      expect(call['values']['definition_id'], 'test_def');
      expect(call['values']['status'], 'active');
    });

    test('getActiveQuestInstances should query with status filter', () async {
      await service.getActiveQuestInstances();

      expect(fakeDb.queries.length, 1);
      final call = fakeDb.queries.first;
      expect(call['table'], 'quest_instances');
      expect(call['where'], 'status = ?');
      expect(call['whereArgs'], ['active']);
    });

    test('updateQuestInstanceStatus should call db.update', () async {
      final now = DateTime.now();
      await service.updateQuestInstanceStatus(123, QuestStatus.completed,
          completedAt: now);

      expect(fakeDb.updates.length, 1);
      final call = fakeDb.updates.first;
      expect(call['table'], 'quest_instances');
      expect(call['values']['status'], 'completed');
      expect(call['values']['completed_at'], now.toIso8601String());
      expect(call['where'], 'id = ?');
      expect(call['whereArgs'], [123]);
    });

    test('deleteQuestInstance should call db.delete', () async {
      await service.deleteQuestInstance(456);

      expect(fakeDb.deletes.length, 1);
      final call = fakeDb.deletes.first;
      expect(call['table'], 'quest_instances');
      expect(call['where'], 'id = ?');
      expect(call['whereArgs'], [456]);
    });
  });
}
