import 'package:go_router/go_router.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/maps_page.dart';
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
      path: '/centers',
      builder: (context, state) => const CentersScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
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
    GoRoute(path: '/sync', builder: (context, state) => const SyncScreen()),
    GoRoute(path: '/map', builder: (context, state) => const MapsPage()),
  ],
);
