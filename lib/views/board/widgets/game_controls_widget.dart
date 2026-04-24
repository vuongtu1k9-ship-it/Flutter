import 'package:flutter/material.dart';

/// Puzzle tools bar: Hint, Reset, Exit.
class GameControlsWidget extends StatelessWidget {
  final VoidCallback onHint;
  final VoidCallback onReset;
  final VoidCallback onExit;

  const GameControlsWidget({
    super.key,
    required this.onHint,
    required this.onReset,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildToolButton(icon: Icons.lightbulb_outline_rounded, label: 'Gợi ý', color: Colors.amber, onTap: onHint),
          _buildToolButton(icon: Icons.refresh_rounded, label: 'Làm lại', color: Colors.blue, onTap: onReset),
          _buildToolButton(icon: Icons.close_rounded, label: 'Thoát', color: Colors.red, onTap: onExit),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.85),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
