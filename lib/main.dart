import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kalig_onan_evac_system/services/sync_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kalig_onan_evac_system/core/utils/router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US', null);
  await DatabaseService().database;

  await dotenv.load(fileName: "assets/.env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']?.trim() ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '',
  );

  // Initialize sample data if needed
  // await _initializeSampleData();

  await _startSync();

  /// Maruuu1101110:
  // Initialize MapBox access
  MapboxOptions.setAccessToken(dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '');

  // permission handler for location
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

Future<void> _startSync() async {
  final syncService = SyncService();
  syncService.setOnlineStatus(true);
}

// Future<void> _initializeSampleData() async {
//   final db = DatabaseService();
//   final centerExists = await db.getCurrentCenter();

//   if (centerExists == null) {
//     // Create a sample evacuation center
//     final sampleCenter = EvacuationCenter(
//       id: IdService.newId(),
//       name: 'Community Center - Downtown',
//       commandCenterId: 'ddd7cde1-e5e9-486f-88f8-86a40aecb508',
//       latitude: 14.5995,
//       longitude: 120.9842,
//       totalCapacity: 0,
//       currentOccupancy: 0,
//       status: CenterStatus.operational,
//       medicalAvailable: true,
//       lastUpdated: DateTime.now(),
//       synced: false,
//     );

//     await db.insertEvacuationCenter(sampleCenter);

//     final stations = [
//       Station(
//         id: IdService.newId(),
//         name: 'Station A - General',
//         evacuationCenterId: sampleCenter.id,
//         capacity: 200,
//       ),
//       Station(
//         id: IdService.newId(),
//         name: 'Station B - Children',
//         evacuationCenterId: sampleCenter.id,
//         capacity: 120,
//         allowedAgeGroup: AgeGroup.child,
//       ),
//       Station(
//         id: IdService.newId(),
//         name: 'Station C - Elderly Care',
//         evacuationCenterId: sampleCenter.id,
//         capacity: 90,
//         allowedAgeGroup: AgeGroup.elderly,
//       ),
//       Station(
//         id: IdService.newId(),
//         name: 'Station D - Serious Medical',
//         evacuationCenterId: sampleCenter.id,
//         capacity: 70,
//         allowedMedicalCondition: MedicalCondition.serious,
//       ),
//     ];

//     for (final station in stations) {
//       await db.insertStation(station);
//     }

//     // Add sample supplies
//     final supplies = [
//       Supply(
//         id: IdService.newId(),
//         evacuationCenterId: sampleCenter.id,
//         name: 'First Aid Kits',
//         currentStock: 50,
//         usageRatePerDay: 2,
//         lastRestocked: DateTime.now(),
//       ),
//       Supply(
//         id: IdService.newId(),
//         evacuationCenterId: sampleCenter.id,
//         name: 'Pain Relievers',
//         currentStock: 200,
//         usageRatePerDay: 10,
//         lastRestocked: DateTime.now(),
//       ),
//       Supply(
//         id: IdService.newId(),
//         evacuationCenterId: sampleCenter.id,
//         name: 'Bandages',
//         currentStock: 500,
//         usageRatePerDay: 25,
//         lastRestocked: DateTime.now(),
//       ),
//     ];

//     for (final supply in supplies) {
//       await db.insertSupply(supply);
//     }
//   }
// }

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Kalig Onan Evacuation System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(255, 49, 121, 124),
          secondary: Color.fromRGBO(222, 222, 222, 1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          titleSpacing: 0,
          iconTheme: IconThemeData(color: Colors.white, size: 28),
          centerTitle: true,
          backgroundColor: Color.fromARGB(255, 49, 121, 124),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          secondary: Color.fromRGBO(50, 50, 50, 1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
