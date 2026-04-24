import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xiangqi_mobile/utils/fen_utils.dart';

class PieceModel {
  final String id;
  final String code;
  int row;
  int col;

  PieceModel({required this.id, required this.code, required this.row, required this.col});
}

/// Renders all animated chess pieces using [AnimatedPositioned].
class ChessPiecesLayer extends StatelessWidget {
  final List<PieceModel> pieces;
  final double cellW;
  final double cellH;
  final bool isFlipped;

  const ChessPiecesLayer({
    super.key,
    required this.pieces,
    required this.cellW,
    required this.cellH,
    required this.isFlipped,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: pieces.map((piece) {
        int displayRow = isFlipped ? 9 - piece.row : piece.row;
        int displayCol = isFlipped ? 8 - piece.col : piece.col;

        return AnimatedPositioned(
          key: ValueKey(piece.id),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          left: displayCol * cellW,
          top: displayRow * cellH,
          width: cellW,
          height: cellH,
          child: IgnorePointer(
            child: Center(
              child: Container(
                width: cellW * 0.90,
                height: cellH * 0.90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Colors.white,
                      Color(0xFFF3EFEA),
                      Color(0xFFD6CDBB),
                    ],
                    stops: [0.3, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 2,
                      offset: const Offset(-1, -1),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF8B7355),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(3.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  child: ClipOval(
                    child: SvgPicture.asset(
                      FenUtils.getPieceAsset(piece.code),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
