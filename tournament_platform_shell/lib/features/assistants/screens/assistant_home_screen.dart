import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../../auth/models/session.dart';
import '../../tournaments/providers/tournaments_providers.dart';

class AssistantHomeScreen extends ConsumerWidget {
  const AssistantHomeScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  final String tournamentId;
  final String tournamentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(tournamentDetailProvider(tournamentId));
    final selectedRole = ref.watch(selectedRoleProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Determine capabilities
    final hasEntryManagement = selectedRole?.hasCapability('entry_management') ?? false;
    final hasScheduling = selectedRole?.hasCapability('scheduling') ?? false;
    final hasScoreManagement = selectedRole?.hasCapability('score_management') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(tournamentName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load tournament: $err'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(tournamentDetailProvider(tournamentId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (tournament) {
          final hasAnyCapability = hasEntryManagement || hasScheduling || hasScoreManagement;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Capability banner if no capabilities
              if (!hasAnyCapability)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You have view-only access. Contact an organizer to request capabilities.',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),

              // Tournament overview card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${tournament.sport} · ${tournament.isPublic ? "Public" : "Private"}',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _CapabilityChip(
                            label: 'Entries',
                            enabled: hasEntryManagement,
                          ),
                          _CapabilityChip(
                            label: 'Scheduling',
                            enabled: hasScheduling,
                          ),
                          _CapabilityChip(
                            label: 'Scoring',
                            enabled: hasScoreManagement,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick actions grid
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.sports_tennis,
                      label: 'Matches',
                      onTap: () => context.push(
                        '/tournaments/$tournamentId/matches?name=${Uri.encodeComponent(tournament.name)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.picture_as_pdf,
                      label: 'Results',
                      onTap: () => context.push(
                        '/tournaments/$tournamentId/results?name=${Uri.encodeComponent(tournament.name)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.account_tree,
                      label: 'Draw',
                      onTap: null, // View only, no action needed
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Categories section (view-only baseline for all assistants)
              Text(
                'Categories',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (tournament.categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No categories yet.'),
                ),
              ...tournament.categories.map(
                (c) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    leading: const Icon(Icons.category),
                    title: Text(c.name),
                    subtitle: Text('${c.drawFormat} · capacity ${c.capacity} · ${c.status}'),
                    children: [
                      // Manage Entries - only if has capability
                      if (hasEntryManagement)
                        ListTile(
                          leading: const Icon(Icons.person_add),
                          title: const Text('Manage Entries'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(
                            '/tournaments/$tournamentId/categories/${c.id}/entries',
                          ),
                        )
                      else
                        ListTile(
                          leading: Icon(Icons.person_add, color: colorScheme.onSurfaceVariant),
                          title: Text(
                            'Manage Entries',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          trailing: const Icon(Icons.lock_outline, size: 18),
                        ),
                      // View Draw - always visible, read-only
                      ListTile(
                        leading: const Icon(Icons.account_tree),
                        title: const Text('View Draw'),
                        trailing: c.status == 'open' || c.status == 'draw_generated'
                            ? const Icon(Icons.chevron_right)
                            : Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Courts section - scheduling capability required
              Row(
                children: [
                  Text(
                    'Courts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (hasScheduling) ...[
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showAddCourtDialog(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ],
              ),
              if (!hasScheduling)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Scheduling capability required to add courts',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (tournament.courts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No courts yet.'),
                ),
              ...tournament.courts.map(
                (c) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(c.name),
                  ),
                ),
              ),
            ],
          );
        },
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

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: enabled
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: enabled
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: enabled
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDisabled = onTap == null;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: isDisabled ? colorScheme.onSurfaceVariant : null,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDisabled ? colorScheme.onSurfaceVariant : null,
                ),
              ),
              if (isDisabled) ...[
                const SizedBox(height: 4),
                Icon(
                  Icons.lock_outline,
                  size: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
