// Smoke test — just verifies the test harness is wired correctly.
// Full widget tests require Firebase/plugin initialisation, so we keep this
// minimal and put real logic coverage in validators_test.dart and
// budget_threshold_test.dart.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder: test harness runs', () {
    expect(1 + 1, equals(2));
  });
}
