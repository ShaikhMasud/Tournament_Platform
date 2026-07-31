import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/models/session.dart';
import '../../auth/providers/auth_providers.dart';

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
    final hasOrganizerRole = roles.any((r) => r.isOrganizer);
    final hasAssistantRole = roles.any((r) => r.isAssistant);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Platform'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const SizedBox(height: 32),
              Icon(
                Icons.sports_tennis,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                session.email,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Role Selection
              Text(
                'Select your role',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Player Role - Always available
              Expanded(
                child: _RoleCard(
                  icon: Icons.person,
                  color: Colors.green,
                  title: 'Player',
                  subtitle: 'Register for tournaments and view draws',
                  isAvailable: true,
                  onTap: () => context.go('/player/home'),
                ),
              ),

              const SizedBox(height: 12),

              // Organizer Role
              Expanded(
                child: _RoleCard(
                  icon: Icons.admin_panel_settings,
                  color: Colors.purple,
                  title: 'Organizer',
                  subtitle: hasOrganizerRole
                      ? 'Manage tournaments (${roles.where((r) => r.isOrganizer).length} tournaments)'
                      : 'Create and manage tournaments',
                  badge: hasOrganizerRole ? '${roles.where((r) => r.isOrganizer).length}' : null,
                  onTap: () => context.go('/organizer/home'),
                ),
              ),

              const SizedBox(height: 12),

              // Assistant Role
              Expanded(
                child: _RoleCard(
                  icon: Icons.badge,
                  color: Colors.blue,
                  title: 'Assistant',
                  subtitle: hasAssistantRole
                      ? 'Help manage tournaments (${roles.where((r) => r.isAssistant).length} assignments)'
                      : 'Get invited by an organizer',
                  badge: hasAssistantRole ? '${roles.where((r) => r.isAssistant).length}' : null,
                  onTap: () {
                    if (hasAssistantRole) {
                      _showAssistantTournamentPicker(context, ref, roles.where((r) => r.isAssistant).toList());
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No tournament assignments yet. Ask an organizer to invite you.')),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssistantTournamentPicker(
    BuildContext context,
    WidgetRef ref,
    List<TournamentRoleSummary> assistantRoles,
  ) {
    if (assistantRoles.length == 1) {
      // Only one tournament, go directly
      final role = assistantRoles.first;
      context.go('/assistant/tournaments/${role.tournamentId}?name=${Uri.encodeComponent(role.tournamentName)}');
      return;
    }

    // Show picker dialog
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Tournament',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...assistantRoles.map((role) => ListTile(
                  leading: const Icon(Icons.sports_tennis),
                  title: Text(role.tournamentName),
                  subtitle: Text(role.capabilities.map((c) => c.capability).join(', ')),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/assistant/tournaments/${role.tournamentId}?name=${Uri.encodeComponent(role.tournamentName)}');
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.badge,
    this.isAvailable = true,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? badge;
  final bool isAvailable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isAvailable ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.primary),
            ],
          ),
        ),
      ),
      )
    );
  }
}
