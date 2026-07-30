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

    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hasPlayerAccess = session.playerProfiles.isNotEmpty;
    final roles = session.tournamentRoles;

    if (!hasPlayerAccess && roles.isEmpty) {
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
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              "You don't have any tournament access yet.\n"
              "Ask an organizer to register you as a player, or to invite you "
              "as an assistant.",
              textAlign: TextAlign.center,
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
          if (hasPlayerAccess)
            _RoleTile(
              icon: Icons.sports_tennis,
              title: 'Player',
              subtitle: '${session.playerProfiles.length} entr'
                  '${session.playerProfiles.length == 1 ? "y" : "ies"}',
              // Player screens are Phase 2 — nothing to route to yet.
              onTap: null,
            ),
          for (final role in roles)
            _RoleTile(
              icon: role.isOrganizer ? Icons.admin_panel_settings : Icons.badge,
              title: '${role.isOrganizer ? "Organizer" : "Assistant"} — ${role.tournamentName}',
              subtitle: role.isAssistant
                  ? _capabilitySummary(role)
                  : 'Full tournament management',
              // Assistant screens are Phase 3 — only Organizer routes for now.
              onTap: role.isOrganizer
                  ? () {
                      ref.read(selectedRoleProvider.notifier).state = role;
                      context.go('/organizer/home');
                    }
                  : null,
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
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap == null
            ? const Icon(Icons.lock_outline, size: 18)
            : const Icon(Icons.chevron_right),
        enabled: onTap != null,
        onTap: onTap,
      ),
    );
  }
}