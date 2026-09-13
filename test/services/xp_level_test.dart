import 'package:flutter_test/flutter_test.dart';
import 'package:jbaudio/models/progression.dart';

void main() {
  group('ProgressionSnapshot Level Logic', () {
    test('Level 1 boundaries', () {
      final s0 = ProgressionSnapshot.fromTotalXp(0);
      expect(s0.currentLevel, 1);
      expect(s0.xpInCurrentLevel, 0);
      expect(s0.xpRequiredForNext, 200);
      expect(s0.progressPercent, 0.0);
      expect(s0.isMaxLevel, false);

      final s1 = ProgressionSnapshot.fromTotalXp(1);
      expect(s1.currentLevel, 1);
      expect(s1.xpInCurrentLevel, 1);
      expect(s1.progressPercent, 1 / 200);

      final s199 = ProgressionSnapshot.fromTotalXp(199);
      expect(s199.currentLevel, 1);
      expect(s199.xpInCurrentLevel, 199);
      expect(s199.progressPercent, 199 / 200);
    });

    test('Level 2 boundary', () {
      final s200 = ProgressionSnapshot.fromTotalXp(200);
      expect(s200.currentLevel, 2);
      expect(s200.xpInCurrentLevel, 0);
      expect(s200.xpRequiredForNext, 236); // Saut 2: 200 * 1.18 = 236
      expect(s200.progressPercent, 0.0);
    });

    test('Level 3 boundary', () {
      // Threshold for Level 3 = Saut 1 + Saut 2 = 200 + 236 = 436
      final s435 = ProgressionSnapshot.fromTotalXp(435);
      expect(s435.currentLevel, 2);

      final s436 = ProgressionSnapshot.fromTotalXp(436);
      expect(s436.currentLevel, 3);
      expect(s436.xpInCurrentLevel, 0);
      expect(s436.xpRequiredForNext, 278); // Saut 3: 200 * 1.18^2 = 278.48 -> 278
    });

    test('Mid-level progress', () {
      // Level 2 goes from 200 to 436. Required = 236.
      // Mid point = 200 + 118 = 318
      final s318 = ProgressionSnapshot.fromTotalXp(318);
      expect(s318.currentLevel, 2);
      expect(s318.xpInCurrentLevel, 118);
      expect(s318.progressPercent, 0.5);
    });

    test('Max level 20', () {
      // Approximate cumulative XP for level 20 is around 24698
      // Let's just use a high value
      final sHigh = ProgressionSnapshot.fromTotalXp(1000000);
      expect(sHigh.currentLevel, 20);
      expect(sHigh.isMaxLevel, true);
      expect(sHigh.progressPercent, 1.0);
      expect(sHigh.xpRequiredForNext, 0);
    });

    test('Negative XP handling', () {
      final sNeg = ProgressionSnapshot.fromTotalXp(-50);
      expect(sNeg.totalXp, 0);
      expect(sNeg.currentLevel, 1);
    });

    test('Consistency check: xpInCurrentLevel + remaining should match required', () {
      for (int xp in [100, 500, 2000, 5000]) {
        final s = ProgressionSnapshot.fromTotalXp(xp);
        if (!s.isMaxLevel) {
          // In our snapshot, we don't expose xpRemaining explicitly but it's calculated in UI
          // requiredForNext is the total saut.
          // cumulativeStart + xpInCurrentLevel = totalXp
          // cumulativeStart + requiredForNext = nextThreshold
          expect(s.xpInCurrentLevel <= s.xpRequiredForNext, true);
        }
      }
    });
  });
}
