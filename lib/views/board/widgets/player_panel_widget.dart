import 'package:flutter/material.dart';

/// Player info panel — shows avatar, name, ELO, side badge, and turn indicator.
class PlayerPanelWidget extends StatelessWidget {
  final String side;
  final Map<String, dynamic> playersInfo;
  final String currentSide;
  final String? mySide;

  const PlayerPanelWidget({
    super.key,
    required this.side,
    required this.playersInfo,
    required this.currentSide,
    this.mySide,
  });

  @override
  Widget build(BuildContext context) {
    final info = playersInfo[side];
    final bool isMyTurn = currentSide == side;
    final bool isMySide = mySide == side;

    String name = 'Trống';
    String elo = '';
    String? avatar;

    if (info is String) {
      name = info;
    } else if (info is Map) {
      name = info['name'] ?? 'Kỳ thủ';
      elo = info['elo']?.toString() ?? '1200';
      avatar = info['avatar'] ?? info['picture'];
    }

    final String fullAvatarUrl = (avatar != null && avatar.startsWith('/'))
        ? 'https://cotuong.xyz$avatar'
        : (avatar ?? '');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMyTurn ? const Color(0xFF4A3428) : const Color(0xFF2C1810),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMyTurn ? const Color(0xFFF59E0B) : Colors.white10,
          width: isMyTurn ? 2 : 1,
        ),
        boxShadow: isMyTurn
            ? [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          // Avatar with turn indicator dot
          Stack(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: side == 'red' ? Colors.redAccent : Colors.black87,
                    width: 2,
                  ),
                  image: fullAvatarUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(fullAvatarUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: fullAvatarUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.white54, size: 30)
                    : null,
              ),
              if (isMyTurn)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.timer, size: 12, color: Colors.black),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Name + ELO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: isMyTurn ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isMySide)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Bạn',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  'Elo: $elo',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          // Side badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: side == 'red'
                  ? Colors.red.withOpacity(0.2)
                  : Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: side == 'red' ? Colors.red : Colors.grey,
                width: 1,
              ),
            ),
            child: Text(
              side == 'red' ? 'ĐỎ' : 'ĐEN',
              style: TextStyle(
                color: side == 'red' ? Colors.redAccent : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
