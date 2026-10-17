import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Shows a styled [ModalBottomSheet] with a 24px top corner radius and a
/// drag handle, using the app's [BottomSheetThemeData].
///
/// ```dart
/// showAppBottomSheet(
///   context: context,
///   title: 'Add Expense',
///   child: AddExpenseForm(),
/// );
/// ```
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isScrollControlled = true,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    // Shape and drag handle come from BottomSheetThemeData.
    builder: (ctx) => Padding(
      // Push content above the system keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(ctx).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  kSp16,
                  kSp4,
                  kSp16,
                  kSp8,
                ),
                child: Text(
                  title,
                  style: Theme.of(ctx).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              Divider(
                height: 1,
                color: Theme.of(ctx).dividerColor,
              ),
            ],
            child,
          ],
        ),
      ),
    ),
  );
}
