import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_endpoints.dart';
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
      final wsUrl = '${ApiConfig.wsBase}${ApiEndpoints.matchWebSocket(widget.matchId)}';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        _onWebSocketMessage,
        onError: (error) {
          setState(() => _error = 'WebSocket error: $error');
        },
        onDone: () {},
      );

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
    } catch (e) {}
  }

  void _incrementScore(int entry) {
    if (_winnerId != null) return;
    if (_channel == null) return;

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
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildScoreView(),
    );
  }

  Widget _buildScoreView() {
    return Column(
      children: [
        // Header with LIVE indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: Colors.red,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, color: Colors.white, size: 12),
              SizedBox(width: 8),
              Text(
                'LIVE MATCH',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 24),
              
              // Score Display
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Player 1
                    _PlayerCard(
                      name: _match?.entry1?.playerName ?? 'Player 1',
                      points: _entry1Points,
                      isWinner: _winnerId == _match?.entry1?.id,
                      isEntry1: true,
                      onIncrement: _winnerId == null ? () => _incrementScore(1) : null,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // VS Divider
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Player 2
                    _PlayerCard(
                      name: _match?.entry2?.playerName ?? 'Player 2',
                      points: _entry2Points,
                      isWinner: _winnerId == _match?.entry2?.id,
                      isEntry1: false,
                      onIncrement: _winnerId == null ? () => _incrementScore(2) : null,
                    ),
                  ],
                ),
              ),
              
              // Winner Banner
              if (_winnerId != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        'WINNER: ${_winnerId == _match?.entry1?.id ? _match?.entry1?.playerName : _match?.entry2?.playerName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Error display
              if (_error != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.name,
    required this.points,
    required this.isWinner,
    required this.isEntry1,
    this.onIncrement,
  });

  final String name;
  final int points;
  final bool isWinner;
  final bool isEntry1;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      elevation: isWinner ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isWinner
            ? const BorderSide(color: Colors.amber, width: 3)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: isEntry1 ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                if (isWinner) ...[
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: isEntry1 ? TextAlign.left : TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isEntry1) _ScoreButton(points: points, onTap: onIncrement),
                if (!isEntry1) _ScoreButton(points: points, onTap: onIncrement),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreButton extends StatelessWidget {
  const _ScoreButton({required this.points, this.onTap});

  final int points;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 80,
      decoration: BoxDecoration(
        color: onTap != null ? Colors.blue : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: onTap != null
                ? const Icon(Icons.add, color: Colors.white, size: 40)
                : Text(
                    '$points',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
