import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/token_storage.dart';
import '../models/match.dart';
import '../providers/matches_providers.dart';

class MatchLiveScoringScreen extends ConsumerStatefulWidget {
  const MatchLiveScoringScreen({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<MatchLiveScoringScreen> createState() => _MatchLiveScoringScreenState();
}

class _MatchLiveScoringScreenState extends ConsumerState<MatchLiveScoringScreen> {
  WebSocketChannel? _channel;
  MatchModel? _match;
  bool _isLoading = true;
  String? _error;
  int _entry1Points = 0;
  int _entry2Points = 0;
  int _version = 0;
  String? _winnerId;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    try {
      // Get token for WebSocket auth.
      // In a real app, you'd inject this via provider.
      final wsUrl = '${ApiConfig.wsBase}${ApiEndpoints.matchWebSocket(widget.matchId)}';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        _onWebSocketMessage,
        onError: (error) {
          setState(() => _error = 'WebSocket error: $error');
        },
        onDone: () {
          // Connection closed.
        },
      );

      // Send initial state request.
      _channel!.sink.add(jsonEncode({'action': 'request_state'}));
    } catch (e) {
      setState(() => _error = 'Failed to connect: $e');
    }
  }

  void _onWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final event = data['event'] as String?;

      if (event == 'state_snapshot' || event == 'score_update') {
        setState(() {
          _isLoading = false;
          _entry1Points = data['score']?['entry1_points'] as int? ?? 0;
          _entry2Points = data['score']?['entry2_points'] as int? ?? 0;
          _version = data['version'] as int? ?? 0;
          _winnerId = data['winner_entry_id'] as String?;
        });
      } else if (data['error'] != null) {
        setState(() => _error = data['error'] as String);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] as String), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // Ignore parse errors.
    }
  }

  void _incrementScore(int entry) {
    if (_winnerId != null) return; // Match already has a winner.
    if (_channel == null) return;

    final newEntry1Points = entry == 1 ? _entry1Points + 1 : _entry1Points;
    final newEntry2Points = entry == 2 ? _entry2Points + 1 : _entry2Points;

    _channel!.sink.add(jsonEncode({
      'action': 'score',
      'entry': entry,
      'version': _version,
    }));
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));

    // Sync REST state when available.
    matchAsync.whenData((match) {
      if (_isLoading && _match == null) {
        _match = match;
        _entry1Points = match.score.entry1Points;
        _entry2Points = match.score.entry2Points;
        _version = match.version;
        _winnerId = match.winnerEntryId;
        _isLoading = false;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_match?.categoryName ?? 'Live Scoring'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildScoreView(),
    );
  }

  Widget _buildScoreView() {
    return Column(
      children: [
        const SizedBox(height: 24),
        // Live indicator.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Colors.white, size: 8),
              SizedBox(width: 6),
              Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Score display.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _match?.entry1?.playerName ?? 'Player 1',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (_winnerId == _match?.entry1?.id)
                      const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '$_entry1Points',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: _winnerId == _match?.entry1?.id ? Colors.green : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_winnerId == null)
                      ElevatedButton(
                        onPressed: () => _incrementScore(1),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(100, 50),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('+1', style: TextStyle(fontSize: 24)),
                      ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('-', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _match?.entry2?.playerName ?? 'Player 2',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (_winnerId == _match?.entry2?.id)
                      const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '$_entry2Points',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: _winnerId == _match?.entry2?.id ? Colors.green : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_winnerId == null)
                      ElevatedButton(
                        onPressed: () => _incrementScore(2),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(100, 50),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('+1', style: TextStyle(fontSize: 24)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        if (_winnerId != null)
          Card(
            color: Colors.green.shade50,
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    '${_winnerId == _match?.entry1?.id ? _match?.entry1?.playerName : _match?.entry2?.playerName} wins!',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
      ],
    );
  }
}
