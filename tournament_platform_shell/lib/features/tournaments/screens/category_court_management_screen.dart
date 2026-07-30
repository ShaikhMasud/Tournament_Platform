import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tournaments_providers.dart';

class CategoryCourtManagementScreen extends ConsumerWidget {
  const CategoryCourtManagementScreen({super.key, required this.tournamentId});

  final String tournamentId; 

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(tournamentDetailProvider(tournamentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Categories & Courts')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load tournament: $err')),
        data: (tournament) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Categories', style: Theme.of(context).textTheme.titleMedium),
              if (tournament.categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No categories yet.'),
                ),
              ...tournament.categories.map(
                (c) => ListTile(
                  title: Text(c.name),
                  subtitle: Text('${c.drawFormat} · capacity ${c.capacity} · ${c.status}'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showAddCategoryDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add category'),
              ),
              const Divider(height: 32),
              Text('Courts', style: Theme.of(context).textTheme.titleMedium),
              if (tournament.courts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No courts yet.'),
                ),
              ...tournament.courts.map((c) => ListTile(title: Text(c.name))),
              OutlinedButton.icon(
                onPressed: () => _showAddCourtDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add court'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final capacityController = TextEditingController(text: '16');
    // Knockout is the only format the scaffold's Match model supports
    // per the plan's Section 2 decision.
    const drawFormat = 'knockout';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Category name'),
            ),
            TextField(
              controller: capacityController,
              decoration: const InputDecoration(labelText: 'Capacity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(tournamentDetailProvider(tournamentId).notifier).addCategory(
                    name: nameController.text.trim(),
                    drawFormat: drawFormat,
                    capacity: int.tryParse(capacityController.text.trim()) ?? 16,
                  );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddCourtDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add court'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Court name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(tournamentDetailProvider(tournamentId).notifier)
                  .addCourt(name: nameController.text.trim());
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
