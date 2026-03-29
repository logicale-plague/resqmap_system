import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/providers/supabase_provider.dart';
import 'package:kalig_onan_evac_system/core/providers/user_provider.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/authentication/data/user_dto.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

final authServiceProvider = Provider<AuthService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final db = ref.watch(databaseServiceProvider);
  return AuthService(supabase: supabase, databaseService: db);
});

class AuthService {
  final SupabaseClient _supabase;
  final DatabaseService _databaseService;

  AuthService({
    required SupabaseClient supabase,
    required DatabaseService databaseService,
  }) : _supabase = supabase,
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
      final cleanupNote = cleanupError == null
          ? ''
          : ' Cleanup failed: $cleanupError';
      throw Exception('Failed to create user profile: $e.$cleanupNote');
    }

    try {
      await _databaseService.insertUser(userWithId);
    } catch (e) {
      final profileCleanupError = await _deleteRemoteProfileSafely(
        supabaseUser.id,
      );
      final authCleanupError = await _deleteAuthUserSafely(supabaseUser.id);
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
    await _fetchAndStoreUser(supabaseUser.id);
    // await _fetchAndStoreUser(supabaseUser.id);

    return response;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> _fetchAndStoreUser(String userId) async {
    final data = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return;

    final user = userFromMap(data);
    await _databaseService.insertUser(user);
  }

  Future<String?> _deleteAuthUserSafely(String userId) async {
    try {
      await _supabase.auth.admin.deleteUser(userId);
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
