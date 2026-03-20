import '../../screens/index.dart';

final router = {
  '/dashboard': (context) => const DashboardScreen(),
  '/register': (context) => const RegistrationScreen(),
  '/evacuees': (context) => const EvacueesScreen(),
  '/alerts': (context) => const AlertsScreen(),
  '/supplies': (context) => const SuppliesScreen(),
  '/sync': (context) => const SyncScreen(),
};
