import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/entries_repository.dart';
import '../providers/entries_providers.dart';

/// Shows a dialog to add an entry to [categoryId].
///
/// For an Organizer/capable Assistant, this includes a player-id field
/// (a real build would replace this with a typeahead search against a
/// player-lookup endpoint — not specified in Phase 2's plan, so left as
/// a plain UUID text field with a TODO). A Player adding themselves needs
/// no input at all; the server resolves them from the auth token.
Future<void> showAddEntryDialog(
  BuildContext context,
  WidgetRef ref, {
  required String categoryId,
}) async {
  final canManage = ref.read(canManageEntriesProvider);
  final playerIdController = TextEditingController();
  String? errorText;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add entry'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canManage) ...[
                  TextField(
                    controller: playerIdController,
                    decoration: const InputDecoration(
                      labelText: 'Player ID',
                      // TODO: swap for a player search/typeahead once a
                      // player-lookup endpoint exists.
                      helperText: 'Enter the player\'s UUID to add them',
                    ),
                  ),
                ] else ...[
                  const Text('This will add you to this category.'),
                ],
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
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  try {
                    final playerId = canManage && playerIdController.text.trim().isNotEmpty
                        ? playerIdController.text.trim()
                        : null;
                    await ref
                        .read(entriesProvider(categoryId).notifier)
                        .addEntry(playerId: playerId);
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  } on EntryActionException catch (e) {
                    setState(() => errorText = e.message);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );
}
