import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../../tournaments/providers/tournaments_providers.dart';

class TournamentBrowseScreen extends ConsumerWidget {
  const TournamentBrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournaments = ref.watch(publicTournamentsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Tournaments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/player/home'),
        ),
      ),
      body: tournaments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (tournamentList) {
          if (tournamentList.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_tennis, size: 64, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  const Text('No public tournaments available'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tournamentList.length,
            itemBuilder: (context, index) {
              final tournament = tournamentList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _showTournamentDetails(context, ref, tournament),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.emoji_events, color: colorScheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tournament.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tournament.sport,
                                style: TextStyle(color: colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tournament.isPublic ? 'Public' : 'Private',
                                style: TextStyle(
                                  color: tournament.isPublic ? Colors.green : Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showTournamentDetails(BuildContext context, WidgetRef ref, dynamic tournament) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                tournament.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                tournament.sport,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Categories',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              if (tournament.categories.isEmpty)
                const Text('No categories available')
              else
                ...tournament.categories.map<Widget>((c) => ListTile(
                      leading: const Icon(Icons.category),
                      title: Text(c.name),
                      subtitle: Text('${c.drawFormat} · ${c.status}'),
                      trailing: c.status == 'open'
                          ? FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.push('/tournaments/${tournament.id}/categories/${c.id}/entries');
                              },
                              child: const Text('Register'),
                            )
                          : null,
                    )),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/tournaments/${tournament.id}/results');
                },
                child: const Text('View Results'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final publicTournamentsProvider = FutureProvider((ref) async {
  // TODO: Call API to get public tournaments
  return [];
});
