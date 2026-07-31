import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/player_providers.dart';
import 'tournament_browse_screen.dart';
import 'leaderboard_screen.dart';

class PlayerHomeScreen extends ConsumerWidget {
  const PlayerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(playerTournamentsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () => _showTournamentPicker(context, ref),
            tooltip: 'Leaderboard',
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Actions
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.search,
                    label: 'Browse\nTournaments',
                    onTap: () => context.push('/player/browse'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.emoji_events,
                    label: 'My\nEntries',
                    onTap: null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.schedule,
                    label: 'Match\nSchedule',
                    onTap: null,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // My Tournaments
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'My Tournaments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/player/browse'),
                  child: const Text('Browse More'),
                ),
              ],
            ),
          ),
          Expanded(
            child: tournamentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Failed to load tournaments: $err'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(playerTournamentsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (tournaments) {
                if (tournaments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sports_tennis,
                            size: 64,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Tournament Entries',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Browse and register for tournaments',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => context.push('/player/browse'),
                            icon: const Icon(Icons.search),
                            label: const Text('Browse Tournaments'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(playerTournamentsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tournaments.length,
                    itemBuilder: (context, index) {
                      final tournament = tournaments[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _showTournamentActions(context, ref, tournament),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.emoji_events,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tournament.name,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Text(
                                            tournament.categoryName,
                                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _StatusChip(status: tournament.entryStatus),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                // Quick actions
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _MiniAction(
                                      icon: Icons.account_tree,
                                      label: 'Draw',
                                      onTap: () {
                                        // View draw
                                      },
                                    ),
                                    _MiniAction(
                                      icon: Icons.leaderboard,
                                      label: 'Standings',
                                      onTap: () {
                                        context.push('/player/leaderboard/${tournament.tournamentId}?name=${Uri.encodeComponent(tournament.name)}');
                                      },
                                    ),
                                    _MiniAction(
                                      icon: Icons.picture_as_pdf,
                                      label: 'Results',
                                      onTap: () {
                                        context.push('/tournaments/${tournament.tournamentId}/results');
                                      },
                                    ),
                                    if (tournament.nextMatchId != null)
                                      _MiniAction(
                                        icon: Icons.play_circle,
                                        label: 'Live',
                                        color: Colors.red,
                                        onTap: () {
                                          context.push('/matches/${tournament.nextMatchId}/live');
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showTournamentActions(BuildContext context, WidgetRef ref, dynamic tournament) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tournament.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(tournament.categoryName),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.account_tree),
              title: const Text('View Draw'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard),
              title: const Text('Leaderboard'),
              onTap: () {
                Navigator.pop(context);
                context.push('/player/leaderboard/${tournament.tournamentId}?name=${Uri.encodeComponent(tournament.name)}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Results'),
              onTap: () {
                Navigator.pop(context);
                context.push('/tournaments/${tournament.tournamentId}/results');
              },
            ),
            if (tournament.nextMatchId != null)
              ListTile(
                leading: const Icon(Icons.play_circle, color: Colors.red),
                title: const Text('Live Match'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/matches/${tournament.nextMatchId}/live');
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showTournamentPicker(BuildContext context, WidgetRef ref) async {
    final tournamentsAsync = ref.read(playerTournamentsProvider);
    
    tournamentsAsync.whenData((tournaments) {
      if (tournaments.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tournaments to show leaderboard for')),
        );
        return;
      }
      
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...tournaments.map((t) => ListTile(
                leading: const Icon(Icons.emoji_events),
                title: Text(t.name),
                subtitle: Text(t.categoryName),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/player/leaderboard/${t.tournamentId}?name=${Uri.encodeComponent(t.name)}');
                },
              )),
            ],
          ),
        ),
      );
    });
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

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
