import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/index.dart';
import 'services/database_service.dart';
import 'services/id_service.dart';
import 'models/index.dart';

final _routes = {
  '/dashboard': (context) => const DashboardScreen(),
  '/register': (context) => const RegistrationScreen(),
  '/evacuees': (context) => const EvacueesScreen(),
  '/alerts': (context) => const AlertsScreen(),
  '/supplies': (context) => const SuppliesScreen(),
  '/sync': (context) => const SyncScreen(),
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US', null);

  await dotenv.load(fileName: 'assets/.env');

  // Initialize database
  await DatabaseService().database;
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']?.trim() ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '',
  );

  // Initialize sample data if needed
  await _initializeSampleData();

  /// Maruuu1101110:
  // Initialize MapBox access
  MapboxOptions.setAccessToken(dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '');

  // perission handler for location
  await Permission.locationWhenInUse.request();

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.black12,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: MainApp()));
}

Future<void> _initializeSampleData() async {
  final db = DatabaseService();
  final centerExists = await db.getCurrentCenter();

  if (centerExists == null) {
    // Create a sample evacuation center
    final sampleCenter = EvacuationCenter(
      id: IdService.newId(),
      name: 'Community Center - Downtown',
      latitude: 14.5995,
      longitude: 120.9842,
      totalCapacity: 500,
      currentOccupancy: 150,
      status: CenterStatus.operational,
      medicalAvailable: true,
      lastUpdated: DateTime.now(),
      synced: false,
    );

    await db.insertEvacuationCenter(sampleCenter);

    // Add sample supplies
    final supplies = [
      Supply(
        id: IdService.newId(),
        name: 'First Aid Kits',
        currentStock: 50,
        usageRatePerDay: 2,
        lastRestocked: DateTime.now(),
      ),
      Supply(
        id: IdService.newId(),
        name: 'Pain Relievers',
        currentStock: 200,
        usageRatePerDay: 10,
        lastRestocked: DateTime.now(),
      ),
      Supply(
        id: IdService.newId(),
        name: 'Bandages',
        currentStock: 500,
        usageRatePerDay: 25,
        lastRestocked: DateTime.now(),
      ),
    ];

    for (final supply in supplies) {
      await db.insertSupply(supply);
    }
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kalig Onan Evacuation System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(elevation: 2, centerTitle: true),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.light,
      home: const DashboardScreen(),
      routes: _routes,
    );
  }
}
