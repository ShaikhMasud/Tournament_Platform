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

  Future<Tournament> getTournament(String id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.tournament(id));
    return Tournament.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /tournaments/ — organizationId must be one of the caller's own
  /// orgs; the server re-validates this regardless of what's sent.
  Future<Tournament> createTournament({
    required String organizationId,
    required String name,
    bool isPublic = false,
  }) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.tournaments,
      data: {
        'organization': organizationId,
        'name': name,
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
}