import 'package:go_router/go_router.dart';
import 'package:kalig_onan_evac_system/feature/maps_page.dart';
import 'package:kalig_onan_evac_system/feature/page/homePage.dart';
import '../../screens/index.dart';

final router = GoRouter(
  initialLocation: '/homePage',
  routes: [
    // MARU DEBUG //
    GoRoute(path: '/homePage', builder: (context, state) => const HomePage()),
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
    GoRoute(path: '/map', builder: (context, state) => const MapsPage()),
  ],
);
