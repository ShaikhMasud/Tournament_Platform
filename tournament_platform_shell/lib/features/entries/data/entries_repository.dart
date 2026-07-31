import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/entry.dart';

/// One page of entries, as returned by DRF's PageNumberPagination.
class EntryPage {
  final int count;
  final bool hasNext;
  final List<Entry> results;

  const EntryPage({
    required this.count,
    required this.hasNext,
    required this.results,
  });

  factory EntryPage.fromJson(Map<String, dynamic> json) => EntryPage(
        count: json['count'] as int,
        hasNext: json['next'] != null,
        results: (json['results'] as List)
            .map((e) => Entry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Thrown for a rejected add/remove so the UI can show the server's exact
/// reason (duplicate, full, locked, draw already finalized) instead of a
/// generic failure message.
class EntryActionException implements Exception {
  final int statusCode;
  final String message;
  const EntryActionException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class EntriesRepository {
  EntriesRepository(this._apiClient);

  final ApiClient _apiClient;

  /// GET /api/categories/{id}/entries/?search=&status=&page=
  Future<EntryPage> listEntries({
    required String categoryId,
    String? search,
    String? status,
    int page = 1,
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.entries(categoryId),
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
        'page': page,
      },
    );
    return EntryPage.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /api/categories/{id}/entries/add/
  /// Omit [playerId] to enter the caller's own player profile; pass it
  /// (Organizer/capable Assistant only) to add someone else.
  Future<Entry> addEntry({required String categoryId, int? playerId}) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiEndpoints.entries(categoryId)}add/',
        data: {if (playerId != null) 'player': playerId},
      );
      return Entry.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw EntryActionException(
        e.response?.statusCode ?? 0,
        _extractMessage(e.response?.data),
      );
    }
  }

  /// DELETE /api/entries/{id}/
  Future<void> removeEntry(String entryId) async {
    try {
      await _apiClient.dio.delete(ApiEndpoints.entry(entryId));
    } on DioException catch (e) {
      throw EntryActionException(
        e.response?.statusCode ?? 0,
        _extractMessage(e.response?.data),
      );
    }
  }

  String _extractMessage(dynamic data) {
    if (data == null) return 'Something went wrong.';
    if (data is String) return data;
    if (data is List && data.isNotEmpty) return data.first.toString();
    if (data is Map) {
      if (data['detail'] != null) return data['detail'].toString();
      // field-level validation errors, e.g. {"player": ["..."]}
      final firstValue = data.values.isNotEmpty ? data.values.first : null;
      if (firstValue is List && firstValue.isNotEmpty) {
        return firstValue.first.toString();
      }
    }
    return 'Something went wrong.';
  }
}
