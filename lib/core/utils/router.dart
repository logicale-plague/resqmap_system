import 'package:go_router/go_router.dart';
import '../../admin_screens/index.dart';
import '../../screens/index.dart';

final router = GoRouter(
  initialLocation: '/command-center',
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
    GoRoute(path: '/sync', builder: (context, state) => const SyncScreen()),
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
  ],
);
