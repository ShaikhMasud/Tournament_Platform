import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../tournaments/data/tournaments_repository.dart';
import '../../tournaments/providers/tournaments_providers.dart';
import '../../tournaments/models/tournament.dart';

class TournamentBrowseScreen extends ConsumerStatefulWidget {
  const TournamentBrowseScreen({super.key});

  @override
  ConsumerState<TournamentBrowseScreen> createState() => _TournamentBrowseScreenState();
}

class _TournamentBrowseScreenState extends ConsumerState<TournamentBrowseScreen> {
  List<Map<String, dynamic>> _tournaments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTournaments();
  }

  Future<void> _fetchTournaments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(tournamentsRepositoryProvider);
      final tournaments = await repo.listPublicTournaments();
      setState(() {
        _tournaments = tournaments.map((t) => {
          'id': t.id,
          'name': t.name,
          'sport': t.sport,
          'is_public': t.isPublic,
          'categories': t.categories.map((c) => {
            'id': c.id,
            'name': c.name,
            'draw_format': c.drawFormat,
            'capacity': c.capacity,
            'status': c.status,
          }).toList(),
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Tournaments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/player/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTournaments,
          ),
        ],
      ),
      body: _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            const Text('Error loading tournaments'),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _fetchTournaments,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_tennis, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text('No public tournaments available'),
            const SizedBox(height: 8),
            Text(
              'Check back later for new tournaments',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTournaments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tournaments.length,
        itemBuilder: (context, index) {
          final tournament = _tournaments[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _showTournamentDetails(context, tournament),
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
                            tournament['name'] ?? '',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatSport(tournament['sport'] ?? ''),
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.category, size: 14, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                '${(tournament['categories'] as List?)?.length ?? 0} categories',
                                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                              ),
                            ],
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
      ),
    );
  }

  String _formatSport(String sport) {
    switch (sport) {
      case 'badminton_single_game':
        return 'Badminton (Singles)';
      case 'badminton_double_game':
        return 'Badminton (Doubles)';
      case 'tennis_single_game':
        return 'Tennis (Singles)';
      case 'tennis_double_game':
        return 'Tennis (Doubles)';
      default:
        return sport.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }
  }

  void _showTournamentDetails(BuildContext context, Map<String, dynamic> tournament) {
    final categories = (tournament['categories'] as List?) ?? [];

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
                tournament['name'] ?? '',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatSport(tournament['sport'] ?? ''),
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
              if (categories.isEmpty)
                const Text('No categories available')
              else
                ...categories.map<Widget>((c) => ListTile(
                      leading: const Icon(Icons.category),
                      title: Text(c['name'] ?? ''),
                      subtitle: Text('${c['draw_format']} · capacity ${c['capacity']}'),
                      trailing: c['status'] == 'open'
                          ? FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.push('/tournaments/${tournament['id']}/categories/${c['id']}/entries');
                              },
                              child: const Text('Register'),
                            )
                          : Chip(
                              label: Text(c['status']?.toString().toUpperCase() ?? ''),
                              backgroundColor: Colors.grey.shade200,
                            ),
                    )),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/tournaments/${tournament['id']}/results');
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('View Results'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
