import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../tournaments/data/tournaments_repository.dart';
import '../../tournaments/providers/tournaments_providers.dart';

class AssistantManagementScreen extends ConsumerStatefulWidget {
  const AssistantManagementScreen({
    super.key,
    required this.organizationId,
    required this.organizationName,
  });

  final String organizationId;
  final String organizationName;

  @override
  ConsumerState<AssistantManagementScreen> createState() => _AssistantManagementScreenState();
}

class _AssistantManagementScreenState extends ConsumerState<AssistantManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Assistants - ${widget.organizationName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/organizer/home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person_search), text: 'Search Existing'),
            Tab(icon: Icon(Icons.person_add), text: 'Create New'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SearchExistingTab(organizationId: widget.organizationId),
          _CreateNewTab(organizationId: widget.organizationId),
        ],
      ),
    );
  }
}

class _SearchExistingTab extends ConsumerStatefulWidget {
  const _SearchExistingTab({required this.organizationId});

  final String organizationId;

  @override
  ConsumerState<_SearchExistingTab> createState() => _SearchExistingTabState();
}

class _SearchExistingTabState extends ConsumerState<_SearchExistingTab> {
  final _searchController = TextEditingController();
  final _tournamentIdController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isAssigning = false;
  final _selectedCapabilities = <String>[];

  @override
  void dispose() {
    _searchController.dispose();
    _tournamentIdController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_searchController.text.trim().length < 2) return;

    setState(() => _isSearching = true);

    try {
      final repo = ref.read(tournamentsRepositoryProvider);
      final results = await repo.searchUsers(_searchController.text.trim());
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  Future<void> _assignUser(Map<String, dynamic> user) async {
    if (_tournamentIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Tournament ID')),
      );
      return;
    }

    setState(() => _isAssigning = true);

    try {
      final repo = ref.read(tournamentsRepositoryProvider);
      await repo.assignExistingUser(
        tournamentId: _tournamentIdController.text.trim(),
        email: user['email'],
        capabilities: _selectedCapabilities,
      );

      setState(() => _isAssigning = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user['display_name'] ?? user['username']} added as assistant!')),
        );
      }
    } catch (e) {
      setState(() => _isAssigning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search for existing users to add as assistants.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by email or name',
              hintText: 'Type to search...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _search,
                    ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tournamentIdController,
            decoration: const InputDecoration(
              labelText: 'Tournament ID *',
              hintText: 'Enter tournament UUID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Capabilities:', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: [
              _CapabilityChip(
                label: 'Entry Management',
                capability: 'entry_management',
                selected: _selectedCapabilities,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCapabilities.add('entry_management');
                    } else {
                      _selectedCapabilities.remove('entry_management');
                    }
                  });
                },
              ),
              _CapabilityChip(
                label: 'Scheduling',
                capability: 'scheduling',
                selected: _selectedCapabilities,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCapabilities.add('scheduling');
                    } else {
                      _selectedCapabilities.remove('scheduling');
                    }
                  });
                },
              ),
              _CapabilityChip(
                label: 'Score Mgmt',
                capability: 'score_management',
                selected: _selectedCapabilities,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCapabilities.add('score_management');
                    } else {
                      _selectedCapabilities.remove('score_management');
                    }
                  });
                },
              ),
              _CapabilityChip(
                label: 'Results Mgmt',
                capability: 'results_management',
                selected: _selectedCapabilities,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCapabilities.add('results_management');
                    } else {
                      _selectedCapabilities.remove('results_management');
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No users found'),
              ),
            ),
          ..._searchResults.map((user) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text((user['display_name'] ?? user['username'] ?? 'U')[0].toUpperCase()),
                  ),
                  title: Text(user['display_name'] ?? user['username'] ?? ''),
                  subtitle: Text(user['email'] ?? ''),
                  trailing: _isAssigning
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : FilledButton(
                          onPressed: () => _assignUser(user),
                          child: const Text('Add'),
                        ),
                ),
              )),
        ],
      ),
    );
  }
}

class _CreateNewTab extends ConsumerStatefulWidget {
  const _CreateNewTab({required this.organizationId});

  final String organizationId;

  @override
  ConsumerState<_CreateNewTab> createState() => _CreateNewTabState();
}

class _CreateNewTabState extends ConsumerState<_CreateNewTab> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _tournamentIdController = TextEditingController();
  final _selectedCapabilities = <String>[];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _tournamentIdController.dispose();
    super.dispose();
  }

  Future<void> _createAssistant() async {
    if (_emailController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _displayNameController.text.trim().isEmpty) {
      setState(() => _error = 'Please fill all required fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(tournamentsRepositoryProvider);
      final result = await repo.createAssistantAccount(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        tournamentId: _tournamentIdController.text.trim().isNotEmpty
            ? _tournamentIdController.text.trim()
            : null,
        capabilities: _selectedCapabilities,
        sendInvite: true,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assistant created: ${result['email']}'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear form
        _emailController.clear();
        _usernameController.clear();
        _displayNameController.clear();
        _tournamentIdController.clear();
        setState(() => _selectedCapabilities.clear());
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create a new assistant account. They will receive login credentials via email.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                  ),
                ],
              ),
            ),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email *',
              hintText: 'assistant@example.com',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username *',
              hintText: 'assistant_user',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'Display Name *',
              hintText: 'John Assistant',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tournamentIdController,
            decoration: const InputDecoration(
              labelText: 'Tournament ID (optional)',
              hintText: 'Leave empty to assign later',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Capabilities:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _CapabilityChip(
                label: 'Entry Management',
                capability: 'entry_management',
                selected: _selectedCapabilities,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCapabilities.add('entry_management');
                    } else {
                      _selectedCapabilities.remove('entry_management');
                    }
                  });
                },
              ),
              _CapabilityChip(
                label: 'Scheduling',
                capability: 'scheduling',
                selected: _selectedCapabilities,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCapabilities.add('scheduling');
                    } else {
                      _selectedCapabilities.remove('scheduling');
                    }
                  });
                },
              ),
              _CapabilityChip(
                label: 'Score Mgmt',
                capability: 'score_management',
                selected: _selectedCapabilities,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCapabilities.add('score_management');
                    } else {
                      _selectedCapabilities.remove('score_management');
                    }
                  });
                },
              ),
              _CapabilityChip(
                label: 'Results Mgmt',
                capability: 'results_management',
                selected: _selectedCapabilities,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCapabilities.add('results_management');
                    } else {
                      _selectedCapabilities.remove('results_management');
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _createAssistant,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.person_add),
              label: Text(_isLoading ? 'Creating...' : 'Create Assistant Account'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({
    required this.label,
    required this.capability,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String capability;
  final List<String> selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected.contains(capability);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }
}
