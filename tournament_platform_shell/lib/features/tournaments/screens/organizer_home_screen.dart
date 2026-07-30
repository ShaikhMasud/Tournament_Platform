import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../organizations/providers/organizations_providers.dart';
import '../models/tournament.dart';
import '../providers/tournaments_providers.dart';

class OrganizerHomeScreen extends ConsumerWidget {
  const OrganizerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(tournamentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Tournaments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTournamentDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Tournament'),
      ),
      body: tournamentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load tournaments: $err')),
        data: (tournaments) {
          if (tournaments.isEmpty) {
            return const Center(
              child: Text('No tournaments yet — create one to get started.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(tournamentsProvider.future),
            child: ListView.builder(
              itemCount: tournaments.length,
              itemBuilder: (context, index) {
                final Tournament t = tournaments[index];
                return ListTile(
                  title: Text(t.name),
                  subtitle: Text(
                    '${t.sport} · ${t.isPublic ? "Public" : "Private"} · '
                    '${t.categories.length} categories · ${t.courts.length} courts',
                  ),
                  // GoRouter-based navigation — this app uses
                  // MaterialApp.router, so Navigator.pushNamed has no
                  // route table to resolve against and throws at runtime.
                  onTap: () => context.push('/tournaments/${t.id}/manage'),
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
    bool isPublic = false;
    // Organization.id (and Tournament.id) are String, matching the JSON
    // the server returns — this must not be int.
    String? selectedOrgId;
    String? errorText;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, dialogRef, _) {
            final orgsAsync = dialogRef.watch(organizationsProvider);
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('New Tournament'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      orgsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => Text('Could not load organizations: $e'),
                        data: (orgs) {
                          if (orgs.isEmpty) {
                            return const Text(
                              'Create an organization first before creating a tournament.',
                            );
                          }
                          selectedOrgId ??= orgs.first.id;
                          return DropdownButton<String>(
                            value: selectedOrgId,
                            items: orgs
                                .map((o) => DropdownMenuItem(
                                      value: o.id,
                                      child: Text(o.name),
                                    ))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => selectedOrgId = value),
                          );
                        },
                      ),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Tournament name'),
                      ),
                      SwitchListTile(
                        title: const Text('Public'),
                        value: isPublic,
                        onChanged: (value) => setState(() => isPublic = value),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 8),
                        Text(errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: (selectedOrgId == null || isSubmitting)
                          ? null
                          : () async {
                              setState(() {
                                isSubmitting = true;
                                errorText = null;
                              });
                              try {
                                await ref.read(tournamentsProvider.notifier).createTournament(
                                      organizationId: selectedOrgId!,
                                      name: nameController.text.trim(),
                                      isPublic: isPublic,
                                    );
                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }
                              } catch (e) {
                                setState(() {
                                  isSubmitting = false;
                                  errorText = 'Could not create tournament: $e';
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
                );
              },
            );
          },
        );
      },
    );
  }
}