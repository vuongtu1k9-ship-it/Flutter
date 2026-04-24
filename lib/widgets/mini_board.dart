import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xiangqi_mobile/utils/fen_utils.dart';

class MiniBoard extends StatelessWidget {
  final String? fen;
  final List<dynamic>? board;
  final bool isFlipped;
  final double? width;

  const MiniBoard({
    super.key,
    this.fen,
    this.board,
    this.isFlipped = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double boardWidth = width ?? constraints.maxWidth;
        if (boardWidth.isInfinite || boardWidth == 0) {
          boardWidth = 120; // Default fallback width
        }

        double cellW = boardWidth / 9;
        double cellH = cellW * 1.1;
        Size boardSize = Size(boardWidth, cellH * 10);

        List<List<String?>> boardData;
        if (board != null) {
          boardData = FenUtils.fromBoardObject(board!);
        } else {
          boardData = FenUtils.parseFen(fen ?? "rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1");
        }

        return SizedBox(
          width: boardSize.width,
          height: boardSize.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: boardSize.width,
                height: boardSize.height,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5D3B3), // Lighter, modern wood color
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    )
                  ],
                ),
                child: CustomPaint(
                  painter: MiniBoardPainter(isFlipped: isFlipped),
                ),
              ),
              ..._buildPieces(boardData, cellW, cellH),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildPieces(List<List<String?>> boardData, double cellW, double cellH) {
    List<Widget> pieces = [];
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 9; c++) {
        String? code = boardData[r][c];
        if (code != null) {
          int displayRow = isFlipped ? 9 - r : r;
          int displayCol = isFlipped ? 8 - c : c;

          pieces.add(
            Positioned(
              left: displayCol * cellW,
              top: displayRow * cellH,
              width: cellW,
              height: cellH,
              child: Center(
                child: Container(
                  width: cellW * 0.95, // Maximize piece size inside cell
                  height: cellH * 0.95,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 1.5,
                        offset: const Offset(0, 0.5),
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    FenUtils.getPieceAsset(code),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          );
        }
      }
    }
    return pieces;
  }
}

class MiniBoardPainter extends CustomPainter {
  final bool isFlipped;

  MiniBoardPainter({this.isFlipped = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 0.5;

    final thickerPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..strokeWidth = 1.0;

    double cellW = size.width / 9;
    double cellH = size.height / 10;

    // Draw main board frame
    canvas.drawRect(
      Rect.fromLTWH(cellW / 2, cellH / 2, 8 * cellW, 9 * cellH),
      thickerPaint..style = PaintingStyle.stroke,
    );

    // Vertical lines
    for (int i = 0; i < 9; i++) {
      double x = i * cellW + (cellW / 2);
      canvas.drawLine(Offset(x, cellH / 2), Offset(x, 4.5 * cellH), paint);
      canvas.drawLine(Offset(x, 5.5 * cellH), Offset(x, 9.5 * cellH), paint);
    }

    // Horizontal lines
    for (int i = 0; i < 10; i++) {
      double y = i * cellH + (cellH / 2);
      canvas.drawLine(Offset(cellW / 2, y), Offset(8.5 * cellW, y), paint);
    }

    // Palace (X lines)
    canvas.drawLine(Offset(3.5 * cellW, cellH / 2), Offset(5.5 * cellW, 2.5 * cellH), paint);
    canvas.drawLine(Offset(5.5 * cellW, cellH / 2), Offset(3.5 * cellW, 2.5 * cellH), paint);
    canvas.drawLine(Offset(3.5 * cellW, 7.5 * cellH), Offset(5.5 * cellW, 9.5 * cellH), paint);
    canvas.drawLine(Offset(5.5 * cellW, 7.5 * cellH), Offset(3.5 * cellW, 9.5 * cellH), paint);

    // Cross markers (Cannons and Soldiers)
    final markerPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 0.5;

    void drawCross(int row, int col) {
      double x = col * cellW + (cellW / 2);
      double y = row * cellH + (cellH / 2);
      double gap = cellW * 0.12;
      double len = cellW * 0.18;

      // Top Left
      if (col > 0) {
        canvas.drawLine(Offset(x - gap, y - gap), Offset(x - gap - len, y - gap), markerPaint);
        canvas.drawLine(Offset(x - gap, y - gap), Offset(x - gap, y - gap - len), markerPaint);
      }
      // Top Right
      if (col < 8) {
        canvas.drawLine(Offset(x + gap, y - gap), Offset(x + gap + len, y - gap), markerPaint);
        canvas.drawLine(Offset(x + gap, y - gap), Offset(x + gap, y - gap - len), markerPaint);
      }
      // Bottom Left
      if (col > 0) {
        canvas.drawLine(Offset(x - gap, y + gap), Offset(x - gap - len, y + gap), markerPaint);
        canvas.drawLine(Offset(x - gap, y + gap), Offset(x - gap, y + gap + len), markerPaint);
      }
      // Bottom Right
      if (col < 8) {
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
