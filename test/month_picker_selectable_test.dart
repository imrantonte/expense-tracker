// ignore_for_file: prefer_const_declarations

import 'package:flutter_test/flutter_test.dart';
import 'package:where_did_it_go/widgets/month_picker_sheet.dart';

void main() {
  // Shared fixtures
  const joinYear  = 2024;
  const joinMonth = 3; // March 2024
  final now = DateTime(2026, 11, 18); // simulate "today"

  bool selectable(int year, int month) => isMonthSelectable(
        year: year,
        month: month,
        joinYear: joinYear,
        joinMonth: joinMonth,
        now: now,
      );

  // ── isMonthSelectable ──────────────────────────────────────────────────────

  group('isMonthSelectable', () {
    test('join month itself is enabled', () {
      expect(selectable(joinYear, joinMonth), isTrue);
    });

    test('month before join month is disabled', () {
      expect(selectable(joinYear, joinMonth - 1), isFalse); // Feb 2024
    });

    test('year before join year is disabled', () {
      expect(selectable(joinYear - 1, 12), isFalse); // Dec 2023
    });

    test('current month (today) is enabled', () {
      expect(selectable(now.year, now.month), isTrue);
    });

    test('month after current month is disabled', () {
      // December 2026 — one month after November 2026
      expect(selectable(now.year, now.month + 1), isFalse);
    });

    test('next year is entirely disabled', () {
      expect(selectable(now.year + 1, 1), isFalse);
    });

    test('a past month in a past year (after join) is enabled', () {
      expect(selectable(2025, 6), isTrue); // June 2025 is in range
    });

    test('month exactly at join month boundary is enabled', () {
      // The join month itself should always be selectable.
      expect(selectable(joinYear, joinMonth), isTrue);
    });
  });

  // ── isYearSelectable ───────────────────────────────────────────────────────

  group('isYearSelectable', () {
    bool yearOk(int y) => isYearSelectable(
          year: y,
          joinYear: joinYear,
          joinMonth: joinMonth,
          now: now,
        );

    test('join year is selectable', () {
      expect(yearOk(joinYear), isTrue);
    });

    test('year before join year is not selectable', () {
      expect(yearOk(joinYear - 1), isFalse);
    });

    test('current year is selectable', () {
      expect(yearOk(now.year), isTrue);
    });

    test('next year is not selectable', () {
      expect(yearOk(now.year + 1), isFalse);
    });
  });
}
