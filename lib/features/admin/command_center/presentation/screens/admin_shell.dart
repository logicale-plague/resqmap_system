import 'package:flutter/material.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/screens/admin_evac_center_screens.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/screens/command_center_dashboard_screen.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/screens/profile_screen.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/maps_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const List<String> titles = [
    'Command Center',
    'Evacuation Centers',
    'Map',
    'Profile',
  ];

  static const List<Widget> screens = [
    CommandCenterDashboardScreen(),
    AdminEvacCenterScreens(), // Evacuation Centers Screen
    MapsPage(), // Map Screen
    ProfileScreen(), // Profile Screen
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titles[_currentIndex])),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_work_outlined),
            label: 'Centers',
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
