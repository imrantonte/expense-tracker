// Unit tests for budget threshold and overage logic in lib/core/validators.dart
// and quiet-hours / interval helpers in lib/services/reminder_service.dart.
// Run with: flutter test test/budget_threshold_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:where_did_it_go/core/validators.dart';
import 'package:where_did_it_go/services/reminder_service.dart';

void main() {
  // ── isBudgetThresholdReached ──────────────────────────────────────────────

  group('isBudgetThresholdReached', () {
    test('returns false when limit is zero', () {
      expect(
        isBudgetThresholdReached(spent: 100, limit: 0, alertThreshold: 0.8),
        isFalse,
      );
    });

    test('returns false when alertThreshold is zero', () {
      expect(
        isBudgetThresholdReached(spent: 100, limit: 1000, alertThreshold: 0),
        isFalse,
      );
    });

    test('returns false when spent is below threshold', () {
      // 750 < 1000 * 0.8 = 800
      expect(
        isBudgetThresholdReached(spent: 750, limit: 1000, alertThreshold: 0.8),
        isFalse,
      );
    });

    test('returns true when spent equals threshold exactly', () {
      // 800 == 1000 * 0.8
      expect(
        isBudgetThresholdReached(spent: 800, limit: 1000, alertThreshold: 0.8),
        isTrue,
      );
    });

    test('returns true when spent exceeds threshold', () {
      expect(
        isBudgetThresholdReached(spent: 900, limit: 1000, alertThreshold: 0.8),
        isTrue,
      );
    });

    test('returns true even when spent exceeds the limit itself', () {
      expect(
        isBudgetThresholdReached(
            spent: 1200, limit: 1000, alertThreshold: 0.8),
        isTrue,
      );
    });

    test('works with 90% threshold', () {
      expect(
        isBudgetThresholdReached(spent: 899, limit: 1000, alertThreshold: 0.9),
        isFalse,
      );
      expect(
        isBudgetThresholdReached(spent: 900, limit: 1000, alertThreshold: 0.9),
        isTrue,
      );
    });
  });

  // ── isBudgetExceeded ──────────────────────────────────────────────────────

  group('isBudgetExceeded', () {
    test('returns false when limit is zero', () {
      expect(isBudgetExceeded(spent: 500, limit: 0), isFalse);
    });

    test('returns false when spent equals limit', () {
      expect(isBudgetExceeded(spent: 1000, limit: 1000), isFalse);
    });

    test('returns false when spent is below limit', () {
      expect(isBudgetExceeded(spent: 999, limit: 1000), isFalse);
    });

    test('returns true when spent exceeds limit', () {
      expect(isBudgetExceeded(spent: 1001, limit: 1000), isTrue);
    });

    test('returns true with a fractional overage', () {
      expect(isBudgetExceeded(spent: 1000.01, limit: 1000), isTrue);
    });
  });

  // ── budgetUsageFraction ───────────────────────────────────────────────────

  group('budgetUsageFraction', () {
    test('returns 0 when limit is zero', () {
      expect(budgetUsageFraction(spent: 500, limit: 0), equals(0.0));
    });

    test('returns 0 when spent is zero', () {
      expect(budgetUsageFraction(spent: 0, limit: 1000), equals(0.0));
    });

    test('returns 0.5 at half the limit', () {
      expect(
          budgetUsageFraction(spent: 500, limit: 1000), closeTo(0.5, 0.001));
    });

    test('returns 1.0 at exactly the limit', () {
      expect(
          budgetUsageFraction(spent: 1000, limit: 1000), closeTo(1.0, 0.001));
    });

    test('clamps at 1.0 when over limit', () {
      expect(
          budgetUsageFraction(spent: 1500, limit: 1000), closeTo(1.0, 0.001));
    });
  });

  // ── BudgetRepository.monthKey (pure logic) ────────────────────────────────

  group('monthKey formatting', () {
    // Test the logic inline — same formula as BudgetRepository.monthKey.
    String monthKey(int year, int month) =>
        '$year-${month.toString().padLeft(2, '0')}';

    test('pads single-digit months', () {
      expect(monthKey(2026, 1), equals('2026-01'));
      expect(monthKey(2026, 9), equals('2026-09'));
    });

    test('does not pad double-digit months', () {
      expect(monthKey(2026, 10), equals('2026-10'));
      expect(monthKey(2026, 12), equals('2026-12'));
    });
  });

  // ── ReminderService quiet-hours logic ─────────────────────────────────────

  group('ReminderService.isInQuietHours', () {
    // Simple window: 22:00 → 08:00 (wraps midnight)
    bool quiet(DateTime t) => ReminderService.isInQuietHours(
          t,
          fromHour: 22,
          fromMin: 0,
          toHour: 8,
          toMin: 0,
        );

    test('returns true at 22:00 (window start)', () {
      expect(quiet(DateTime(2026, 1, 1, 22, 0)), isTrue);
    });

    test('returns true at midnight', () {
      expect(quiet(DateTime(2026, 1, 1, 0, 0)), isTrue);
    });

    test('returns true at 07:59', () {
      expect(quiet(DateTime(2026, 1, 1, 7, 59)), isTrue);
    });

    test('returns false at 08:00 (window end)', () {
      expect(quiet(DateTime(2026, 1, 1, 8, 0)), isFalse);
    });

    test('returns false at noon', () {
      expect(quiet(DateTime(2026, 1, 1, 12, 0)), isFalse);
    });

    test('returns false at 21:59', () {
      expect(quiet(DateTime(2026, 1, 1, 21, 59)), isFalse);
    });
  });

  group('ReminderService.isInQuietHours — simple window (08:00 → 10:00)', () {
    bool quiet(DateTime t) => ReminderService.isInQuietHours(
          t,
          fromHour: 8,
          fromMin: 0,
          toHour: 10,
          toMin: 0,
        );

    test('returns true at 08:00', () {
      expect(quiet(DateTime(2026, 1, 1, 8, 0)), isTrue);
    });

    test('returns true at 09:30', () {
      expect(quiet(DateTime(2026, 1, 1, 9, 30)), isTrue);
    });

    test('returns false at 10:00', () {
      expect(quiet(DateTime(2026, 1, 1, 10, 0)), isFalse);
    });

    test('returns false at midnight', () {
      expect(quiet(DateTime(2026, 1, 1, 0, 0)), isFalse);
    });
  });

  // ── ReminderService.intervalMinutesForKey ─────────────────────────────────

  group('ReminderService.intervalMinutesForKey', () {
    test('2h → 120 minutes', () {
      expect(ReminderService.intervalMinutesForKey('2h'), equals(120));
    });

    test('3h → 180 minutes', () {
      expect(ReminderService.intervalMinutesForKey('3h'), equals(180));
    });

    test('4h → 240 minutes', () {
      expect(ReminderService.intervalMinutesForKey('4h'), equals(240));
    });

    test('1d → 1440 minutes', () {
      expect(ReminderService.intervalMinutesForKey('1d'), equals(1440));
    });

    test('unknown key falls back to 120 minutes', () {
      expect(ReminderService.intervalMinutesForKey('custom'), equals(120));
    });
  });
}
