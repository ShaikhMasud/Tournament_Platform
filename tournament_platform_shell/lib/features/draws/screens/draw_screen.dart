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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_tree_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No draw has been generated yet.', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
            'Generate the draw to create match pairings.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Draw'),
          ),
        ],
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.layers),
                      const SizedBox(width: 8),
                      Text('Total Rounds: $totalRounds', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.account_tree),
                      const SizedBox(width: 8),
                      Text('Slots: ${draw.slots.length}', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(draw.status.toUpperCase()),
                    backgroundColor: _statusColor(draw.status),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Match brackets will appear here once matches are generated.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade100;
      case 'finalized':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade200;
    }
  }
}
