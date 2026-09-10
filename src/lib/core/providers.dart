import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => authRepository);

/// Session hiện tại — S-00 dùng để quyết định vào H-01 hay S-01.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
