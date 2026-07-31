import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AssistantManagementScreen extends ConsumerWidget {
  const AssistantManagementScreen({
    super.key,
    required this.organizationId,
    required this.organizationName,
  });

  final String organizationId;
  final String organizationName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Assistants - $organizationName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/organizer/home'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people, size: 80, color: colorScheme.primary.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(
              'Assistant Management',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage assistants and their permissions',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddAssistantDialog(context, ref),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Assistant'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAssistantDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final selectedCapabilities = <String>[];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Assistant'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'assistant@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                const Text('Capabilities:'),
                const SizedBox(height: 8),
                _CapabilityCheckbox(
                  label: 'Entry Management',
                  capability: 'entry_management',
                  selected: selectedCapabilities,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedCapabilities.add('entry_management');
                      } else {
                        selectedCapabilities.remove('entry_management');
                      }
                    });
                  },
                ),
                _CapabilityCheckbox(
                  label: 'Scheduling',
                  capability: 'scheduling',
                  selected: selectedCapabilities,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedCapabilities.add('scheduling');
                      } else {
                        selectedCapabilities.remove('scheduling');
                      }
                    });
                  },
                ),
                _CapabilityCheckbox(
                  label: 'Score Management',
                  capability: 'score_management',
                  selected: selectedCapabilities,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedCapabilities.add('score_management');
                      } else {
                        selectedCapabilities.remove('score_management');
                      }
                    });
                  },
                ),
                _CapabilityCheckbox(
                  label: 'Results Management',
                  capability: 'results_management',
                  selected: selectedCapabilities,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedCapabilities.add('results_management');
                      } else {
                        selectedCapabilities.remove('results_management');
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                // TODO: Call API to add assistant
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Assistant added (API pending)')),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapabilityCheckbox extends StatelessWidget {
  const _CapabilityCheckbox({
    required this.label,
    required this.capability,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final String capability;
  final List<String> selected;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(label),
      value: selected.contains(capability),
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}
