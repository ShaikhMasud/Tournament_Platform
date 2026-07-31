import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/models/session.dart';
import '../../auth/providers/auth_providers.dart';
import '../../organizations/providers/organizations_providers.dart';

class RoleSelectorScreen extends ConsumerWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final colorScheme = Theme.of(context).colorScheme;

    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final roles = session.tournamentRoles;

    // Empty state: only when no player profiles and no roles
    // (Normally signup creates a player profile, so this is rare)
    if (session.playerProfiles.isEmpty && roles.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tournament Ops'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.sports_tennis,
                    size: 40,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Tournament Access Yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "You don't have any tournament access yet.\n"
                  "Ask an organizer to register you as a player, or to invite you as an assistant.",
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose where to go'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User info header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    session.email[0].toUpperCase(),
                    style: TextStyle(color: colorScheme.onPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.email,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${session.playerProfiles.length} player profile${session.playerProfiles.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your Roles',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          // Player tile - always accessible for signed up users
          _RoleTile(
            icon: Icons.sports_tennis,
            iconColor: Colors.green,
            title: 'Player',
            subtitle: session.playerProfiles.isEmpty
                ? 'No tournament entries yet'
                : '${session.playerProfiles.length} entr'
                    '${session.playerProfiles.length == 1 ? "y" : "ies"}',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/player/home'),
          ),
          // Organization/Tournament tile - only shown when no organizer roles
          if (!roles.any((r) => r.isOrganizer))
            _ActionTile(
              icon: Icons.add_business,
              iconColor: Colors.purple,
              title: 'Create Organization',
              subtitle: 'Start managing tournaments',
              onTap: () => _showCreateOrganizationDialog(context, ref),
            ),
          // Tournament roles
          for (final role in roles)
            _RoleTile(
              icon: role.isOrganizer ? Icons.admin_panel_settings : Icons.badge,
              iconColor: role.isOrganizer ? Colors.purple : Colors.blue,
              title: '${role.isOrganizer ? "Organizer" : "Assistant"}',
              subtitle: role.isOrganizer
                  ? 'Full tournament management'
                  : _capabilitySummary(role),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ref.read(selectedRoleProvider.notifier).state = role;
                if (role.isOrganizer) {
                  context.go('/organizer/home');
                } else {
                  context.go('/assistant/tournaments/${role.tournamentId}?name=${Uri.encodeComponent(role.tournamentName)}');
                }
              },
            ),
        ],
      ),
    );
  }

  String _capabilitySummary(TournamentRoleSummary role) {
    final active = role.capabilities.where((c) => c.isActive).map((c) => c.capability).toList();
    if (active.isEmpty) return 'No capabilities granted yet';
    return active.join(', ').replaceAll('_', ' ');
  }

  void _showCreateOrganizationDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String? errorText;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Organization'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'An organization groups your tournaments together.\n'
              'You will become the owner and can create tournaments under it.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Organization name',
                hintText: 'e.g., City Sports Club',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      setState(() => errorText = 'Please enter a name');
                      return;
                    }
                    setState(() {
                      isSubmitting = true;
                      errorText = null;
                    });
                    try {
                      await _createOrganization(ref, name);
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                        // Show success and prompt to create tournament
                        if (context.mounted) {
                          _showCreateTournamentDialog(context, ref);
                        }
                      }
                    } catch (e) {
                      setState(() {
                        isSubmitting = false;
                        errorText = 'Failed to create: $e';
                      });
                    }
                  },
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createOrganization(WidgetRef ref, String name) async {
    // Get the repository from providers
    final repository = ref.read(organizationsRepositoryProvider);
    await repository.createOrganization(name: name);
  }

  void _showCreateTournamentDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🎉 Organization Created!'),
        content: const Text(
          'Your organization has been created.\n\n'
          'Go to the Organizer tab to create your first tournament.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Refresh session to show organizer role
              ref.invalidate(authControllerProvider);
              // Navigate to organizer home
              context.go('/organizer/home');
            },
            child: const Text('Go to Organizer'),
          ),
        ],
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLocked = onTap == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isLocked ? colorScheme.onSurfaceVariant : null,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}