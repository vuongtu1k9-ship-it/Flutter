import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'pikafish_ffi.dart';

class PikafishManager {
  static const String engineUrl = 'http://10.0.2.2:8080/api/engine/download-info'; // Emulator to localhost
  
  static Future<bool> isEngineDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('pikafish_ready') ?? false;
  }

  static Future<void> checkAndDownloadEngine({
    required Function(double) onProgress,
    required Function() onComplete,
    required Function(String) onError,
  }) async {
    try {
      if (await isEngineDownloaded()) {
        onComplete();
        return;
      }

      final dio = Dio();
      // 1. Fetch metadata
      final infoResponse = await dio.get(engineUrl);
      if (infoResponse.data['ok'] != true) {
        onError('Không lấy được thông tin Engine từ máy chủ.');
        return;
      }
      
      final downloadUrl = 'http://10.0.2.2:8080' + infoResponse.data['url'];
      
      // 2. Prepare paths
      final dir = await getApplicationDocumentsDirectory();
      final zipPath = '${dir.path}/pikafish-android.zip';
      final extractDir = '${dir.path}/pikafish_engine';

      // 3. Download ZIP
      await dio.download(
        downloadUrl,
        zipPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      // 4. Extract ZIP in Isolate
      await compute(_extractZip, {'zipPath': zipPath, 'extractDir': extractDir});
      
      // 5. Cleanup and Mark Ready
      final zipFile = File(zipPath);
      if (await zipFile.exists()) {
        await zipFile.delete();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pikafish_ready', true);
      await prefs.setString('pikafish_path', extractDir);

      onComplete();
    } catch (e) {
      onError('Lỗi tải Engine: $e');
    }
  }

  static void _extractZip(Map<String, String> args) {
    final bytes = File(args['zipPath']!).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        File('${args['extractDir']}/$filename')
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory('${args['extractDir']}/$filename').createSync(recursive: true);
      }
    }
  }

  static Future<void> initEngineIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    bool isReady = prefs.getBool('pikafish_ready') ?? false;
    if (isReady) {
      String extractDir = prefs.getString('pikafish_path') ?? '';
      if (extractDir.isNotEmpty) {
        String soPath = '$extractDir/libpikafish.so';
        if (File(soPath).existsSync()) {
          PikafishFFI.loadLibrary(soPath);
          PikafishFFI.sendCommand('uci');
          PikafishFFI.sendCommand('isready');
        }
      }
    }
  }

  static Future<Map<String, dynamic>?> getBestMove(List<List<String?>> board, String side) async {
    await initEngineIfNeeded();
    // Convert board to FEN...
    // For now, this is a placeholder returning null. In full implementation, we pass FEN to FFI, wait for output.
    PikafishFFI.sendCommand('go depth 10');
    await Future.delayed(const Duration(milliseconds: 1000));
    String out = PikafishFFI.readOutput();
    // Parse out for bestmove...
    return null; // Fallback to Lightweight if not parsed yet
  }
}
