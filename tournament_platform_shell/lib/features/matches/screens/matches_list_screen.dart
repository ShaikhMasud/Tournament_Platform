import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/match.dart';
import '../providers/matches_providers.dart';

class MatchesListScreen extends ConsumerWidget {
  const MatchesListScreen({
    super.key,
    required this.tournamentId,
    this.categoryId,
    this.status,
  });

  final String tournamentId;
  final String? categoryId;
  final String? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = MatchesFilter(
      tournamentId: tournamentId,
      categoryId: categoryId,
      status: status,
    );
    final matchesAsync = ref.watch(matchesListProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(matchesListProvider(filter)),
          ),
        ],
      ),
      body: matchesAsync.when(
        data: (matches) {
          if (matches.isEmpty) {
            return const Center(
              child: Text('No matches found.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(matchesListProvider(filter).notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                return _MatchCard(
                  match: match,
                  onTap: () => context.push('/matches/${match.id}/live'),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(matchesListProvider(filter)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.onTap});

  final MatchModel match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusChip(status: match.status),
                  const Spacer(),
                  Text(
                    'Round ${match.roundNumber}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  if (match.court != null) ...[
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(match.court!.name, style: const TextStyle(color: Colors.grey)),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              _PlayerRow(
                entry: match.entry1,
                points: match.score.entry1Points,
                isWinner: match.winnerEntryId == match.entry1?.id,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Divider(height: 1),
              ),
              _PlayerRow(
                entry: match.entry2,
                points: match.score.entry2Points,
                isWinner: match.winnerEntryId == match.entry2?.id,
              ),
              if (match.categoryName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  match.categoryName,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.entry,
    required this.points,
    required this.isWinner,
  });

  final MatchEntry? entry;
  final int points;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isWinner) const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
        if (isWinner) const SizedBox(width: 4),
        Expanded(
          child: Text(
            entry?.playerName ?? 'BYE',
            style: TextStyle(
              fontSize: 15,
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          '$points',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isWinner ? Colors.green : null,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _colorFor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Color _colorFor(String s) {
    switch (s) {
      case 'pending':
        return Colors.grey;
      case 'scheduled':
        return Colors.blue;
      case 'live':
        return Colors.red;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
