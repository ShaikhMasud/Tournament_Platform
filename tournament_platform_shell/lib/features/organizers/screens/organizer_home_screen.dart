import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../../organizations/providers/organizations_providers.dart';
import '../../organizations/models/organization.dart';
import '../../tournaments/data/tournaments_repository.dart';
import '../../tournaments/providers/tournaments_providers.dart';

class OrganizerHomeScreen extends ConsumerWidget {
  const OrganizerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizations = ref.watch(organizationsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizer Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: organizations.when(
        data: (orgs) {
          if (orgs.isEmpty) {
            return _EmptyState(
              onCreateOrg: () => _showCreateOrganizationDialog(context, ref),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orgs.length,
            itemBuilder: (context, index) {
              final org = orgs[index];
              return _OrganizationCard(
                organization: org,
                onCreateTournament: () => _showCreateTournamentDialog(context, ref, org.id, org.name),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOrganizationDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Organization'),
      ),
    );
  }

  void _showCreateOrganizationDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Organization'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Organization Name',
            hintText: 'e.g., City Sports Club',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  await ref.read(organizationsProvider.notifier).createOrganization(controller.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Organization created successfully!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateTournamentDialog(BuildContext context, WidgetRef ref, String orgId, String orgName) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    String selectedSport = 'badminton_single_game';
    bool isPublic = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('New Tournament - $orgName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tournament Name *',
                    hintText: 'e.g., City Championship 2024',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Sport', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedSport,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'badminton_single_game', child: Text('Badminton (Singles)')),
                    DropdownMenuItem(value: 'badminton_double_game', child: Text('Badminton (Doubles)')),
                    DropdownMenuItem(value: 'tennis_single_game', child: Text('Tennis (Singles)')),
                    DropdownMenuItem(value: 'tennis_double_game', child: Text('Tennis (Doubles)')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => selectedSport = value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'e.g., City Sports Center',
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Public Tournament'),
                  subtitle: const Text('Allow anyone to register'),
                  value: isPublic,
                  onChanged: (value) => setState(() => isPublic = value),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a tournament name')),
                        );
                        return;
                      }
                      
                      setState(() => isLoading = true);
                      
                      try {
                        final repo = ref.read(tournamentsRepositoryProvider);
                        final tournament = await repo.createTournament(
                          organizationId: orgId,
                          name: nameController.text.trim(),
                          sport: selectedSport,
                          isPublic: isPublic,
                        );
                        
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        
                        // Refresh session to update roles
                        ref.invalidate(authControllerProvider);
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tournament "${tournament.name}" created!'),
                              action: SnackBarAction(
                                label: 'View',
                                onPressed: () {
                                  // Navigate to tournament management
                                },
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateOrg});

  final VoidCallback onCreateOrg;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.business,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Organizations Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create an organization to start managing tournaments.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onCreateOrg,
              icon: const Icon(Icons.add),
              label: const Text('Create Organization'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrganizationCard extends StatelessWidget {
  const _OrganizationCard({
    required this.organization,
    required this.onCreateTournament,
  });

  final Organization organization;
  final VoidCallback onCreateTournament;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Organization Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.business, color: colorScheme.onPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        organization.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Owner',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      // Edit organization
                    } else if (value == 'settings') {
                      // Organization settings
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'settings', child: Text('Settings')),
                  ],
                ),
              ],
            ),
          ),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: const Text('New Tournament'),
                      onPressed: onCreateTournament,
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.list, size: 18),
                      label: const Text('Tournaments'),
                      onPressed: () => context.go('/organizer/organizations/${organization.id}/tournaments?name=${Uri.encodeComponent(organization.name)}'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.people, size: 18),
                      label: const Text('Assistants'),
                      onPressed: () => context.go('/organizer/organizations/${organization.id}/assistants?name=${Uri.encodeComponent(organization.name)}'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.person_pin, size: 18),
                      label: const Text('Players'),
                      onPressed: () => context.go('/organizer/organizations/${organization.id}/players?name=${Uri.encodeComponent(organization.name)}'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.manage_accounts, size: 18),
                      label: const Text('Team'),
                      onPressed: () => context.go('/organizer/organizations/${organization.id}/team?name=${Uri.encodeComponent(organization.name)}'),
                    ),

                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
