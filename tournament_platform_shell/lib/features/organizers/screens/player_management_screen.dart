import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_providers.dart';
import '../../tournaments/providers/tournaments_providers.dart';

class PlayerManagementScreen extends ConsumerStatefulWidget {
  const PlayerManagementScreen({
    super.key,
    required this.organizationId,
    required this.organizationName,
  });

  final String organizationId;
  final String organizationName;

  @override
  ConsumerState<PlayerManagementScreen> createState() => _PlayerManagementScreenState();
}

class _PlayerManagementScreenState extends ConsumerState<PlayerManagementScreen> {
  List<Map<String, dynamic>> _players = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      // Get all tournaments for this organization
      final tournamentsAsync = ref.read(tournamentsProvider);
      
      final Set<String> playerIds = {};
      final List<Map<String, dynamic>> allEntries = [];

      tournamentsAsync.whenData((tournaments) async {
        final orgTournaments = tournaments.where((t) => t.organizationId == widget.organizationId).toList();
        
        for (final tournament in orgTournaments) {
          try {
            final response = await apiClient.dio.get(
              ApiEndpoints.categories(tournament.id),
            );
            
            final categories = response.data is List ? response.data as List : [];
            
            for (final category in categories) {
              try {
                final entriesResponse = await apiClient.dio.get(
                  ApiEndpoints.entries(category['id'] as String),
                );
                
                final entries = entriesResponse.data is Map && entriesResponse.data['results'] != null
                    ? entriesResponse.data['results'] as List
                    : (entriesResponse.data is List ? entriesResponse.data as List : []);
                
                for (final entry in entries) {
                  if (!playerIds.contains(entry['player'])) {
                    playerIds.add(entry['player'] as String);
                    allEntries.add({
                      'player_id': entry['player'],
                      'player_name': entry['player_name'] ?? entry['display_name'] ?? 'Unknown',
                      'category_name': category['name'],
                      'tournament_name': tournament.name,
                      'tournament_id': tournament.id,
                      'status': entry['status'],
                      'entry_id': entry['id'],
                    });
                  }
                }
              } catch (e) {
                // Skip category if entries fail
              }
            }
          } catch (e) {
            // Skip tournament if categories fail
          }
        }

        if (mounted) {
          setState(() {
            _players = allEntries;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredPlayers {
    if (_searchQuery.isEmpty) return _players;
    return _players.where((p) {
      final name = (p['player_name'] ?? '').toLowerCase();
      final tournament = (p['tournament_name'] ?? '').toLowerCase();
      final category = (p['category_name'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || tournament.contains(query) || category.contains(query);
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _playersByTournament {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final player in _filteredPlayers) {
      final tournamentName = player['tournament_name'] ?? 'Unknown';
      if (!grouped.containsKey(tournamentName)) {
        grouped[tournamentName] = [];
      }
      grouped[tournamentName]!.add(player);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Players - ${widget.organizationName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/organizer/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlayers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search players...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Stats row
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _StatCard(
                    icon: Icons.people,
                    label: 'Total Players',
                    value: _players.length.toString(),
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.emoji_events,
                    label: 'Tournaments',
                    value: _playersByTournament.keys.length.toString(),
                    color: Colors.green,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Error loading players', style: TextStyle(color: Colors.red.shade700)),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPlayers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_players.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Players Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Players will appear here once they register\nfor your tournaments.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_filteredPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No players match your search'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPlayers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _playersByTournament.keys.length,
        itemBuilder: (context, index) {
          final tournamentName = _playersByTournament.keys.elementAt(index);
          final tournamentPlayers = _playersByTournament[tournamentName]!;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text('${tournamentPlayers.length}'),
              ),
              title: Text(
                tournamentName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${tournamentPlayers.length} players'),
              children: tournamentPlayers.map((player) {
                return _PlayerTile(
                  player: player,
                  onTap: () => _showPlayerDetails(player),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  void _showPlayerDetails(Map<String, dynamic> player) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (player['player_name'] ?? '?')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    player['player_name'] ?? 'Unknown',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 24),
                _DetailRow(icon: Icons.emoji_events, label: 'Tournament', value: player['tournament_name'] ?? ''),
                const SizedBox(height: 12),
                _DetailRow(icon: Icons.category, label: 'Category', value: player['category_name'] ?? ''),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.check_circle,
                  label: 'Status',
                  value: player['status']?.toString().toUpperCase() ?? '',
                  valueColor: player['status'] == 'confirmed' ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/player/leaderboard/${player['tournament_id']}?name=${Uri.encodeComponent(player['tournament_name'] ?? '')}');
                    },
                    icon: const Icon(Icons.leaderboard),
                    label: const Text('View Leaderboard'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player, required this.onTap});

  final Map<String, dynamic> player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = player['status']?.toString().toLowerCase() ?? '';
    final statusColor = status == 'confirmed' ? Colors.green : Colors.orange;

    return ListTile(
      leading: CircleAvatar(
        child: Text((player['player_name'] ?? '?')[0].toUpperCase()),
      ),
      title: Text(player['player_name'] ?? 'Unknown'),
      subtitle: Text(player['category_name'] ?? ''),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
        ),
      ),
      onTap: onTap,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500, color: valueColor),
            ),
          ],
        ),
      ],
    );
  }
}
