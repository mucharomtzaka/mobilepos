import 'package:flutter/material.dart';

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
  bool isScrollControlled = false,
}) {
  if (isScrollControlled) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder: (ctx, animation, secondaryAnimation) => Align(
        alignment: Alignment.bottomCenter,
        child: _BottomSheetContent(
          maxWidth: _maxDialogWidth,
          child: builder(ctx),
        ),
      ),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) =>
          SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        )),
        child: FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _BottomSheetContent(
      maxWidth: _maxDialogWidth,
      child: builder(ctx),
    ),
  );
}

class _BottomSheetContent extends StatelessWidget {
  final double maxWidth;
  final Widget child;
  const _BottomSheetContent({required this.maxWidth, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final topInset = MediaQuery.of(context).padding.top;
    final maxHeight =
        MediaQuery.of(context).size.height - topInset - bottomInset - 12;
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 200),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight.clamp(240, MediaQuery.of(context).size.height),
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: child,
      ),
    );
  }
}
