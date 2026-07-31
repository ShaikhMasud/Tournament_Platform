import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/draw.dart';
import '../providers/draws_providers.dart';

class DrawScreen extends ConsumerWidget {
  const DrawScreen({super.key, required this.categoryId, required this.categoryName});

  final String categoryId;
  final String categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawAsync = ref.watch(drawProvider(categoryId));

    return Scaffold(
      appBar: AppBar(title: Text('Draw — $categoryName')),
      body: drawAsync.when(
        data: (draw) {
          if (draw == null) {
            return _NoDrawView(onGenerate: () => ref.read(drawProvider(categoryId).notifier).generate());
          }
          return _DrawView(draw: draw);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load draw: $e', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(drawProvider(categoryId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoDrawView extends StatelessWidget {
  const _NoDrawView({required this.onGenerate});

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(Icons.account_tree, size: 64, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            Text(
              'Draw Not Generated',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate the draw to create match pairings\nand determine the tournament bracket.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Draw'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawView extends StatelessWidget {
  const _DrawView({required this.draw});

  final Draw draw;

  int _calculateTotalRounds() {
    if (draw.slots.isEmpty) return 0;
    return draw.slots.map((s) => s.roundNumber).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final totalRounds = _calculateTotalRounds();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.layers, size: 32),
                            const SizedBox(height: 4),
                            Text('$totalRounds', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text('Rounds'),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 60, color: Colors.grey.shade300),
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.grid_view, size: 32),
                            const SizedBox(height: 4),
                            Text('${draw.slots.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text('Slots'),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 60, color: Colors.grey.shade300),
                      Expanded(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle, size: 32, color: _statusColor(draw.status)),
                            const SizedBox(height: 4),
                            Text(draw.status.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            const Text('Status'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Bracket Section
          Text('Tournament Bracket', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          
          if (draw.slots.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.sports, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('No matches in draw yet'),
                    ],
                  ),
                ),
              ),
            )
          else
            ...List.generate(totalRounds, (roundIndex) {
              final round = totalRounds - roundIndex;
              final roundSlots = draw.slots.where((s) => s.roundNumber == round).toList()
                ..sort((a, b) => a.slotPosition.compareTo(b.slotPosition));
              
              return _RoundView(round: round, slots: roundSlots, totalRounds: totalRounds);
            }),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'finalized':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class _RoundView extends StatelessWidget {
  const _RoundView({required this.round, required this.slots, required this.totalRounds});

  final int round;
  final List<DrawSlot> slots;
  final int totalRounds;

  String _roundName() {
    if (round == totalRounds) return 'Final';
    if (round == totalRounds - 1) return 'Semi-Final';
    if (round == totalRounds - 2) return 'Quarter-Final';
    return 'Round $round';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: round == totalRounds ? Colors.amber.shade100 : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _roundName(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: round == totalRounds ? Colors.amber.shade900 : Colors.blue.shade900,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) => _MatchSlotCard(slot: slot)).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _MatchSlotCard extends StatelessWidget {
  const _MatchSlotCard({required this.slot});

  final DrawSlot slot;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Match ${slot.slotPosition}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _PlayerEntry(entry: slot.entry1, isWinner: slot.winnerEntryId == slot.entry1?.id),
            const Divider(height: 8),
            _PlayerEntry(entry: slot.entry2, isWinner: slot.winnerEntryId == slot.entry2?.id),
          ],
        ),
      ),
    );
  }
}

class _PlayerEntry extends StatelessWidget {
  const _PlayerEntry({required this.entry, required this.isWinner});

  final DrawEntry? entry;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return const Text('BYE', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic));
    }
    return Row(
      children: [
        if (isWinner) ...[
          const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            entry!.displayName,
            style: TextStyle(
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
