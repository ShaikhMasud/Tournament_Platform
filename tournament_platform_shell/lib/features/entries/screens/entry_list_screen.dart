import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/entries_repository.dart';
import '../providers/entries_providers.dart';
import '../widgets/add_entry_dialog.dart';

class EntryListScreen extends ConsumerStatefulWidget {
  const EntryListScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  ConsumerState<EntryListScreen> createState() => _EntryListScreenState();
}

class _EntryListScreenState extends ConsumerState<EntryListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  void _maybeLoadMore() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(entriesProvider(widget.categoryId).notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesProvider(widget.categoryId));
    // Action visibility is a UX convenience only — the server re-checks
    // every add/remove regardless of what this shows.
    final canManage = ref.watch(canManageEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Entries')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => showAddEntryDialog(
                context,
                ref,
                categoryId: widget.categoryId,
              ),
              icon: const Icon(Icons.person_add),
              label: const Text('Add entry'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by player name',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => ref
                  .read(entriesProvider(widget.categoryId).notifier)
                  .setSearch(value),
            ),
          ),
          Expanded(
            child: entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  err is EntryActionException ? err.message : 'Failed to load entries: $err',
                ),
              ),
              data: (list) {
                if (list.entries.isEmpty) {
                  return const Center(child: Text('No entries yet.'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(
                    entriesProvider(widget.categoryId).future,
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: list.entries.length + (list.hasNext ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= list.entries.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final entry = list.entries[index];
                      return ListTile(
                        title: Text(entry.playerDisplayName),
                        subtitle: Text(entry.status.name),
                        trailing: canManage
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _confirmRemove(entry.id),
                              )
                            : null,
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

  void _confirmRemove(String entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(entriesProvider(widget.categoryId).notifier)
          .removeEntry(entryId);
    } on EntryActionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }
}
