import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/providers/user_provider.dart'
    show currentUserProvider;
import 'package:kalig_onan_evac_system/core/providers/supabase_provider.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/authentication/data/user_persistence_extensions.dart';
import 'package:kalig_onan_evac_system/features/authentication/data/user_dto.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

final authServiceProvider = Provider<AuthService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final db = ref.watch(databaseServiceProvider);
  return AuthService(ref: ref, supabase: supabase, databaseService: db);
});

class AuthService {
  final Ref _ref;
  final SupabaseClient _supabase;
  final DatabaseService _databaseService;

  AuthService({
    required Ref ref,
    required SupabaseClient supabase,
    required DatabaseService databaseService,
  }) : _ref = ref,
       _supabase = supabase,
       _databaseService = databaseService;

  Future<AuthResponse> signUp(User user, String password) async {
    final response = await _supabase.auth.signUp(
      email: user.email,
      password: password,
    );

    final supabaseUser = response.user;
    if (supabaseUser == null) {
      // Sign-up failed, return the response with error
      throw Exception('Failed to create user.');
    }

    final userWithId = User(
      id: supabaseUser.id,
      latitude: user.latitude,
      longitude: user.longitude,
      postalCode: user.postalCode,
      fullAddress: user.fullAddress,
      username: user.username,
      email: user.email,
      dateOfBirth: user.dateOfBirth,
      role: user.role,
      createdAt: DateTime.now(),
    );

    try {
      await _supabase.from('users').insert(userToMap(userWithId));
    } catch (e) {
      final cleanupError = await _deleteAuthUserSafely(supabaseUser.id);
      await _supabase.auth.signOut();
      final cleanupNote = cleanupError == null
          ? ''
          : ' Cleanup failed: $cleanupError';
      throw Exception('Failed to create user profile: $e.$cleanupNote');
    }

    try {
      await _persistCurrentUserLocally(userWithId, password: password);
    } catch (e) {
      final profileCleanupError = await _deleteRemoteProfileSafely(
        supabaseUser.id,
      );
      final authCleanupError = await _deleteAuthUserSafely(supabaseUser.id);
      await _supabase.auth.signOut();
      final cleanupMessages = <String>[
        if (profileCleanupError != null)
          'profile cleanup failed: $profileCleanupError',
        if (authCleanupError != null) 'auth cleanup failed: $authCleanupError',
      ];
      final cleanupNote = cleanupMessages.isEmpty
          ? ''
          : ' Cleanup failed: ${cleanupMessages.join('; ')}';
      throw Exception('Failed to persist local user profile: $e.$cleanupNote');
    }

    return response;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final supabaseUser = response.user;
    if (supabaseUser == null) {
      // Sign-in failed, return the response with error
      return response;
    }
    try {
      await _fetchAndStoreUser(supabaseUser.id, password: password);
    } catch (e) {
      await _supabase.auth.signOut();
      rethrow;
    }

    return response;
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } finally {
      await _databaseService.clearCurrentUser();
      _ref.invalidate(currentUserProvider);
    }
  }

  Future<void> _fetchAndStoreUser(String userId, {String? password}) async {
    final data = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) {
      throw StateError('User profile not found for ID: $userId');
    }

    final user = userFromMap(data);
    await _persistCurrentUserLocally(user, password: password);
  }

  Future<void> _persistCurrentUserLocally(User user, {String? password}) async {
    // Replace cached auth user in one transaction to avoid transient null reads.
    await _databaseService.replaceCurrentUser(user, password: password);
    _ref.invalidate(currentUserProvider);
  }

  Future<String?> _deleteAuthUserSafely(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'delete-user',
        body: {'userId': userId},
      );
      if (response.status != 200) {
        throw Exception('Server deletion failed: ${response.data}');
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> _deleteRemoteProfileSafely(String userId) async {
    try {
      await _supabase.from('users').delete().eq('id', userId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
