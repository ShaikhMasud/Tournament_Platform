import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/entries_repository.dart';
import '../models/entry.dart';
import '../providers/entries_providers.dart';

class CategoryEntriesScreen extends ConsumerStatefulWidget {
  const CategoryEntriesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final String categoryId;
  final String categoryName;

  @override
  ConsumerState<CategoryEntriesScreen> createState() => _CategoryEntriesScreenState();
}

class _CategoryEntriesScreenState extends ConsumerState<CategoryEntriesScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesProvider(widget.categoryId));

    return Scaffold(
      appBar: AppBar(title: Text('Entries — ${widget.categoryName}')),
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search players...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (value) {
                      // Implement search on change with debounce
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String?>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (value) {
                    setState(() => _selectedStatus = value);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: null, child: Text('All')),
                    const PopupMenuItem(value: 'confirmed', child: Text('Confirmed')),
                    const PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  ],
                ),
              ],
            ),
          ),
          // Entries list
          Expanded(
            child: entriesAsync.when(
              data: (state) {
                if (state.entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No entries yet.'),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _showAddEntryDialog,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Entry'),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(entriesProvider(widget.categoryId).notifier).refresh(),
                  child: ListView.builder(
                    itemCount: state.entries.length,
                    itemBuilder: (context, index) {
                      final entry = state.entries[index];
                      return _EntryCard(
                        entry: entry,
                        onDelete: () => _confirmDelete(entry),
                      );
                    },
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
                      onPressed: () => ref.invalidate(entriesProvider(widget.categoryId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _showAddEntryDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Entry'),
        content: const Text(
          'This will add you (or your selected player) to this category.\n\n'
          'For now, only the current user can be added as an entry.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await ref.read(entriesProvider(widget.categoryId).notifier).addEntry();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Entry added successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add entry: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Add Me'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Entry entry) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Entry'),
        content: Text('Remove ${entry.playerDisplayName} from this category?'),
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
                await ref.read(entriesProvider(widget.categoryId).notifier).removeEntry(entry.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Entry removed')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to remove entry: $e'), backgroundColor: Colors.red),
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

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.onDelete});

  final Entry entry;
  final VoidCallback onDelete;

  String _statusToString(EntryStatus status) {
    switch (status) {
      case EntryStatus.confirmed:
        return 'CONFIRMED';
      case EntryStatus.unknown:
        return 'UNKNOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(entry.playerDisplayName.isNotEmpty 
              ? entry.playerDisplayName[0].toUpperCase() 
              : '?'),
        ),
        title: Text(entry.playerDisplayName),
        subtitle: Text(_statusToString(entry.status)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
