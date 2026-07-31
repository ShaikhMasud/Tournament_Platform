import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/api_config.dart';
import 'token_storage.dart';

enum SocketConnectionState { connecting, live, reconnecting, stale, unavailable }

/// One instance per open match (scorer or spectator view). Matches the
/// connecting/live/reconnecting/stale/unavailable states from the UI plan.
/// Reconnect logic re-fetches authoritative state before flipping back to
/// "live" — never trust the socket reopening alone as "synced".
class MatchSocketClient {
  MatchSocketClient({required this.matchId, required this.tokenStorage});

  final String matchId;
  final TokenStorage tokenStorage;

  WebSocketChannel? _channel;
  final _stateController = StreamController<SocketConnectionState>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _staleTimer;
  int _retryAttempt = 0;

  Stream<SocketConnectionState> get connectionState => _stateController.stream;
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  Future<void> connect() async {
    _emit(SocketConnectionState.connecting);
    final token = await tokenStorage.accessToken;
    final uri = Uri.parse('${ApiConfig.wsBase}/ws/matches/$matchId/?token=$token');

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _retryAttempt = 0;
      _emit(SocketConnectionState.live);
      _resetStaleTimer();

      _channel!.stream.listen(
        (raw) {
          _resetStaleTimer();
          final data = jsonDecode(raw as String) as Map<String, dynamic>;
          _messageController.add(data);
          if (_stateController.hasListener) _emit(SocketConnectionState.live);
        },
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
      );
    } catch (_) {
      _handleDisconnect();
    }
  }

  /// Score submissions carry `based_on_version` so the server can reject
  /// stale/duplicate updates — see Match.version in the Django plan.
  void sendScoreUpdate(Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode({'type': 'score_update', ...payload}));
  }

  void _resetStaleTimer() {
    _staleTimer?.cancel();
    // No message for 15s while notionally "live" -> flag as stale so the UI
    // can warn the user, without tearing down the connection outright.
    _staleTimer = Timer(const Duration(seconds: 15), () {
      _emit(SocketConnectionState.stale);
    });
  }

  void _handleDisconnect() {
    _staleTimer?.cancel();
    _retryAttempt++;
    if (_retryAttempt > 5) {
      _emit(SocketConnectionState.unavailable);
      return;
    }
    _emit(SocketConnectionState.reconnecting);
    final backoff = Duration(seconds: _retryAttempt * 2);
    Timer(backoff, connect);
  }

  void _emit(SocketConnectionState state) {
    if (!_stateController.isClosed) _stateController.add(state);
  }

  void dispose() {
    _staleTimer?.cancel();
    _channel?.sink.close();
    _stateController.close();
    _messageController.close();
  }
}
