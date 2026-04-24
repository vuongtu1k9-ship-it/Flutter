import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// SocketService with exponential backoff reconnection logic.
/// Retries: 1s → 2s → 4s → 8s → 16s → max 30s (5 attempts max).
class SocketService {
  io.Socket? _socket;
  String? _authToken;

  bool _isIntentionalDisconnect = false;
  int _retryCount = 0;
  static const int _maxRetries = 5;
  static const int _maxBackoffSeconds = 30;

  Timer? _reconnectTimer;

  // Reconnecting state callback
  void Function(int attempt, int maxAttempts)? onReconnecting;
  void Function()? onReconnected;
  void Function()? onReconnectFailed;

  // ─── Connect ──────────────────────────────────────────────────────────────

  void connect(String token) {
    _authToken = token;
    _isIntentionalDisconnect = false;
    _retryCount = 0;
    _createSocket();
  }

  void _createSocket() {
    _socket?.dispose();

    _socket = io.io('https://cotuong.xyz', io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': _authToken})
      .disableAutoConnect()
      .build());

    _socket!.onConnect((_) {
      _retryCount = 0;
      _reconnectTimer?.cancel();
      onReconnected?.call();
    });

    _socket!.onDisconnect((_) {
      if (!_isIntentionalDisconnect) {
        _scheduleReconnect();
      }
    });

    _socket!.onConnectError((_) {
      if (!_isIntentionalDisconnect) {
        _scheduleReconnect();
      }
    });

    _socket!.connect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    if (_retryCount >= _maxRetries) {
      onReconnectFailed?.call();
      return;
    }

    _retryCount++;
    final delaySeconds = (_maxBackoffSeconds < (1 << _retryCount))
        ? _maxBackoffSeconds
        : (1 << _retryCount); // 2, 4, 8, 16, 30

    onReconnecting?.call(_retryCount, _maxRetries);

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isIntentionalDisconnect) {
        _createSocket();
      }
    });
  }

  // ─── Disconnect ───────────────────────────────────────────────────────────

  void disconnect() {
    _isIntentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _socket?.disconnect();
  }

  void dispose() {
    _isIntentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _socket?.dispose();
  }

  // ─── Room ─────────────────────────────────────────────────────────────────

  void joinRoom(String roomId, Function(dynamic) onAck) {
    _socket?.emitWithAck('room:join', {'roomId': roomId}, ack: onAck);
  }

  void watchRoom(String roomId, Function(dynamic) onAck) {
    _socket?.emitWithAck('room:watch', {'roomId': roomId}, ack: onAck);
  }

  void createRoom(Map<String, dynamic> config, Function(dynamic) onAck) {
    _socket?.emitWithAck('room:create', config, ack: onAck);
  }

  // ─── Game ─────────────────────────────────────────────────────────────────

  void sendMove(String roomId, Map<String, int> from, Map<String, int> to, Function(dynamic) onAck) {
    _socket?.emitWithAck('game:move', {
      'roomId': roomId,
      'move': {'from': from, 'to': to},
    }, ack: onAck);
  }

  void onGameMoved(Function(dynamic) callback) {
    _socket?.on('game:move', callback);
  }

  void onGameStarted(Function(dynamic) callback) {
    _socket?.on('game:started', callback);
  }

  void onGameOver(Function(dynamic) callback) {
    _socket?.on('game:over', callback);
  }

  // ─── Presence / Lobby ─────────────────────────────────────────────────────

  void onPresenceUpdate(Function(dynamic) callback) {
    _socket?.on('presence:update', callback);
  }

  void onPresenceList(Function(dynamic) callback) {
    _socket?.on('presence:list', callback);
  }

  void requestPresenceList() {
    _socket?.emit('presence:list');
  }

  void onLobbyUpdate(Function(dynamic) callback) {
    _socket?.on('lobby:update', callback);
  }

  void onRoomPlayers(Function(dynamic) callback) {
    _socket?.on('room:players', callback);
  }

  // ─── Challenge ────────────────────────────────────────────────────────────

  void onChallengeReceived(Function(dynamic) callback) {
    _socket?.on('challenge:received', callback);
  }

  void onChallengeAccepted(Function(dynamic) callback) {
    _socket?.on('challenge:accepted', callback);
  }

  void onChallengeError(Function(dynamic) callback) {
    _socket?.on('challenge:error', callback);
  }

  void onChallengeStatus(Function(dynamic) callback) {
    _socket?.on('challenge:status', callback);
  }

  void onChallengeCanceled(Function(dynamic) callback) {
    _socket?.on('challenge:canceled', callback);
  }

  void sendChallenge(String targetUid, String targetName) {
    _socket?.emit('challenge:send', {
      'targetUid': targetUid,
      'targetName': targetName,
      'challengeConfig': {'mode': 'standard'},
    });
  }

  void replyToChallenge(String challengeId, String status) {
    _socket?.emit('challenge:reply', {
      'challengeId': challengeId,
      'status': status,
    });
  }

  // ─── Engine ───────────────────────────────────────────────────────────────

  void requestEngineBestMove(Map<String, dynamic> params, Function(dynamic) onAck) {
    _socket?.emitWithAck('engine:bestmove', params, ack: onAck);
  }

  // ─── Chat ─────────────────────────────────────────────────────────────────

  void sendChatMessage(String roomId, String message) {
    _socket?.emit('chat:send', {'roomId': roomId, 'message': message});
  }

  void onChatMessage(Function(dynamic) callback) {
    _socket?.on('chat:message', callback);
  }

  void sendLobbyMessage(String message) {
    _socket?.emit('lobby:chat:send', {'message': message});
  }

  void onLobbyMessage(Function(dynamic) callback) {
    _socket?.on('lobby:chat:message', callback);
  }

  // ─── Bot ──────────────────────────────────────────────────────────────────

  void onBotTaunt(Function(dynamic) callback) {
    _socket?.on('bot:taunt', callback);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void off(String event) {
    _socket?.off(event);
  }

  void clearGameListeners() {
    _socket?.off('game:move');
    _socket?.off('game:started');
    _socket?.off('game:over');
  }

  void clearLobbyListeners() {
    _socket?.off('presence:update');
    _socket?.off('lobby:update');
    _socket?.off('challenge:received');
    _socket?.off('challenge:accepted');
    _socket?.off('lobby:chat:message');
  }

  bool get isConnected => _socket?.connected ?? false;
}
