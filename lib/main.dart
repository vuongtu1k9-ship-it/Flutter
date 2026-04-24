import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:xiangqi_mobile/services/socket_service.dart';
import 'package:xiangqi_mobile/services/api_service.dart';
import 'package:xiangqi_mobile/views/home_view.dart';
import 'package:xiangqi_mobile/views/login_view.dart';
import 'package:xiangqi_mobile/views/splash_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exception}');
  };
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();
  String? _authToken;
  Map<String, dynamic>? _userData;
  bool _initialized = false;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _loadStoredLogin();
  }

  Future<void> _loadStoredLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    final String? userJson = prefs.getString('user_data');

    if (token != null && userJson != null) {
      setState(() {
        _authToken = token;
        _userData = jsonDecode(userJson);
      });
      _socketService.connect(token);
    }
    setState(() {
      _initialized = true;
    });
  }

  Future<void> _onLoginSuccess(Map<String, dynamic> result) async {
    final prefs = await SharedPreferences.getInstance();
    final String token = result['token'];
    final Map<String, dynamic> user = result['user'];

    await prefs.setString('auth_token', token);
    await prefs.setString('user_data', jsonEncode(user));

    setState(() {
      _authToken = token;
      _userData = user;
    });
    _socketService.connect(token);
  }

  Future<void> _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');

    setState(() {
      _authToken = null;
      _userData = null;
    });
    _socketService.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Xiangqi Mobile',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.amber.shade700,
          secondary: Colors.redAccent,
          surface: const Color(0xFF1E1E1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: true,
        ),
        useMaterial3: true,
      ),
      home: _showSplash
          ? SplashView(onComplete: () => setState(() => _showSplash = false))
          : (_authToken == null
              ? LoginView(onLoginSuccess: _onLoginSuccess)
              : HomeView(
                  userData: _userData ?? {},
                  token: _authToken!,
                  apiService: _apiService,
                  socketService: _socketService,
                  onLogout: _onLogout,
                )),
    );
  }
}
