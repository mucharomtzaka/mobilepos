import 'package:flutter/material.dart';

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanRect;
  final double lineProgress;

  ScannerOverlayPainter({required this.scanRect, required this.lineProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final innerPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)));
    final path = Path.combine(PathOperation.difference, outerPath, innerPath);

    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.5));

    final lineY = scanRect.top + scanRect.height * lineProgress;
    canvas.drawLine(
      Offset(scanRect.left + 4, lineY),
      Offset(scanRect.right - 4, lineY),
      Paint()
        ..color = Colors.cyan
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    const cornerLen = 28.0;
    final stroke = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.top + cornerLen)
        ..lineTo(scanRect.left, scanRect.top)
        ..lineTo(scanRect.left + cornerLen, scanRect.top),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLen, scanRect.top)
        ..lineTo(scanRect.right, scanRect.top)
        ..lineTo(scanRect.right, scanRect.top + cornerLen),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.bottom - cornerLen)
        ..lineTo(scanRect.left, scanRect.bottom)
        ..lineTo(scanRect.left + cornerLen, scanRect.bottom),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLen, scanRect.bottom)
        ..lineTo(scanRect.right, scanRect.bottom)
        ..lineTo(scanRect.right, scanRect.bottom - cornerLen),
      stroke,
    );
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter old) =>
      old.lineProgress != lineProgress || old.scanRect != scanRect;
}
