import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/tournament.dart';

class TournamentsRepository {
  TournamentsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// GET /tournaments/ — public tournaments + any the caller holds an
  /// active role on (server decides visibility; client just renders it).
  Future<List<Tournament>> listVisibleTournaments() async {
    final response = await _apiClient.dio.get(ApiEndpoints.tournaments);
    final results = (response.data is List)
        ? response.data as List
        : (response.data['results'] as List);
    return results
        .map((json) => Tournament.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// GET /tournaments/public/ — all public tournaments for browsing
  Future<List<Tournament>> listPublicTournaments() async {
    final response = await _apiClient.dio.get(ApiEndpoints.publicTournaments);
    final results = (response.data is List)
        ? response.data as List
        : (response.data['results'] as List);
    return results
        .map((json) => Tournament.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// GET /tournaments/my/ — tournaments where player has entries
  Future<List<Map<String, dynamic>>> listMyTournaments() async {
    final response = await _apiClient.dio.get(ApiEndpoints.myTournaments);
    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    }
    return [];
  }

  Future<Tournament> getTournament(String id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.tournament(id));
    return Tournament.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /tournaments/create/ — create a new tournament under an organization
  Future<Tournament> createTournament({
    required String organizationId,
    required String name,
    String? sportName,
    bool isPublic = false,
  }) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.createTournament,
      data: {
        'organization': organizationId,
        'name': name,
        'sport_name': sportName ?? 'badminton_single_game',
        'is_public': isPublic,
      },
    );
    return Tournament.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Category> createCategory({
    required String tournamentId,
    required String name,
    required String drawFormat,
    required int capacity,
  }) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.categories(tournamentId),
      data: {
        'name': name,
        'draw_format': drawFormat,
        'capacity': capacity,
      },
    );
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /tournaments/{id}/categories/ — list all categories
  Future<List<Category>> getCategories(String tournamentId) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.categories(tournamentId),
    );
    if (response.data is List) {
      return (response.data as List)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Court> createCourt({
    required String tournamentId,
    required String name,
  }) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.courts(tournamentId),
      data: {'name': name},
    );
    return Court.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /tournaments/{id}/courts/ — list all courts
  Future<List<Court>> getCourts(String tournamentId) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.courts(tournamentId),
    );
    if (response.data is List) {
      return (response.data as List)
          .map((e) => Court.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// GET /tournaments/{id}/roles/ — get tournament roles
  Future<List<Map<String, dynamic>>> getTournamentRoles(String tournamentId) async {
    final response = await _apiClient.dio.get(ApiEndpoints.tournamentRoles(tournamentId));
    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    }
    return [];
  }

  /// POST /tournaments/{id}/assign-user/ — assign existing user as assistant
  Future<Map<String, dynamic>> assignExistingUser({
    required String tournamentId,
    required String email,
    List<String> capabilities = const [],
  }) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.assignUser(tournamentId),
      data: {
        'email': email,
        'capabilities': capabilities,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  /// POST /auth/assistant-signup/ — create new assistant account
  Future<Map<String, dynamic>> createAssistantAccount({
    required String email,
    required String username,
    required String displayName,
    String? tournamentId,
    List<String> capabilities = const [],
    bool sendInvite = true,
  }) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.assistantSignup,
      data: {
        'email': email,
        'username': username,
        'display_name': displayName,
        if (tournamentId != null) 'tournament_id': tournamentId,
        'capabilities': capabilities,
        'send_invite': sendInvite,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  /// GET /auth/users/search/ — search for users by email or name
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.userSearch,
      queryParameters: {'q': query},
    );
    if (response.data is Map && response.data['results'] != null) {
      return List<Map<String, dynamic>>.from(response.data['results']);
    }
    return [];
  }

  /// GET /tournaments/{id}/leaderboard/ — get leaderboard
  Future<Map<String, dynamic>> getLeaderboard(String tournamentId, {String? categoryId}) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.leaderboard(tournamentId),
      queryParameters: categoryId != null ? {'category': categoryId} : null,
    );
    return Map<String, dynamic>.from(response.data);
  }
}