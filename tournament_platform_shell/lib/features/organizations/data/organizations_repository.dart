import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/organization.dart';

/// Only place in the app that calls ApiClient for organization endpoints.
/// Mirrors the pattern already established in lib/features/auth/'s
/// repository — screens and providers never touch Dio/ApiClient directly.
class OrganizationsRepository {
  OrganizationsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// GET /organizations/ — the caller's own organizations only.
  Future<List<Organization>> listMyOrganizations() async {
    final response = await _apiClient.dio.get(ApiEndpoints.organizations);
    final results = (response.data is List)
        ? response.data as List
        : (response.data['results'] as List); // DRF pagination wraps in this by default
    return results
        .map((json) => Organization.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// POST /organizations/ — create an org owned by the caller.
  Future<Organization> createOrganization({required String name}) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.organizations,
      data: {'name': name},
    );
    return Organization.fromJson(response.data as Map<String, dynamic>);
  }
}