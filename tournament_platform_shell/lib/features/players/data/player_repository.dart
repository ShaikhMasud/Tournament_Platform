import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

/// Player-specific repository for accessing player entries and matches.
class PlayerRepository {
  PlayerRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Get tournaments this player has entries in.
  Future<List<PlayerTournament>> getMyTournaments() async {
    final response = await _apiClient.dio.get(ApiEndpoints.playerTournaments);
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((e) => PlayerTournament.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get entries for the current player.
  Future<List<PlayerEntry>> getMyEntries() async {
    final response = await _apiClient.dio.get(ApiEndpoints.playerEntries);
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((e) => PlayerEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get entry detail including bracket position.
  Future<PlayerEntryDetail> getEntryDetail(String entryId) async {
    final response = await _apiClient.dio.get('${ApiEndpoints.playerEntries}/$entryId');
    return PlayerEntryDetail.fromJson(response.data as Map<String, dynamic>);
  }
}

class PlayerTournament {
  PlayerTournament({
    required this.id,
    required this.name,
    required this.sport,
    required this.categoryName,
    required this.entryStatus,
    this.nextMatchId,
    this.nextMatchTime,
    this.nextMatchCourt,
  });

  final String id;
  final String name;
  final String sport;
  final String categoryName;
  final String entryStatus;
  final String? nextMatchId;
  final DateTime? nextMatchTime;
  final String? nextMatchCourt;

  factory PlayerTournament.fromJson(Map<String, dynamic> json) => PlayerTournament(
        id: json['id'] as String,
        name: json['name'] as String,
        sport: json['sport'] as String,
        categoryName: json['category_name'] as String? ?? '',
        entryStatus: json['entry_status'] as String? ?? 'unknown',
        nextMatchId: json['next_match_id'] as String?,
        nextMatchTime: json['next_match_time'] != null
            ? DateTime.parse(json['next_match_time'] as String)
            : null,
        nextMatchCourt: json['next_match_court'] as String?,
      );
}

class PlayerEntry {
  PlayerEntry({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.categoryId,
    required this.categoryName,
    required this.status,
    required this.drawStatus,
  });

  final String id;
  final String tournamentId;
  final String tournamentName;
  final String categoryId;
  final String categoryName;
  final String status;
  final String drawStatus;

  factory PlayerEntry.fromJson(Map<String, dynamic> json) => PlayerEntry(
        id: json['id'] as String,
        tournamentId: json['tournament_id'] as String,
        tournamentName: json['tournament_name'] as String,
        categoryId: json['category_id'] as String,
        categoryName: json['category_name'] as String,
        status: json['status'] as String,
        drawStatus: json['draw_status'] as String? ?? 'unknown',
      );
}

class PlayerEntryDetail {
  PlayerEntryDetail({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.categoryId,
    required this.categoryName,
    required this.status,
    required this.bracketPosition,
    this.nextMatchId,
    this.nextMatchTime,
    this.nextMatchCourt,
    this.nextOpponentName,
  });

  final String id;
  final String tournamentId;
  final String tournamentName;
  final String categoryId;
  final String categoryName;
  final String status;
  final int bracketPosition;
  final String? nextMatchId;
  final DateTime? nextMatchTime;
  final String? nextMatchCourt;
  final String? nextOpponentName;

  factory PlayerEntryDetail.fromJson(Map<String, dynamic> json) => PlayerEntryDetail(
        id: json['id'] as String,
        tournamentId: json['tournament_id'] as String,
        tournamentName: json['tournament_name'] as String,
        categoryId: json['category_id'] as String,
        categoryName: json['category_name'] as String,
        status: json['status'] as String,
        bracketPosition: json['bracket_position'] as int? ?? 0,
        nextMatchId: json['next_match_id'] as String?,
        nextMatchTime: json['next_match_time'] != null
            ? DateTime.parse(json['next_match_time'] as String)
            : null,
        nextMatchCourt: json['next_match_court'] as String?,
        nextOpponentName: json['next_opponent_name'] as String?,
      );
}
