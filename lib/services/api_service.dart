import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/game_models.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://cotuong.xyz',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } catch (e) {
      debugPrint('Login Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> loginWithGoogle(String idToken) async {
    try {
      final response = await _dio.post('/api/auth/google', data: {
        'credential': idToken,
      });
      return response.data;
    } catch (e) {
      debugPrint('Google Login Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMe(String token) async {
    try {
      final response = await _dio.get('/api/auth/me', options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ));
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<List<User>> getPlayers({int limit = 100, int page = 1, String? search}) async {
    try {
      String url = '/api/players?limit=$limit&page=$page';
      if (search != null && search.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(search)}';
      }
      final response = await _dio.get(url);
      if (response.data['ok'] == true) {
        final List list = response.data['players'] ?? [];
        return list.map((e) => User.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('GetPlayers Error: $e');
    }
    return [];
  }

  Future<List<GameSummary>> getGames({int limit = 10, int? cursor}) async {
    try {
      String url = '/api/games?status=started&limit=$limit';
      if (cursor != null) url += '&cursor=$cursor';
      final response = await _dio.get(url);
      if (response.data['ok'] == true) {
        final List list = response.data['games'] ?? [];
        return list.map((e) => GameSummary.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('GetGames Error: $e');
    }
    return [];
  }

  Future<List<Puzzle>> getPuzzles({int limit = 10, int page = 1, String? query}) async {
    try {
      String url = '/api/setups/public?limit=$limit&page=$page';
      if (query != null && query.isNotEmpty) {
        url += '&q=${Uri.encodeComponent(query)}';
      }
      final response = await _dio.get(url);
      if (response.data['ok'] == true) {
        final List list = response.data['setups'] ?? [];
        return list.map((e) => Puzzle.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('GetPuzzles Error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final response = await _dio.get('/api/users/$uid/summary');
      if (response.data['ok'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('GetUserProfile Error: $e');
    }
    return null;
  }

  Future<bool> updateProfile(String token, String newName) async {
    try {
      final response = await _dio.post(
        '/api/profile',
        data: {'name': newName},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data['ok'] == true;
    } catch (e) {
      debugPrint('UpdateProfile Error: $e');
      return false;
    }
  }

  Future<List<User>> getBots() async {
    try {
      final response = await _dio.get('/api/bots/active');
      if (response.data['ok'] == true) {
        final List list = response.data['bots'] ?? [];
        return list.map((e) => User.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('GetBots Error: $e');
    }
    return [];
  }

  Future<List<Tournament>> getTournaments() async {
    try {
      final response = await _dio.get('/api/tournaments?limit=10');
      if (response.data['ok'] == true) {
        final List list = response.data['tournaments'] ?? [];
        return list.map((e) => Tournament.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('GetTournaments Error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getBestMove(List<List<String?>> board, String side) async {
    try {
      // Convert our board format to server's board object format
      List<List<Map<String, dynamic>?>> serverBoard = List.generate(10, (r) => List.generate(9, (c) {
        String? code = board[r][c];
        if (code == null) return null;
        bool isRed = code == code.toLowerCase();
        return {
          'side': isRed ? 'red' : 'black',
          'type': _charToType(code.toLowerCase()),
        };
      }));

      final response = await _dio.post('/api/engine/bestmove', data: {
        'board': serverBoard,
        'side': side,
        'movetimeMs': 1000,
      });
      return response.data;
    } catch (e) {
      debugPrint('GetBestMove Error: $e');
      return null;
    }
  }

  String _charToType(String char) {
    switch (char) {
      case 'k': return 'general';
      case 'a': return 'advisor';
      case 'b': return 'elephant';
      case 'n': return 'horse';
      case 'r': return 'chariot';
      case 'c': return 'cannon';
      case 'p': return 'soldier';
      default: return 'soldier';
    }
  }

  // ─── Tournament ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getTournamentDetail(String token, String tournamentId) async {
    try {
      final response = await _dio.get(
        '/api/tournaments/$tournamentId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      debugPrint('GetTournamentDetail Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> joinTournament(String token, String tournamentId) async {
    try {
      final response = await _dio.post(
        '/api/tournaments/$tournamentId/join',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Đăng ký thất bại';
      return {'ok': false, 'message': msg};
    } catch (e) {
      return {'ok': false, 'message': 'Lỗi kết nối'};
    }
  }
}

