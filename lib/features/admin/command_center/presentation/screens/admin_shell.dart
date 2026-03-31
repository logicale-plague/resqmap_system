import 'package:flutter/material.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/screens/admin_evac_center_screens.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/screens/command_center_dashboard_screen.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/maps_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  List<String> titles = ['Command Center', 'Evacuation Centers', 'Map'];

  List<Widget> screens = [
    const CommandCenterDashboardScreen(),
    const AdminEvacCenterScreens(), // Evacuation Centers Screen
    const MapsPage(), // Map Screen
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titles[_currentIndex])),
      body: screens[_currentIndex],
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
        ],
      ),
    );
  }
}
