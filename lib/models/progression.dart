import 'dart:math';

class UserProgression {
  static const int xpPerMinute = 1;
  static const int xpPlayValidated = 2;
  static const int xpSongCompleted = 5;
  static const int xpDiscoveryBonus = 10;
  static const int xpDailyQuestBonus = 50;
  static const int xpWeeklyQuestBonus = 200;

  final int totalXp;
  final int pendingSeconds;

  const UserProgression({
    this.totalXp = 0,
    this.pendingSeconds = 0,
  });

  UserProgression copyWith({
    int? totalXp,
    int? pendingSeconds,
  }) {
    return UserProgression(
      totalXp: totalXp ?? this.totalXp,
      pendingSeconds: pendingSeconds ?? this.pendingSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_xp': totalXp,
      'pending_seconds': pendingSeconds,
    };
  }

  factory UserProgression.fromJson(Map<String, dynamic> json) {
    return UserProgression(
      totalXp: json['total_xp'] as int? ?? 0,
      pendingSeconds: json['pending_seconds'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProgression &&
          runtimeType == other.runtimeType &&
          totalXp == other.totalXp &&
          pendingSeconds == other.pendingSeconds;

  @override
  int get hashCode => totalXp.hashCode ^ pendingSeconds.hashCode;
}

/// Represents the calculated state of user progression at a point in time.
class ProgressionSnapshot {
  static const int maxLevel = 20;

  final int totalXp;
  final int currentLevel;
  final int xpInCurrentLevel;
  final int xpRequiredForNext;
  final double progressPercent;
  final bool isMaxLevel;

  const ProgressionSnapshot({
    required this.totalXp,
    required this.currentLevel,
    required this.xpInCurrentLevel,
    required this.xpRequiredForNext,
    required this.progressPercent,
    required this.isMaxLevel,
  });

  /// Pure function to derive level data from total XP.
  /// Formula: Jump_N (N to N+1) = 200 * 1.18^(N-1)
  factory ProgressionSnapshot.fromTotalXp(int xp) {
    if (xp < 0) xp = 0;

    int level = 1;
    int cumulativeXp = 0;
    int nextLevelThreshold = 0;
    int currentLevelStartThreshold = 0;

    // Pre-calculate/Iterate to find current level and boundaries.
    // For 20 levels, we do max 19 iterations.
    for (int n = 1; n < maxLevel; n++) {
      int jump = (200 * pow(1.18, n - 1)).round();
      nextLevelThreshold = cumulativeXp + jump;

      if (xp < nextLevelThreshold) {
        // User is in level 'n'
        break;
      }

      currentLevelStartThreshold = nextLevelThreshold;
      cumulativeXp = nextLevelThreshold;
      level = n + 1;
    }

    if (level >= maxLevel) {
      // Handle max level case
      return ProgressionSnapshot(
        totalXp: xp,
        currentLevel: maxLevel,
        xpInCurrentLevel: xp - cumulativeXp,
        xpRequiredForNext: 0, // No more levels
        progressPercent: 1.0,
        isMaxLevel: true,
      );
    }

    int xpInLevel = xp - currentLevelStartThreshold;
    int requiredForNext = nextLevelThreshold - currentLevelStartThreshold;
    double percent = (xpInLevel / requiredForNext).clamp(0.0, 1.0);

    return ProgressionSnapshot(
      totalXp: xp,
      currentLevel: level,
      xpInCurrentLevel: xpInLevel,
      xpRequiredForNext: requiredForNext,
      progressPercent: percent,
      isMaxLevel: false,
    );
  }
}
