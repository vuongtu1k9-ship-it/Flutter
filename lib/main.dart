/// lib/main.dart
/// Entry point for Flutter Xiangqi app

import 'package:flutter/material.dart';
import 'models/piece.dart';
import 'models/game.dart';

void main() {
  runApp(const XiangqiApp());
}

class XiangqiApp extends StatelessWidget {
  const XiangqiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xiangqi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const XiangqiHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class XiangqiHomePage extends StatefulWidget {
  const XiangqiHomePage({super.key});

  @override
  State<XiangqiHomePage> createState() => _XiangqiHomePageState();
}

class _XiangqiHomePageState extends State<XiangqiHomePage> {
  final Game game = Game();
  Piece? selectedPiece;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xiangqi'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Turn: ${game.getCurrentPlayerText()}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 9 / 10,
                child: Container(
                  color: Colors.brown[200],
                  padding: const EdgeInsets.all(8.0),
                  child: CustomPaint(
                    painter: XiangqiBoardPainter(game: game, selectedPiece: selectedPiece),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onTapDown: (details) => _handleBoardTap(
                            details.localPosition,
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: game.canUndo() ? () {
                    setState(() {
                      game.undo();
                    });
                  } : null,
                  child: const Text('Undo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleBoardTap(Offset localPosition, double width, double height) {
    if (game.isGameOver) return;

    final cellWidth = width / 9;
    final cellHeight = height / 10;

    final col = (localPosition.dx / cellWidth).floor().clamp(0, 8);
    final row = (localPosition.dy / cellHeight).floor().clamp(0, 9);

    final piece = game.getPieceAt(col, row);

    if (selectedPiece == null) {
      if (piece != null && piece.color == game.currentPlayer) {
        setState(() {
          selectedPiece = piece;
        });
      }
    } else {
      if (game.movePiece(selectedPiece!.x, selectedPiece!.y, col, row)) {
        setState(() {
          selectedPiece = null;
        });
      } else {
        if (piece != null && piece.color == game.currentPlayer) {
          setState(() {
            selectedPiece = piece;
          });
        } else {
          setState(() {
            selectedPiece = null;
          });
        }
      }
    }
  }
}

class XiangqiBoardPainter extends CustomPainter {
  final Game game;
  final Piece? selectedPiece;

  XiangqiBoardPainter({required this.game, this.selectedPiece});

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / 9;
    final cellHeight = size.height / 10;

    final boardPaint = Paint()..color = Colors.brown[300]!;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), boardPaint);

    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    for (int i = 0; i <= 9; i++) {
      canvas.drawLine(
        Offset(i * cellWidth, 0),
        Offset(i * cellWidth, size.height),
        linePaint,
      );
    }

    for (int i = 0; i <= 10; i++) {
      canvas.drawLine(
        Offset(0, i * cellHeight),
        Offset(size.width, i * cellHeight),
        linePaint,
      );
    }

    final riverPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.2);
    canvas.drawRect(
      Rect.fromLTWH(0, 5 * cellHeight, size.width, cellHeight),
      riverPaint,
    );

    for (final piece in game.getPieces()) {
      final centerX = piece.x * cellWidth + cellWidth / 2;
      final centerY = piece.y * cellHeight + cellHeight / 2;

      final piecePaint = Paint()
        ..color = piece.color == PieceColor.red ? const Color(0xFFDC143C) : const Color(0xFF191970);

      canvas.drawCircle(
        Offset(centerX, centerY),
        cellWidth * 0.4,
        piecePaint,
      );

      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(
        Offset(centerX, centerY),
        cellWidth * 0.4,
        borderPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: _getPieceSymbol(piece),
          style: TextStyle(
            color: Colors.white,
            fontSize: cellWidth * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, centerY - textPainter.height / 2),
      );
    }

    if (selectedPiece != null) {
      final centerX = selectedPiece!.x * cellWidth + cellWidth / 2;
      final centerY = selectedPiece!.y * cellHeight + cellHeight / 2;

      final highlightPaint = Paint()
        ..color = Colors.yellow.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;

      canvas.drawCircle(
        Offset(centerX, centerY),
        cellWidth * 0.4 + 8,
        highlightPaint,
      );
    }
  }

  String _getPieceSymbol(Piece piece) {
    switch (piece.type) {
      case PieceType.general:
        return 'G';
      case PieceType.advisor:
        return 'A';
      case PieceType.elephant:
        return 'E';
      case PieceType.chariot:
        return 'R';
      case PieceType.cannon:
        return 'C';
      case PieceType.horse:
        return 'H';
      case PieceType.soldier:
        return piece.color == PieceColor.red ? 'S' : 's';
    }
  }

  @override
  bool shouldRepaint(covariant XiangqiBoardPainter oldDelegate) {
    return true;
  }
}