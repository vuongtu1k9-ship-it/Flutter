import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'settings_view.dart';

class ProfileView extends StatefulWidget {
  final String uid;
  final ApiService apiService;
  final Map<String, dynamic> currentUserData;

  const ProfileView({
    super.key,
    required this.uid,
    required this.apiService,
    required this.currentUserData,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await widget.apiService.getUserProfile(widget.uid);
    if (mounted) {
      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    }
  }

  void _goToSettings() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsView(
          apiService: widget.apiService,
          currentUserData: widget.currentUserData,
        ),
      ),
    );
    if (updated == true) {
      _loadProfile(); // reload profile if name changed
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.uid == widget.currentUserData['uid'];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isMe ? 'Hồ sơ của tôi' : 'Hồ sơ kỳ thủ'),
        actions: [
          if (isMe)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: _goToSettings,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profileData == null || _profileData!['user'] == null
              ? const Center(child: Text('Không tìm thấy thông tin', style: TextStyle(color: Colors.white54)))
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    final user = _profileData!['user'];
    final int elo = _profileData!['elo'] ?? 1200;
    final int rank = _profileData!['rank'] ?? 0;
    final int gamesPlayed = _profileData!['gamesPlayed'] ?? 0;
    
    final String? pic = user['picture'];
    final String fullPic = (pic != null && pic.startsWith('/')) 
        ? 'https://cotuong.xyz$pic' 
        : (pic ?? '');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.amber.shade200,
              child: CircleAvatar(
                radius: 56,
                backgroundImage: fullPic.isNotEmpty ? NetworkImage(fullPic) : null,
                backgroundColor: Colors.grey.shade800,
                child: fullPic.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.white54) : null,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            user['name'] ?? 'Kỳ thủ ẩn danh',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'UID: ${user['uid']}',
            style: const TextStyle(fontSize: 14, color: Colors.white54),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Elo', '$elo', Icons.star, Colors.amber),
              _buildStatCard('Thứ hạng', '#$rank', Icons.emoji_events, Colors.orange),
              _buildStatCard('Đã chơi', '$gamesPlayed', Icons.videogame_asset, Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 40),
          if (widget.uid == widget.currentUserData['uid'])
            ElevatedButton.icon(
              onPressed: _goToSettings,
              icon: const Icon(Icons.edit),
              label: const Text('Chỉnh sửa hồ sơ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
