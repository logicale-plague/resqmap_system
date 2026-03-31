import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/supabase_provider.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/providers/user_provider.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/screens/command_center_dashboard_screen.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/screens/home_screen.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/screens/login_screen.dart';
import 'package:kalig_onan_evac_system/features/staff/centers/presentation/screens/centers_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder(
      stream: ref.watch(supabaseProvider).auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;
        if (session != null) {
          // User is authenticated, show the main app
          final userAsync = ref.watch(currentUserProvider);
          return userAsync.when(
            data: (user) {
              if (user == null) {
                // This case can happen if the user is authenticated with Supabase but not found in local DB
                return const LoginScreen(
                  message:
                      'User not found in local database. Please log in again.',
                );
              }
              // User is authenticated and found in local DB, show the main app
              switch (user.role) {
                case UserPermission.admin:
                  return const CommandCenterDashboardScreen();
                case UserPermission.staff:
                  return const CentersScreen();
                case UserPermission.user:
                  return const UserHomeScreen();
              }
            },
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => const LoginScreen(
              message: 'An error occurred. Please try again.',
            ),
          );
        } else {
          // User is not authenticated, show the login screen
          return const LoginScreen(message: 'Please log in to continue.');
        }
      },
    );
  }
}
