import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../../tournaments/data/tournaments_repository.dart';
import '../../tournaments/providers/tournaments_providers.dart';

class TournamentListScreen extends ConsumerWidget {
  const TournamentListScreen({
    super.key,
    required this.organizationId,
    required this.organizationName,
  });

  final String organizationId;
  final String organizationName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(tournamentsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(organizationName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/organizer/home'),
        ),
      ),
      body: tournamentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $err', style: TextStyle(color: colorScheme.error)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(tournamentsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (tournaments) {
          final orgTournaments = tournaments.where((t) => t.organizationId == organizationId).toList();

          if (orgTournaments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 80, color: colorScheme.primary.withOpacity(0.5)),
                  const SizedBox(height: 24),
                  Text(
                    'No Tournaments Yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first tournament to get started',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showCreateTournamentDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Tournament'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(tournamentsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orgTournaments.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FilledButton.icon(
                      onPressed: () => _showCreateTournamentDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Tournament'),
                    ),
                  );
                }
                final tournament = orgTournaments[index - 1];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.emoji_events, color: colorScheme.primary),
                    ),
                    title: Text(
                      tournament.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${tournament.sport} · ${tournament.isPublic ? "Public" : "Private"}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/tournaments/${tournament.id}/manage'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showCreateTournamentDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedSport = 'badminton_single_game';
    bool isPublic = true;
    bool isLoading = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Tournament'),
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
                  autofocus: true,
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
                SwitchListTile(
                  title: const Text('Public Tournament'),
                  subtitle: const Text('Allow anyone to view'),
                  value: isPublic,
                  onChanged: (value) => setState(() => isPublic = value),
                  contentPadding: EdgeInsets.zero,
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
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
                        setState(() => errorText = 'Please enter a tournament name');
                        return;
                      }

                      setState(() {
                        isLoading = true;
                        errorText = null;
                      });

                      try {
                        final repo = ref.read(tournamentsRepositoryProvider);
                        final tournament = await repo.createTournament(
                          organizationId: organizationId,
                          name: nameController.text.trim(),
                          sportName: selectedSport,
                          isPublic: isPublic,
                        );

                        ref.invalidate(authControllerProvider);
                        ref.invalidate(tournamentsProvider);

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tournament "${tournament.name}" created!'),
                              action: SnackBarAction(
                                label: 'Manage',
                                onPressed: () => context.push('/tournaments/${tournament.id}/manage'),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                          errorText = 'Failed to create: $e';
                        });
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
