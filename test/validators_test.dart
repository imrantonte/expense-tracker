// Unit tests for lib/core/validators.dart
// Run with: flutter test test/validators_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:where_did_it_go/core/validators.dart';

void main() {
  // ── isValidEmail ──────────────────────────────────────────────────────────

  group('isValidEmail', () {
    test('accepts a well-formed email', () {
      expect(isValidEmail('user@example.com'), isTrue);
    });

    test('accepts email with subdomain', () {
      expect(isValidEmail('user@mail.example.co.uk'), isTrue);
    });

    test('accepts email with plus addressing', () {
      expect(isValidEmail('user+tag@example.com'), isTrue);
    });

    test('accepts email with leading/trailing whitespace', () {
      expect(isValidEmail('  user@example.com  '), isTrue);
    });

    test('rejects empty string', () {
      expect(isValidEmail(''), isFalse);
    });

    test('rejects address without @', () {
      expect(isValidEmail('userexample.com'), isFalse);
    });

    test('rejects address without TLD', () {
      expect(isValidEmail('user@example'), isFalse);
    });

    test('rejects address with double @', () {
      expect(isValidEmail('user@@example.com'), isFalse);
    });
  });

  // ── validateName ─────────────────────────────────────────────────────────

  group('validateName', () {
    test('returns null for a valid name', () {
      expect(validateName('Alice'), isNull);
    });

    test('returns null for a name with leading/trailing space', () {
      expect(validateName('  Bob  '), isNull);
    });

    test('returns error for empty name', () {
      expect(validateName(''), isNotNull);
    });

    test('returns error for whitespace-only name', () {
      expect(validateName('   '), isNotNull);
    });

    test('returns error for single-character name', () {
      expect(validateName('A'), isNotNull);
    });
  });

  // ── validatePassword ──────────────────────────────────────────────────────

  group('validatePassword', () {
    test('returns null for a 6-character password', () {
      expect(validatePassword('abc123'), isNull);
    });

    test('returns null for a long password', () {
      expect(validatePassword('supersecretpassword!'), isNull);
    });

    test('returns error for a 5-character password', () {
      expect(validatePassword('abc12'), isNotNull);
    });

    test('returns error for an empty password', () {
      expect(validatePassword(''), isNotNull);
    });
  });

  // ── validateConfirmPassword ───────────────────────────────────────────────

  group('validateConfirmPassword', () {
    test('returns null when passwords match', () {
      expect(validateConfirmPassword('pass123', 'pass123'), isNull);
    });

    test('returns error when passwords differ', () {
      expect(validateConfirmPassword('pass123', 'PASS123'), isNotNull);
    });

    test('returns error when confirm is empty', () {
      expect(validateConfirmPassword('pass123', ''), isNotNull);
    });
  });

  // ── parsePositiveAmount ───────────────────────────────────────────────────

  group('parsePositiveAmount', () {
    test('parses a positive integer string', () {
      expect(parsePositiveAmount('100'), equals(100.0));
    });

    test('parses a positive decimal string', () {
      expect(parsePositiveAmount('9.99'), closeTo(9.99, 0.001));
    });

    test('returns null for zero', () {
      expect(parsePositiveAmount('0'), isNull);
    });

    test('returns null for a negative number', () {
      expect(parsePositiveAmount('-5'), isNull);
    });

    test('returns null for non-numeric text', () {
      expect(parsePositiveAmount('abc'), isNull);
    });

    test('handles leading/trailing whitespace', () {
      expect(parsePositiveAmount('  42  '), equals(42.0));
    });
  });
}
