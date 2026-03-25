import 'package:go_router/go_router.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/maps_page.dart';
import 'package:kalig_onan_evac_system/features/alerts/presentation/screens/alerts_screen.dart';
import '../indices/staff_screens_index.dart';
import '../indices/admin_screens_index.dart';

final router = GoRouter(
  initialLocation: '/centers',
  routes: [
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
    GoRoute(
      path: '/centers',
      builder: (context, state) => const CentersScreen(),
    ),
    GoRoute(path: '/sync', builder: (context, state) => const SyncScreen()),
    GoRoute(path: '/alerts', builder: (context, state) => const AlertsScreen()),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const VisualAnalyticsScreen(),
    ),
    GoRoute(
      path: '/monitoring',
      builder: (context, state) => const ResourceMonitoringScreen(),
    ),
    GoRoute(
      path: '/command-center',
      builder: (context, state) => const CommandCenterDashboardScreen(),
    ),
    GoRoute(path: '/map', builder: (context, state) => const MapsPage()),
  ],
);
