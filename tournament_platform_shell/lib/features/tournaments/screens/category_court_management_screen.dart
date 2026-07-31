import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/tournament.dart';
import '../providers/tournaments_providers.dart';

class CategoryCourtManagementScreen extends ConsumerStatefulWidget {
  const CategoryCourtManagementScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<CategoryCourtManagementScreen> createState() => _CategoryCourtManagementScreenState();
}

class _CategoryCourtManagementScreenState extends ConsumerState<CategoryCourtManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(tournamentDetailProvider(widget.tournamentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.category), text: 'Categories'),
            Tab(icon: Icon(Icons.sports), text: 'Matches'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load tournament: $err')),
        data: (tournament) {
          return TabBarView(
            controller: _tabController,
            children: [
              _CategoriesTab(tournament: tournament, tournamentId: widget.tournamentId),
              _MatchesTab(tournament: tournament, tournamentId: widget.tournamentId),
              _SettingsTab(tournament: tournament, tournamentId: widget.tournamentId),
            ],
          );
        },
      ),
    );
  }
}

class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab({required this.tournament, required this.tournamentId});

  final Tournament tournament;
  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tournament.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(label: Text(tournament.sport)),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(tournament.isPublic ? "Public" : "Private"),
                      backgroundColor: tournament.isPublic ? Colors.green.shade100 : Colors.orange.shade100,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Categories', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showAddCategoryDialog(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        if (tournament.categories.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.category_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('No categories yet'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddCategoryDialog(context, ref),
                    child: const Text('Add Category'),
                  ),
                ],
              ),
            ),
          )
        else
          ...tournament.categories.map(
            (c) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text('${tournament.categories.indexOf(c) + 1}'),
                ),
                title: Text(c.name),
                subtitle: Text('${c.drawFormat} • ${c.status}'),
                children: [
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Entries'),
                    subtitle: Text('Capacity: ${c.capacity}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      '/tournaments/$tournamentId/categories/${c.id}/entries?name=${Uri.encodeComponent(c.name)}',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_tree),
                    title: const Text('Draw'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      '/tournaments/$tournamentId/categories/${c.id}/draw?name=${Uri.encodeComponent(c.name)}',
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text('Courts', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showAddCourtDialog(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        if (tournament.courts.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.location_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('No courts configured'),
                ],
              ),
            ),
          )
        else
          ...tournament.courts.map(
            (c) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.location_on)),
                title: Text(c.name),
              ),
            ),
          ),
      ],
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final capacityController = TextEditingController(text: '8');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Mens Singles',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: capacityController,
              decoration: const InputDecoration(
                labelText: 'Capacity',
                hintText: 'Number of players',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              await ref.read(tournamentDetailProvider(tournamentId).notifier).addCategory(
                    name: nameController.text.trim(),
                    drawFormat: 'knockout',
                    capacity: int.tryParse(capacityController.text.trim()) ?? 8,
                  );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddCourtDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Court'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Court Name',
            hintText: 'e.g., Court 1',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
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

class _MatchesTab extends StatelessWidget {
  const _MatchesTab({required this.tournament, required this.tournamentId});

  final Tournament tournament;
  final String tournamentId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Tournament: ${tournament.name}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Matches will appear here after draw generation'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push(
              '/tournaments/$tournamentId/matches?name=${Uri.encodeComponent(tournament.name)}',
            ),
            icon: const Icon(Icons.list),
            label: const Text('View All Matches'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.tournament, required this.tournamentId});

  final Tournament tournament;
  final String tournamentId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Manage Team'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  '/tournaments/$tournamentId/team?name=${Uri.encodeComponent(tournament.name)}',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Results'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  '/tournaments/$tournamentId/results?name=${Uri.encodeComponent(tournament.name)}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tournament Info', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Created: ${tournament.createdAt.toString().split('.')[0]}'),
                Text('Sport: ${tournament.sport}'),
                Text('Visibility: ${tournament.isPublic ? "Public" : "Private"}'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
