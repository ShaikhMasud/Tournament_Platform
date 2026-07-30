import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart'; // apiClientProvider lives here
import '../data/organizations_repository.dart';
import '../models/organization.dart';

final organizationsRepositoryProvider = Provider<OrganizationsRepository>(
  (ref) => OrganizationsRepository(ref.watch(apiClientProvider)),
);

/// Holds the current user's organizations. Read by the tournament
/// creation screen to populate the "which org is this tournament under"
/// picker.
class OrganizationsNotifier extends AsyncNotifier<List<Organization>> {
  @override
  Future<List<Organization>> build() {
    return ref.read(organizationsRepositoryProvider).listMyOrganizations();
  }

  Future<void> createOrganization(String name) async {
    final repo = ref.read(organizationsRepositoryProvider);
    await repo.createOrganization(name: name);
    state = await AsyncValue.guard(() => repo.listMyOrganizations());
  }
}

final organizationsProvider =
    AsyncNotifierProvider<OrganizationsNotifier, List<Organization>>(
  OrganizationsNotifier.new,
);