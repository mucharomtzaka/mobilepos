import 'package:flutter/material.dart';

/// Constrain dialogs and bottom sheets to max 480px wide on tablet landscape.
const double _maxDialogWidth = 480;

Future<T?> showConstrainedDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxDialogWidth),
        child: Material(
          type: MaterialType.transparency,
          child: builder(ctx),
        ),
      ),
    ),
  );
}

Future<T?> showConstrainedModalBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: _maxDialogWidth,
        minWidth: _maxDialogWidth,
      ),
      child: builder(ctx),
    ),
  );
}
