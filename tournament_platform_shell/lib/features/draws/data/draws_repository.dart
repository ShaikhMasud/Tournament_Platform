import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/draw.dart';

class DrawsRepository {
  DrawsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// GET /api/categories/{categoryId}/draw/
  Future<Draw?> getDraw(String categoryId) async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.draw(categoryId));
      return Draw.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// POST /api/categories/{categoryId}/draw/generate/
  Future<Draw> generateDraw({
    required String categoryId,
    String? format,
  }) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.drawGenerate(categoryId),
      data: DrawGenerateRequest(format: format).toJson(),
    );
    return Draw.fromJson(response.data as Map<String, dynamic>);
  }
}
