import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/screens/home_screen.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/screens/profile_screen.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/screens/admin_cmd_center_shell.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/screens/admin_init_shell.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/screens/user_shell.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/domain/evacuation_center.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/maps_page.dart';
import 'package:kalig_onan_evac_system/features/staff/dashboard/presentation/screens/staff_shell.dart';
import '../indices/staff_screens_index.dart';
import '../indices/admin_screens_index.dart';
import '../indices/auth_screens_index.dart';

final router = GoRouter(
  initialLocation: '/login',

  routes: [
    // auth routes
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),

    // admin routes
    GoRoute(
      path: '/admin-init',
      builder: (context, state) => const AdminInitShell(),
    ),
    GoRoute(
      path: '/admin-shell',
      builder: (context, state) {
        final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
        return AdminShell(initialIndex: tab);
      },
    ),
    GoRoute(
      path: '/command-center',
      builder: (context, state) => const CommandCenterDashboardScreen(),
    ),
    GoRoute(
      path: '/monitoring',
      builder: (context, state) => const ResourceMonitoringScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const VisualAnalyticsScreen(),
    ),

    // staff routes
    GoRoute(
      path: '/staff-shell',
      builder: (context, state) {
        final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
        return StaffShell(initialIndex: tab);
      },
    ),
    GoRoute(
      path: '/centers',
      builder: (context, state) => const CentersScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) {
        final center = state.extra as EvacuationCenter?;
        if (center == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No center data provided'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/staff-shell?tab=0'),
                    child: const Text('Back to Centers'),
                  ),
                ],
              ),
            ),
          );
        }

        return DashboardScreen(center: center);
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegistrationScreen(),
    ),
    GoRoute(
      path: '/evacuees',
      builder: (context, state) => const EvacueesScreen(),
    ),
    GoRoute(
      path: '/stations',
      builder: (context, state) => const StationsScreen(),
    ),
    GoRoute(
      path: '/supplies',
      builder: (context, state) => const SuppliesScreen(),
    ),
    GoRoute(path: '/sync', redirect: (context, state) => '/staff-shell?tab=1'),
    GoRoute(path: '/map', builder: (context, state) => const MapsPage()),
    GoRoute(path: '/userhome', builder: (context, state) => const UserShell()),
  ],
);
