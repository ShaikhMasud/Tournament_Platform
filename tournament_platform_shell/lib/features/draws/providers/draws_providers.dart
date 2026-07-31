import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/draws_repository.dart';
import '../models/draw.dart';

final drawsRepositoryProvider = Provider<DrawsRepository>(
  (ref) => DrawsRepository(ref.watch(apiClientProvider)),
);

/// One notifier per category id — fetches and caches the draw for that category.
class DrawNotifier extends FamilyAsyncNotifier<Draw?, String> {
  @override
  Future<Draw?> build(String categoryId) async {
    return ref.read(drawsRepositoryProvider).getDraw(categoryId);
  }

  Future<void> generate({String? format}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref.read(drawsRepositoryProvider).generateDraw(
            categoryId: arg,
            format: format,
          );
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(drawsRepositoryProvider).getDraw(arg),
    );
  }
}

final drawProvider = AsyncNotifierProvider.family<DrawNotifier, Draw?, String>(
  DrawNotifier.new,
);
