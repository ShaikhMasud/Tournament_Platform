/// Central place for every REST path used from Phase 1 onward.
/// Keeps literal path strings out of repository bodies so there's exactly
/// one place to update if a route changes.
///
/// NOTE: these paths are relative to ApiClient's Dio baseUrl, which is
/// already `$baseUrl/api` (see ApiConfig.apiBase) — do NOT prefix these
/// with /api again, same convention auth_repository.dart already uses
/// ('/auth/signup', not '/api/auth/signup').
class ApiEndpoints {
  ApiEndpoints._();

  // --- Organizations ---
  static const String organizations = '/organizations/';
  static String organization(String id) => '/organizations/$id/';

  // --- Tournaments ---
  static const String tournaments = '/tournaments/';
  static String tournament(String id) => '/tournaments/$id/';

  // --- Categories (nested under a tournament) ---
  static String categories(String tournamentId) =>
      '/tournaments/$tournamentId/categories/';
  static String category(String tournamentId, String categoryId) =>
      '/tournaments/$tournamentId/categories/$categoryId/';

  // --- Courts (nested under a tournament) ---
  static String courts(String tournamentId) =>
      '/tournaments/$tournamentId/courts/';
  static String court(String tournamentId, String courtId) =>
      '/tournaments/$tournamentId/courts/$courtId/';

  // --- Entries ---
  static String entries(String categoryId) => '/categories/$categoryId/entries/';
  static String entry(String entryId) => '/entries/$entryId/';

  // --- Draws ---
  static String drawGenerate(String categoryId) => '/categories/$categoryId/draw/generate/';
  static String draw(String categoryId) => '/categories/$categoryId/draw/';

  // --- Matches ---
  static String matches(String tournamentId) => '/tournaments/$tournamentId/matches/';
  static String match(String matchId) => '/matches/$matchId/';
  static String matchSchedule(String matchId) => '/matches/$matchId/schedule/';
  static String matchStart(String matchId) => '/matches/$matchId/start/';
  static String matchScore(String matchId) => '/matches/$matchId/score/';

  // --- Results ---
  static String tournamentResults(String tournamentId) => '/tournaments/$tournamentId/results/pdf/';
  static String resultStatus(String docId) => '/results/$docId/status/';
  static String resultDownload(String docId) => '/results/$docId/download/';

  // --- WebSocket ---
  static String matchWebSocket(String matchId) => '/ws/matches/$matchId/';
}