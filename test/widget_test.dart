// Basic smoke test for "Where Did It Go?" app.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:where_did_it_go/data/expense_provider.dart';
import 'package:where_did_it_go/main.dart';

void main() {
  testWidgets('App renders HomeScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ExpenseProvider(),
        child: const WhereDidItGoApp(),
      ),
    );

    // App bar title should be present.
    expect(find.text('Where Did It Go?'), findsOneWidget);
  });
}
