enum QuestCategory {
  volume,
  discovery,
  diversity,
  temporal,
  discipline,
}

enum QuestPeriodType {
  daily,
  weekly,
  lifetime,
}

enum QuestCriterion {
  listeningTime,
  playCount,
  completionCount,
  distinctArtist,
  distinctAlbum,
  distinctGenre,
  discoveryCount,
  activeDayCount,
}

enum QuestStatus {
  active,
  completed,
  expired,
}

class MusicQuestDefinition {
  final String id;
  final String title;
  final String description;
  final QuestCategory category;
  final QuestPeriodType periodType;
  final QuestCriterion criterion;
  final double targetValue;

  const MusicQuestDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.periodType,
    required this.criterion,
    required this.targetValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'periodType': periodType.name,
      'criterion': criterion.name,
      'targetValue': targetValue,
    };
  }

  factory MusicQuestDefinition.fromJson(Map<String, dynamic> json) {
    return MusicQuestDefinition(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: QuestCategory.values.byName(json['category'] as String),
      periodType: QuestPeriodType.values.byName(json['periodType'] as String),
      criterion: QuestCriterion.values.byName(json['criterion'] as String),
      targetValue: (json['targetValue'] as num).toDouble(),
    );
  }
}

class MusicQuestInstance {
  final int? id; // SQLite auto-increment ID
  final String definitionId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final QuestStatus status;
  final DateTime? completedAt;

  const MusicQuestInstance({
    this.id,
    required this.definitionId,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    this.completedAt,
  });

  MusicQuestInstance copyWith({
    int? id,
    String? definitionId,
    DateTime? periodStart,
    DateTime? periodEnd,
    QuestStatus? status,
    DateTime? completedAt,
  }) {
    return MusicQuestInstance(
      id: id ?? this.id,
      definitionId: definitionId ?? this.definitionId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'definitionId': definitionId,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'status': status.name,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory MusicQuestInstance.fromJson(Map<String, dynamic> json) {
    return MusicQuestInstance(
      id: json['id'] as int?,
      definitionId: json['definitionId'] as String,
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      status: QuestStatus.values.byName(json['status'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}
