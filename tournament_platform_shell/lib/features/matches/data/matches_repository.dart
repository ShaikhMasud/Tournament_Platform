import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/match.dart';

class MatchesRepository {
  MatchesRepository(this._apiClient);

  final ApiClient _apiClient;

  /// GET /api/tournaments/{tournamentId}/matches/
  Future<List<MatchModel>> listMatches({
    required String tournamentId,
    String? categoryId,
    String? courtId,
    String? status,
    int page = 1,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.matches(tournamentId),
      queryParameters: {
        if (categoryId != null) 'category': categoryId,
        if (courtId != null) 'court': courtId,
        if (status != null) 'status': status,
        'page': page,
      },
    );

    final data = response.data;
    final List<dynamic> results;
    if (data is List) {
      results = data;
    } else {
      results = data['results'] as List<dynamic>;
    }

    return results
        .map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/matches/{matchId}/
  Future<MatchModel> getMatch(String matchId) async {
    final response = await _apiClient.dio.get(ApiEndpoints.match(matchId));
    return MatchModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /api/matches/{matchId}/schedule/
  Future<MatchModel> scheduleMatch({
    required String matchId,
    String? courtId,
    DateTime? scheduledStart,
  }) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.matchSchedule(matchId),
      data: ScheduleMatchRequest(
        courtId: courtId,
        scheduledStart: scheduledStart,
      ).toJson(),
    );
    return MatchModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /api/matches/{matchId}/start/
  Future<MatchModel> startMatch(String matchId) async {
    final response = await _apiClient.dio.post(ApiEndpoints.matchStart(matchId));
    return MatchModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH /api/matches/{matchId}/score/
  Future<MatchModel> updateScore({
    required String matchId,
    required int entry1Points,
    required int entry2Points,
    required int version,
  }) async {
    final response = await _apiClient.dio.patch(
      ApiEndpoints.matchScore(matchId),
      data: UpdateScoreRequest(
        entry1Points: entry1Points,
        entry2Points: entry2Points,
        version: version,
      ).toJson(),
    );
    return MatchModel.fromJson(response.data as Map<String, dynamic>);
  }
}
