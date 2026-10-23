// Pure, widget-free validator functions shared across auth screens.
//
// All functions are top-level so they can be imported and unit-tested
// without bringing in Flutter widgets or Firebase.

// ── Email ──────────────────────────────────────────────────────────────────

/// Returns `true` when [email] looks like a valid email address.
///
/// Uses a simple pattern that catches the most common mistakes.
bool isValidEmail(String email) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());

// ── Name ───────────────────────────────────────────────────────────────────

/// Returns `null` when [name] is acceptable, otherwise an error message.
String? validateName(String name) {
  final v = name.trim();
  if (v.isEmpty) return 'Please enter your full name.';
  if (v.length < 2) return 'Name must be at least 2 characters.';
  return null;
}

// ── Password ───────────────────────────────────────────────────────────────

/// Returns `null` when [password] meets the minimum requirement, else a message.
String? validatePassword(String password) {
  if (password.length < 6) {
    return 'Password must be at least 6 characters.';
  }
  return null;
}

/// Returns `null` when [confirm] matches [password], else a message.
String? validateConfirmPassword(String password, String confirm) {
  if (password != confirm) return 'Passwords do not match.';
  return null;
}

// ── Amount ─────────────────────────────────────────────────────────────────

/// Returns the parsed amount if [text] is a valid positive number, else `null`.
double? parsePositiveAmount(String text) {
  final v = double.tryParse(text.trim());
  if (v == null || v <= 0) return null;
  return v;
}

// ── Budget ─────────────────────────────────────────────────────────────────

/// Checks whether [spent] has crossed the [alertThreshold] fraction of [limit].
///
/// Returns `true` only when [alertThreshold] > 0 and `spent >= limit * threshold`.
bool isBudgetThresholdReached({
  required double spent,
  required double limit,
  required double alertThreshold,
}) {
  if (limit <= 0 || alertThreshold <= 0) return false;
  return spent >= limit * alertThreshold;
}

/// Checks whether [spent] has exceeded [limit].
bool isBudgetExceeded({required double spent, required double limit}) {
  if (limit <= 0) return false;
  return spent > limit;
}

/// Computes the budget-usage fraction, clamped to [0.0, 1.0].
double budgetUsageFraction({required double spent, required double limit}) {
  if (limit <= 0) return 0.0;
  return (spent / limit).clamp(0.0, 1.0);
}
