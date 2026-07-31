import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/tournament_role.dart';

class RolesException implements Exception {
  RolesException(this.message);
  final String message;

  @override
  String toString() => message;
}

class RolesRepository {
  RolesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<TournamentRoleSummary>> listRoles(String tournamentId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.tournamentRoles(tournamentId),
      );
      return (response.data as List)
          .map((r) => TournamentRoleSummary.fromJson(r as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw RolesException(_extractError(e));
    }
  }

  Future<TournamentRoleSummary> assignRole({
    required String tournamentId,
    required String email,
    required String role,
    List<String>? capabilities,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.tournamentRoles(tournamentId),
        data: {
          'email': email,
          'role': role,
          if (capabilities != null) 'capabilities': capabilities,
        },
      );
      return TournamentRoleSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw RolesException(_extractError(e));
    }
  }

  Future<void> revokeRole({
    required String tournamentId,
    required String roleId,
  }) async {
    try {
      await _apiClient.dio.delete(
        ApiEndpoints.tournamentRole(tournamentId, roleId),
      );
    } on DioException catch (e) {
      throw RolesException(_extractError(e));
    }
  }

  Future<TournamentRoleSummary> updateCapabilities({
    required String tournamentId,
    required String roleId,
    required List<String> capabilities,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.tournamentRoleCapabilities(tournamentId, roleId),
        data: {'capabilities': capabilities},
      );
      return TournamentRoleSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw RolesException(_extractError(e));
    }
  }

  String _extractError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data.isNotEmpty) {
        final firstValue = data.values.first;
        if (firstValue is List && firstValue.isNotEmpty) return firstValue.first.toString();
        if (firstValue is String) return firstValue;
      }
    }
    return 'Something went wrong. Please check your connection and try again.';
  }
}
