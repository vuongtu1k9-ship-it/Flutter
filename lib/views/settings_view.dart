import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../utils/pikafish_manager.dart';

class SettingsView extends StatefulWidget {
  final ApiService apiService;
  final Map<String, dynamic> currentUserData;

  const SettingsView({
    super.key,
    required this.apiService,
    required this.currentUserData,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late TextEditingController _nameController;
  bool _isSaving = false;
  final AuthService _authService = AuthService();
  
  bool _soundEnabled = true;
  bool _vibrateEnabled = true;
  String _selectedEngine = 'lightweight';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUserData['name'] ?? '');
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('soundEnabled') ?? true;
      _vibrateEnabled = prefs.getBool('vibrateEnabled') ?? true;
      _selectedEngine = prefs.getString('offlineEngine') ?? 'lightweight';
    });
  }

  Future<void> _setEngine(String val) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (val == 'pikafish') {
      bool isReady = prefs.getBool('pikafish_ready') ?? false;
      if (!isReady) {
        // Show download dialog
        _showDownloadDialog();
        return; // Don't set until download completes
      }
    }

    await prefs.setString('offlineEngine', val);
    setState(() => _selectedEngine = val);
  }

  void _showDownloadDialog() {
    double progress = 0.0;
    String status = 'Đang khởi tạo...';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Trigger download on first build
            if (progress == 0.0 && status == 'Đang khởi tạo...') {
              status = 'Đang tải...';
              PikafishManager.checkAndDownloadEngine(
                onProgress: (p) {
                  setStateDialog(() {
                    progress = p;
                  });
                },
                onComplete: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('offlineEngine', 'pikafish');
                  setState(() => _selectedEngine = 'pikafish');
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Tải Engine Pikafish thành công!')),
                  );
                },
                onError: (err) {
                  setStateDialog(() => status = err);
                  Future.delayed(const Duration(seconds: 3), () {
                    if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                  });
                },
              );
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF2C1810),
              title: const Text('Tải Pikafish Engine', style: TextStyle(color: Colors.amber)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(status, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: progress > 0 ? progress : null,
                    backgroundColor: Colors.white24,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 10),
                  Text('${(progress * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _toggleSound(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', val);
    setState(() => _soundEnabled = val);
  }

  Future<void> _toggleVibrate(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrateEnabled', val);
    setState(() => _vibrateEnabled = val);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên phải có ít nhất 2 ký tự')),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    final token = widget.currentUserData['token'] ?? ''; 
    final success = await widget.apiService.updateProfile(token, newName);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        widget.currentUserData['name'] = newName; 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật tên thành công!')),
        );
        Navigator.pop(context, true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thất bại. Vui lòng thử lại.')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Cài đặt'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hồ sơ cá nhân', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Tên hiển thị', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.person, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 48),
            
            const Text('Tùy chỉnh trong trận', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Âm thanh', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Phát âm thanh khi đi cờ', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    secondary: Icon(Icons.volume_up, color: _soundEnabled ? Colors.green : Colors.white54),
                    value: _soundEnabled,
                    activeColor: Colors.green,
                    onChanged: _toggleSound,
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  SwitchListTile(
                    title: const Text('Rung (Haptics)', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Rung thiết bị khi đến lượt', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    secondary: Icon(Icons.vibration, color: _vibrateEnabled ? Colors.amber : Colors.white54),
                    value: _vibrateEnabled,
                    activeColor: Colors.amber,
                    onChanged: _toggleVibrate,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
            const Text('Cấu hình AI (Offline Mode)', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lựa chọn Engine AI', style: TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF2C1810),
                    value: _selectedEngine,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'lightweight', child: Text('Nhẹ (Mặc định - Tích hợp sẵn)')),
                      DropdownMenuItem(value: 'pikafish', child: Text('Pikafish (Nặng - Sắp ra mắt)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _setEngine(val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pikafish là Engine siêu mạnh cần tải thêm dữ liệu (khoảng 20MB).',
                    style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
                  ),
                  if (_selectedEngine == 'pikafish') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue, size: 16),
                              SizedBox(width: 8),
                              Text('Mã nguồn mở (GPLv3)', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pikafish là phần mềm nguồn mở được cấp phép theo giấy phép GNU GPLv3. Xin trân trọng cảm ơn đội ngũ phát triển Pikafish.',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          TextButton(
                            onPressed: () {
                              showDialog(context: context, builder: (_) => AlertDialog(
                                title: const Text('Thông tin Giấy phép Pikafish'),
                                content: const SingleChildScrollView(
                                  child: Text('Dự án này sử dụng Pikafish (https://github.com/official-pikafish/Pikafish).\n\nPikafish được cấp phép theo GNU General Public License v3.0.\nMã nguồn đã được sửa đổi để hỗ trợ chạy trên ứng dụng này thông qua FFI Bridge.\nMã nguồn sửa đổi có sẵn tại: https://github.com/hoanb1/Pikafish'),
                                ),
                                actions: [TextButton(onPressed: () => Navigator.pop(_), child: const Text('ĐÓNG'))],
                              ));
                            },
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            child: const Text('Xem chi tiết', style: TextStyle(color: Colors.amber, fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),

            const SizedBox(height: 48),
            const Divider(color: Colors.white10),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.redAccent)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
