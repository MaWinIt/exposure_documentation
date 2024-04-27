import 'package:flutter/material.dart';

class DiagrammPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Zeichnen eines weißen Hintergrunds
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Zeichnen der X-Achse
    canvas.drawLine(Offset(4, size.height - 4),
        Offset(size.width - 4, size.height - 4), paint);

    // Zeichnen der Y-Achse
    canvas.drawLine(const Offset(4, 0), Offset(4, size.height - 4), paint);

    // Beschriftung der Achsen
    final textPainter = TextPainter(
      text: const TextSpan(
          text: 'Zeit', style: TextStyle(color: Colors.black, fontSize: 16)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(size.width - textPainter.width - 10,
            size.height - 20 - textPainter.height / 2));

    final textPainterY = TextPainter(
      text: const TextSpan(
          text: 'Angst [%]',
          style: TextStyle(color: Colors.black, fontSize: 16)),
      textDirection: TextDirection.ltr,
    );
    textPainterY.layout();
    textPainterY.paint(canvas, const Offset(20, 0));

    // Zeichnen von Pfeilen am Ende der Achsen
    final arrowPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    // Pfeil für die X-Achse
    canvas.drawPath(
      Path()
        ..moveTo(size.width - 4, size.height - 4)
        ..lineTo(size.width - 4, size.height - 4 - 4)
        ..lineTo(size.width - 4 + 4, size.height - 4)
        ..lineTo(size.width - 4, size.height)
        ..close(),
      arrowPaint,
    );

    // Pfeil für die Y-Achse
    canvas.drawPath(
      Path()
        ..moveTo(4, 4)
        ..lineTo(0, 4)
        ..lineTo(4, 0)
        ..lineTo(8, 4)
        ..close(),
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
