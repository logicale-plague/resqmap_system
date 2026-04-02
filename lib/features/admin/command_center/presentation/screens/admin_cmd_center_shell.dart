import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/screens/admin_evac_center_screens.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/screens/command_center_dashboard_screen.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/maps_page.dart';

class AdminShell extends StatefulWidget {
  final int initialIndex;

  const AdminShell({super.key, this.initialIndex = 0});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const List<String> titles = [
    'Command Center',
    'Evacuation Centers',
    'Map',
  ];

  static const List<Widget> screens = [
    CommandCenterDashboardScreen(),
    AdminEvacCenterScreens(), // Evacuation Centers Screen
    MapsPage(), // Map Screen
  ];

  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, screens.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            onPressed: () => context.go('/admin-init'),
            icon: Icon(Icons.home),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work_outlined),
            label: 'Centers',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        ],
      ),
    );
  }
}
