import 'package:flutter_test/flutter_test.dart';
import 'package:jbaudio/models/quest.dart';

void main() {
  group('MusicQuest Models', () {
    test('MusicQuestDefinition should create from valid values', () {
      const def = MusicQuestDefinition(
        id: 'daily_30m',
        title: 'Daily Listener',
        description: 'Listen for 30 minutes today',
        category: QuestCategory.volume,
        periodType: QuestPeriodType.daily,
        criterion: QuestCriterion.listeningTime,
        targetValue: 1800,
      );

      expect(def.id, 'daily_30m');
      expect(def.category, QuestCategory.volume);
      expect(def.periodType, QuestPeriodType.daily);
      expect(def.criterion, QuestCriterion.listeningTime);
      expect(def.targetValue, 1800);
    });

    test('MusicQuestDefinition JSON serialization', () {
      const def = MusicQuestDefinition(
        id: 'weekly_5a',
        title: 'Artist Explorer',
        description: 'Listen to 5 different artists this week',
        category: QuestCategory.diversity,
        periodType: QuestPeriodType.weekly,
        criterion: QuestCriterion.distinctArtist,
        targetValue: 5,
      );

      final json = def.toJson();
      expect(json['id'], 'weekly_5a');
      expect(json['category'], 'diversity');

      final fromJson = MusicQuestDefinition.fromJson(json);
      expect(fromJson.id, def.id);
      expect(fromJson.criterion, def.criterion);
    });

    test('MusicQuestInstance should create and copyWith', () {
      final start = DateTime(2026, 9, 13);
      final end = DateTime(2026, 9, 14);
      
      final instance = MusicQuestInstance(
        definitionId: 'daily_30m',
        periodStart: start,
        periodEnd: end,
        status: QuestStatus.active,
      );

      expect(instance.definitionId, 'daily_30m');
      expect(instance.status, QuestStatus.active);
      expect(instance.completedAt, isNull);

      final completed = instance.copyWith(
        status: QuestStatus.completed,
        completedAt: DateTime.now(),
      );

      expect(completed.status, QuestStatus.completed);
      expect(completed.completedAt, isNotNull);
      expect(completed.definitionId, 'daily_30m');
    });

    test('MusicQuestInstance JSON serialization', () {
      final start = DateTime(2026, 9, 13);
      final end = DateTime(2026, 9, 14);
      final now = DateTime.now();

      final instance = MusicQuestInstance(
        id: 1,
        definitionId: 'daily_30m',
        periodStart: start,
        periodEnd: end,
        status: QuestStatus.completed,
        completedAt: now,
      );

      final json = instance.toJson();
      expect(json['id'], 1);
      expect(json['status'], 'completed');
      expect(json['periodStart'], start.toIso8601String());

      final fromJson = MusicQuestInstance.fromJson(json);
      expect(fromJson.id, 1);
      expect(fromJson.status, QuestStatus.completed);
      expect(fromJson.periodStart, start);
    });
  });
}
