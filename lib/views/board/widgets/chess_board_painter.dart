import 'package:flutter/material.dart';

/// Painted overlay: grid, palace lines, river text, cross markers, highlights.
class XiangqiPainter extends CustomPainter {
  final Offset? selectedCell;
  final Offset? lastMoveFrom;
  final Offset? lastMoveTo;
  final List<Offset> legalMoves;
  final List<Offset> captureMoves;
  final bool isFlipped;

  const XiangqiPainter({
    this.selectedCell,
    this.lastMoveFrom,
    this.lastMoveTo,
    required this.legalMoves,
    required this.captureMoves,
    this.isFlipped = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..strokeWidth = 1.2;

    final thickerPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..strokeWidth = 2.5;

    double cellW = size.width / 9;
    double cellH = size.height / 10;

    final coordStyle = TextStyle(
      color: Colors.black.withOpacity(0.3),
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    // Board frame
    canvas.drawRect(
      Rect.fromLTWH(cellW / 2, cellH / 2, 8 * cellW, 9 * cellH),
      thickerPaint..style = PaintingStyle.stroke,
    );

    // Vertical lines (split by river)
    for (int i = 0; i < 9; i++) {
      double x = i * cellW + (cellW / 2);
      canvas.drawLine(Offset(x, cellH / 2), Offset(x, 4.5 * cellH), paint);
      canvas.drawLine(Offset(x, 5.5 * cellH), Offset(x, 9.5 * cellH), paint);

      String colText = isFlipped ? (9 - i).toString() : (i + 1).toString();
      _drawText(canvas, colText, Offset(x, 0.2 * cellH), coordStyle);
      _drawText(canvas, colText, Offset(x, 9.8 * cellH), coordStyle);
    }

    // Horizontal lines
    for (int i = 0; i < 10; i++) {
      double y = i * cellH + (cellH / 2);
      canvas.drawLine(Offset(cellW / 2, y), Offset(8.5 * cellW, y), paint);

      String rowText = isFlipped ? i.toString() : (9 - i).toString();
      _drawText(canvas, rowText, Offset(0.2 * cellW, y), coordStyle);
      _drawText(canvas, rowText, Offset(8.8 * cellW, y), coordStyle);
    }

    // Palace X-lines
    canvas.drawLine(Offset(3.5 * cellW, cellH / 2), Offset(5.5 * cellW, 2.5 * cellH), paint);
    canvas.drawLine(Offset(5.5 * cellW, cellH / 2), Offset(3.5 * cellW, 2.5 * cellH), paint);
    canvas.drawLine(Offset(3.5 * cellW, 7.5 * cellH), Offset(5.5 * cellW, 9.5 * cellH), paint);
    canvas.drawLine(Offset(5.5 * cellW, 7.5 * cellH), Offset(3.5 * cellW, 9.5 * cellH), paint);

    // Cross markers
    final markerPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..strokeWidth = 1.5;

    void drawCross(int row, int col) {
      double x = col * cellW + (cellW / 2);
      double y = row * cellH + (cellH / 2);
      const double gap = 5.0;
      const double len = 12.0;
      if (col > 0) {
        canvas.drawLine(Offset(x - gap, y - gap), Offset(x - gap - len, y - gap), markerPaint);
        canvas.drawLine(Offset(x - gap, y - gap), Offset(x - gap, y - gap - len), markerPaint);
        canvas.drawLine(Offset(x - gap, y + gap), Offset(x - gap - len, y + gap), markerPaint);
        canvas.drawLine(Offset(x - gap, y + gap), Offset(x - gap, y + gap + len), markerPaint);
      }
      if (col < 8) {
        canvas.drawLine(Offset(x + gap, y - gap), Offset(x + gap + len, y - gap), markerPaint);
        canvas.drawLine(Offset(x + gap, y - gap), Offset(x + gap, y - gap - len), markerPaint);
        canvas.drawLine(Offset(x + gap, y + gap), Offset(x + gap + len, y + gap), markerPaint);
        canvas.drawLine(Offset(x + gap, y + gap), Offset(x + gap, y + gap + len), markerPaint);
      }
    }

    drawCross(2, 1); drawCross(2, 7);
    drawCross(7, 1); drawCross(7, 7);
    for (int i = 0; i <= 8; i += 2) {
      drawCross(3, i);
      drawCross(6, i);
    }

    // River text
    const String riverText = 'cotuong.xyz';
    final tp = TextPainter(
      text: TextSpan(
        text: riverText,
        style: TextStyle(
          color: Colors.black.withOpacity(0.15),
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 8.0,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, 4.5 * cellH + (cellH - tp.height) / 2));

    _paintHighlights(canvas, cellW, cellH);
  }

  void _drawText(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  void _paintHighlights(Canvas canvas, double cellW, double cellH) {
    // Last move highlight
    if (lastMoveFrom != null && lastMoveTo != null) {
      final fromPaint = Paint()..color = const Color(0xFF4338CA).withOpacity(0.15);
      final toPaint = Paint()
        ..color = const Color(0xFF4338CA).withOpacity(0.25)
        ..style = PaintingStyle.fill;
      final toBorderPaint = Paint()
        ..color = const Color(0xFF4338CA).withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      int fCol = isFlipped ? 8 - lastMoveFrom!.dx.toInt() : lastMoveFrom!.dx.toInt();
      int fRow = isFlipped ? 9 - lastMoveFrom!.dy.toInt() : lastMoveFrom!.dy.toInt();
      canvas.drawCircle(Offset(fCol * cellW + cellW / 2, fRow * cellH + cellH / 2), cellW * 0.4, fromPaint);

      int tCol = isFlipped ? 8 - lastMoveTo!.dx.toInt() : lastMoveTo!.dx.toInt();
      int tRow = isFlipped ? 9 - lastMoveTo!.dy.toInt() : lastMoveTo!.dy.toInt();
      canvas.drawCircle(Offset(tCol * cellW + cellW / 2, tRow * cellH + cellH / 2), cellW * 0.48, toPaint);
      canvas.drawCircle(Offset(tCol * cellW + cellW / 2, tRow * cellH + cellH / 2), cellW * 0.48, toBorderPaint);
    }

    // Selected cell
    if (selectedCell != null) {
      int dCol = isFlipped ? 8 - selectedCell!.dx.toInt() : selectedCell!.dx.toInt();
      int dRow = isFlipped ? 9 - selectedCell!.dy.toInt() : selectedCell!.dy.toInt();
      final selPaint = Paint()
        ..color = const Color(0xFF0EA5E9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(Offset(dCol * cellW + cellW / 2, dRow * cellH + cellH / 2), cellW * 0.48, selPaint);
    }

    // Legal move dots
    final dotPaint = Paint()..color = const Color(0xFF0EA5E9).withOpacity(0.4);
    for (var move in legalMoves) {
      int dCol = isFlipped ? 8 - move.dx.toInt() : move.dx.toInt();
      int dRow = isFlipped ? 9 - move.dy.toInt() : move.dy.toInt();
      canvas.drawCircle(Offset(dCol * cellW + cellW / 2, dRow * cellH + cellH / 2), cellW * 0.12, dotPaint);
    }

    // Capture rings
    final capFill = Paint()
      ..color = const Color(0xFFDC2626).withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final capBorder = Paint()
      ..color = const Color(0xFFDC2626).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (var move in captureMoves) {
      int dCol = isFlipped ? 8 - move.dx.toInt() : move.dx.toInt();
      int dRow = isFlipped ? 9 - move.dy.toInt() : move.dy.toInt();
      canvas.drawCircle(Offset(dCol * cellW + cellW / 2, dRow * cellH + cellH / 2), cellW * 0.4, capFill);
      canvas.drawCircle(Offset(dCol * cellW + cellW / 2, dRow * cellH + cellH / 2), cellW * 0.4, capBorder);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
