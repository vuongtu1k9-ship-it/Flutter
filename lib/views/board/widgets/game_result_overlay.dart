import 'package:flutter/material.dart';

enum GameResult { win, lose, draw }

/// Full-screen game result overlay with animation.
/// Shows WIN (gold), LOSE (grey-blue), or DRAW (teal) state.
class GameResultOverlay extends StatefulWidget {
  final GameResult result;
  final int eloChange;
  final String opponentName;
  final VoidCallback onPlayAgain;
  final VoidCallback onReview;
  final VoidCallback onGoHome;

  const GameResultOverlay({
    super.key,
    required this.result,
    required this.eloChange,
    required this.opponentName,
    required this.onPlayAgain,
    required this.onReview,
    required this.onGoHome,
  });

  @override
  State<GameResultOverlay> createState() => _GameResultOverlayState();
}

class _GameResultOverlayState extends State<GameResultOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  (String title, Color primary, Color bg, IconData icon) get _config {
    switch (widget.result) {
      case GameResult.win:
        return ('CHIẾN THẮNG!', const Color(0xFFF59E0B), const Color(0xFF2C1800), Icons.emoji_events_rounded);
      case GameResult.lose:
        return ('THẤT BẠI', const Color(0xFF94A3B8), const Color(0xFF0F172A), Icons.broken_image_rounded);
      case GameResult.draw:
        return ('HÒA CỜ', const Color(0xFF2DD4BF), const Color(0xFF0D2020), Icons.handshake_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, primary, bg, icon) = _config;
    final bool isPositive = widget.eloChange >= 0;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: bg.withOpacity(0.95),
        child: SafeArea(
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Result icon
                    Icon(icon, size: 96, color: primary),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        color: primary,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Opponent info
                    Text(
                      'vs ${widget.opponentName}',
                      style: const TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // ELO change
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isPositive ? Colors.greenAccent : Colors.redAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${isPositive ? '+' : ''}${widget.eloChange} ELO',
                            style: TextStyle(
                              color: isPositive ? Colors.greenAccent : Colors.redAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Chơi Lại', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: widget.onPlayAgain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text('Xem Lại'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: widget.onReview,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.home_outlined),
                            label: const Text('Về Trang Chủ'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: widget.onGoHome,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
