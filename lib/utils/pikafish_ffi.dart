import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef PikafishInitC = ffi.Void Function();
typedef PikafishInitDart = void Function();

typedef PikafishCommandC = ffi.Void Function(ffi.Pointer<Utf8> cmd);
typedef PikafishCommandDart = void Function(ffi.Pointer<Utf8> cmd);

typedef PikafishReadC = ffi.Int32 Function(ffi.Pointer<Utf8> buffer, ffi.Int32 maxLen);
typedef PikafishReadDart = int Function(ffi.Pointer<Utf8> buffer, int maxLen);

class PikafishFFI {
  static late ffi.DynamicLibrary _lib;
  static late PikafishInitDart _init;
  static late PikafishCommandDart _command;
  static late PikafishReadDart _read;

  static bool _initialized = false;

  static void loadLibrary(String libPath) {
    if (_initialized) return;
    
    // Nạp thư viện .so từ Internal Storage
    _lib = ffi.DynamicLibrary.open(libPath);

    _init = _lib.lookupFunction<PikafishInitC, PikafishInitDart>('pikafish_init');
    _command = _lib.lookupFunction<PikafishCommandC, PikafishCommandDart>('pikafish_command');
    _read = _lib.lookupFunction<PikafishReadC, PikafishReadDart>('pikafish_read');
    
    _init(); // Khởi động Pikafish C++ Thread
    _initialized = true;
  }

  static void sendCommand(String cmd) {
    if (!_initialized) return;
    final ptr = cmd.toNativeUtf8();
    _command(ptr);
    malloc.free(ptr);
  }

  static String readOutput() {
    if (!_initialized) return "";
    final ptr = malloc.allocate<Utf8>(4096);
    final len = _read(ptr, 4096);
    String result = "";
    if (len > 0) {
      result = ptr.toDartString();
    }
    malloc.free(ptr);
    return result;
  }
}
