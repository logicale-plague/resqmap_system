import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kalig_onan_evac_system/core/utils/router.dart';
import 'package:kalig_onan_evac_system/features/staff/sync/presentation/providers/auto_sync_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US', null);
  await dotenv.load(fileName: "assets/.env");

  await DatabaseService().database;

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']?.trim() ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '',
  );

  /// Maruuu1101110:
  // Initialize MapBox access
  MapboxOptions.setAccessToken(dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '');

  // permission handler for location
  await Permission.locationWhenInUse.request();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 49, 121, 124),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(autoSyncBootstrapProvider);

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
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          iconTheme: IconThemeData(color: Colors.white, size: 28),
          centerTitle: true,
          backgroundColor: Color.fromARGB(255, 49, 121, 124),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
      // Dark theme seems broken right now
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(255, 49, 121, 124),
          secondary: Color.fromRGBO(50, 50, 50, 1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          iconTheme: IconThemeData(color: Colors.black, size: 28),
          centerTitle: true,
          backgroundColor: Color.fromARGB(255, 49, 121, 124),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 24),
        ),
      ),
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
