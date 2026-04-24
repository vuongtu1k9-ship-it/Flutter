import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'offline_board_view.dart';
import 'home_view.dart';

class LoginView extends StatefulWidget {
  final Function(Map<String, dynamic> result) onLoginSuccess;

  const LoginView({super.key, required this.onLoginSuccess});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signInWithGoogle();
      if (result != null && result['token'] != null) {
        widget.onLoginSuccess(result);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thất bại')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E110A), Color(0xFF0F0804)],
          ),
        ),
        child: Stack(
          children: [
            // Abstract Asian-inspired background elements
            Positioned(
              top: -50,
              right: -50,
              child: Opacity(
                opacity: 0.1,
                child: Icon(Icons.change_history, size: 400, color: Colors.amber),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -50,
              child: Opacity(
                opacity: 0.05,
                child: Icon(Icons.circle_outlined, size: 300, color: Colors.redAccent),
              ),
            ),
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.amber)
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Hero(
                            tag: 'app_logo',
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.03),
                                border: Border.all(color: Colors.amber.withOpacity(0.2), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.05),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/icon.png',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 80,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'COTUONG.XYZ',
                            style: TextStyle(
                              fontSize: 32,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'TINH HOA CỜ TƯỚNG VIỆT',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.withOpacity(0.6),
                              letterSpacing: 4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 64),
                          
                          // Glassmorphism Login Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withOpacity(0.05),
                              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _handleGoogleSignIn,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(
                                      'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                      width: 24,
                                      height: 24,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.login, color: Colors.white),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'Đăng nhập bằng Google',
                                      style: TextStyle(
                                        fontSize: 16, 
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Offline Mode Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withOpacity(0.02),
                              border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _isLoading ? null : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const OfflineBoardView(playVsBot: true),
                                    ),
                                  );
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.offline_bolt, color: Colors.amber, size: 24),
                                    SizedBox(width: 12),
                                    Text(
                                      'CHƠI OFFLINE (Bản Nhẹ)',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withOpacity(0.4),
                            ),
                            child: const Text(
                              'Chính sách bảo mật',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
