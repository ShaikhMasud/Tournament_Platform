import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/tournaments_providers.dart';

class CategoryCourtManagementScreen extends ConsumerWidget {
  const CategoryCourtManagementScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(tournamentDetailProvider(tournamentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Tournament Management')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load tournament: $err')),
        data: (tournament) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Tournament overview card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tournament.name, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text('${tournament.sport} · ${tournament.isPublic ? "Public" : "Private"}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick actions grid
              Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.sports_tennis,
                      label: 'Matches',
                      onTap: () => context.push('/tournaments/$tournamentId/matches?name=${Uri.encodeComponent(tournament.name)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.picture_as_pdf,
                      label: 'Results',
                      onTap: () => context.push('/tournaments/$tournamentId/results?name=${Uri.encodeComponent(tournament.name)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.group,
                      label: 'Team',
                      onTap: () => context.push('/tournaments/$tournamentId/team?name=${Uri.encodeComponent(tournament.name)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Categories section
              Row(
                children: [
                  Text('Categories', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showAddCategoryDialog(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              if (tournament.categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No categories yet. Add one to get started.'),
                ),
              ...tournament.categories.map(
                (c) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    leading: const Icon(Icons.category),
                    title: Text(c.name),
                    subtitle: Text('${c.drawFormat} · capacity ${c.capacity} · ${c.status}'),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_add),
                        title: const Text('Manage Entries'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/tournaments/$tournamentId/categories/${c.id}/entries'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.account_tree),
                        title: const Text('View Draw'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: c.status == 'open' || c.status == 'draw_generated'
                            ? () => context.push('/tournaments/$tournamentId/categories/${c.id}/draw?name=${Uri.encodeComponent(c.name)}')
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 32),

              // Courts section
              Row(
                children: [
                  Text('Courts', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showAddCourtDialog(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              if (tournament.courts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No courts yet. Add courts to schedule matches.'),
                ),
              ...tournament.courts.map(
                (c) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(c.name),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
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

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
