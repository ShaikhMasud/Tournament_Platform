import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/result_document.dart';

class ResultsRepository {
  ResultsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// POST /api/tournaments/{tournamentId}/results/pdf/
  /// Request a new results PDF. Returns existing if already generated.
  Future<ResultDocument> requestResults(String tournamentId) async {
    final response = await _apiClient.dio.post(ApiEndpoints.tournamentResults(tournamentId));
    return ResultDocument.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /api/results/{docId}/status/
  Future<ResultDocument> getStatus(String docId) async {
    final response = await _apiClient.dio.get(ApiEndpoints.resultStatus(docId));
    return ResultDocument.fromJson(response.data as Map<String, dynamic>);
  }
}
