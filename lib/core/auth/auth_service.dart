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

    try {
      final userWithId = User(
        id: supabaseUser.id,
        username: user.username,
        email: user.email,
        dateOfBirth: user.dateOfBirth,
        createdAt: DateTime.now(),
      );
      await _supabase.from('users').insert(userToMap(userWithId));
      return response;
    } catch (e) {
      // Handle any errors that occur during user creation
      throw Exception('Failed to create user in database: $e');
    }
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
}
