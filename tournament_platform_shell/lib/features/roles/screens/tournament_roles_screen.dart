import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/roles_repository.dart';
import '../models/tournament_role.dart';
import '../providers/roles_providers.dart';

class TournamentRolesScreen extends ConsumerStatefulWidget {
  const TournamentRolesScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  final String tournamentId;
  final String tournamentName;

  @override
  ConsumerState<TournamentRolesScreen> createState() => _TournamentRolesScreenState();
}

class _TournamentRolesScreenState extends ConsumerState<TournamentRolesScreen> {
  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(tournamentRolesProvider(widget.tournamentId));

    return Scaffold(
      appBar: AppBar(title: Text('Team — ${widget.tournamentName}')),
      body: rolesAsync.when(
        data: (roles) {
          if (roles.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No team members yet.'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddRoleDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Team Member'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(tournamentRolesProvider(widget.tournamentId).notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Organizers section
                if (roles.any((r) => r.role == 'organizer')) ...[
                  Text('Organizers', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...roles
                      .where((r) => r.role == 'organizer')
                      .map((r) => _RoleCard(role: r, onRevoke: () => _confirmRevoke(r))),
                  const SizedBox(height: 24),
                ],
                // Assistants section
                if (roles.any((r) => r.role == 'assistant')) ...[
                  Text('Assistants', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...roles
                      .where((r) => r.role == 'assistant')
                      .map((r) => _RoleCard(role: r, onRevoke: () => _confirmRevoke(r))),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(tournamentRolesProvider(widget.tournamentId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoleDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _showAddRoleDialog() {
    final emailController = TextEditingController();
    String selectedRole = 'assistant';
    final capabilities = <String>{'entry_management'};

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Team Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'user@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                const Text('Role:'),
                RadioListTile<String>(
                  title: const Text('Assistant'),
                  value: 'assistant',
                  groupValue: selectedRole,
                  onChanged: (v) => setState(() => selectedRole = v!),
                ),
                RadioListTile<String>(
                  title: const Text('Organizer'),
                  value: 'organizer',
                  groupValue: selectedRole,
                  onChanged: (v) => setState(() => selectedRole = v!),
                ),
                if (selectedRole == 'assistant') ...[
                  const SizedBox(height: 8),
                  const Text('Capabilities:'),
                  CheckboxListTile(
                    title: const Text('Entry Management'),
                    value: capabilities.contains('entry_management'),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        capabilities.add('entry_management');
                      } else {
                        capabilities.remove('entry_management');
                      }
                    }),
                  ),
                  CheckboxListTile(
                    title: const Text('Scheduling'),
                    value: capabilities.contains('scheduling'),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        capabilities.add('scheduling');
                      } else {
                        capabilities.remove('scheduling');
                      }
                    }),
                  ),
                  CheckboxListTile(
                    title: const Text('Score Management'),
                    value: capabilities.contains('score_management'),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        capabilities.add('score_management');
                      } else {
                        capabilities.remove('score_management');
                      }
                    }),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an email address')),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                try {
                  await ref.read(tournamentRolesProvider(widget.tournamentId).notifier).assignRole(
                        email: email,
                        role: selectedRole,
                        capabilities: capabilities.toList(),
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added $email as $selectedRole')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add member: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRevoke(TournamentRoleSummary role) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Team Member'),
        content: Text('Remove ${role.userEmail} from the team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await ref.read(tournamentRolesProvider(widget.tournamentId).notifier).revokeRole(role.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Removed ${role.userEmail}')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to remove member: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role, required this.onRevoke});

  final TournamentRoleSummary role;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final isOrganizer = role.role == 'organizer';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOrganizer ? Colors.purple : Colors.blue,
          child: Icon(
            isOrganizer ? Icons.admin_panel_settings : Icons.badge,
            color: Colors.white,
          ),
        ),
        title: Text(role.userEmail),
        subtitle: Text(
          isOrganizer ? 'Organizer' : _capabilitySummary(),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.person_remove),
          onPressed: onRevoke,
        ),
      ),
    );
  }

  String _capabilitySummary() {
    final active = role.capabilities.where((c) => c.isActive).map((c) => c.capability).toList();
    if (active.isEmpty) return 'No capabilities';
    return active.join(', ').replaceAll('_', ' ');
  }
}
