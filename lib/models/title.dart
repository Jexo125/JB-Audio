class TitleDefinition {
  final String id;
  final String nameKey;
  final String descKey;
  final double threshold;
  final TitleType type;

  const TitleDefinition({
    required this.id,
    required this.nameKey,
    required this.descKey,
    required this.threshold,
    required this.type,
  });

  static const List<TitleDefinition> v1Titles = [
    TitleDefinition(
      id: 'title_melomane',
      nameKey: 'titleMelomane',
      descKey: 'titleMelomaneDesc',
      threshold: 36000, // 10 hours in seconds
      type: TitleType.listenTime,
    ),
    TitleDefinition(
      id: 'title_explorer',
      nameKey: 'titleExplorer',
      descKey: 'titleExplorerDesc',
      threshold: 20,
      type: TitleType.artistCount,
    ),
    TitleDefinition(
      id: 'title_collector',
      nameKey: 'titleCollector',
      descKey: 'titleCollectorDesc',
      threshold: 10,
      type: TitleType.albumCount,
    ),
    TitleDefinition(
      id: 'title_finisher',
      nameKey: 'titleFinisher',
      descKey: 'titleFinisherDesc',
      threshold: 50,
      type: TitleType.completionCount,
    ),
    TitleDefinition(
      id: 'title_pioneer',
      nameKey: 'titlePioneer',
      descKey: 'titlePioneerDesc',
      threshold: 20,
      type: TitleType.discoveryCount,
    ),
    TitleDefinition(
      id: 'title_regular',
      nameKey: 'titleRegular',
      descKey: 'titleRegularDesc',
      threshold: 10,
      type: TitleType.activeDays,
    ),
  ];
}

enum TitleType {
  listenTime,
  artistCount,
  albumCount,
  completionCount,
  discoveryCount,
  activeDays,
}

class UnlockedTitle {
  final String id;
  final DateTime unlockedAt;

  UnlockedTitle({
    required this.id,
    required this.unlockedAt,
  });
}

class TitleSnapshot {
  final TitleDefinition definition;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  TitleSnapshot({
    required this.definition,
    required this.isUnlocked,
    this.unlockedAt,
  });
}
