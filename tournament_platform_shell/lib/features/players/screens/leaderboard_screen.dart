import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  final String tournamentId;
  final String tournamentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // TODO: Fetch leaderboard data from API
    final leaderboardData = [
      _LeaderboardEntry(rank: 1, playerName: 'Player A', points: 150, matchesPlayed: 5, matchesWon: 5),
      _LeaderboardEntry(rank: 2, playerName: 'Player B', points: 120, matchesPlayed: 5, matchesWon: 4),
      _LeaderboardEntry(rank: 3, playerName: 'Player C', points: 90, matchesPlayed: 5, matchesWon: 3),
      _LeaderboardEntry(rank: 4, playerName: 'Player D', points: 60, matchesPlayed: 5, matchesWon: 2),
      _LeaderboardEntry(rank: 5, playerName: 'Player E', points: 30, matchesPlayed: 5, matchesWon: 1),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard - $tournamentName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/player/home'),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leaderboardData.length,
        itemBuilder: (context, index) {
          final entry = leaderboardData[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: entry.rank <= 3 ? _getRankColor(entry.rank).withOpacity(0.1) : null,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getRankColor(entry.rank),
                child: Text(
                  '#${entry.rank}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                entry.playerName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${entry.matchesWon} wins / ${entry.matchesPlayed} played'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${entry.points} pts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }
}

class _LeaderboardEntry {
  final int rank;
  final String playerName;
  final int points;
  final int matchesPlayed;
  final int matchesWon;

  _LeaderboardEntry({
    required this.rank,
    required this.playerName,
    required this.points,
    required this.matchesPlayed,
    required this.matchesWon,
  });
}
