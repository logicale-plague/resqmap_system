import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/screens/admin_evac_center_screens.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/screens/command_center_dashboard_screen.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/screens/resource_monitoring_screen.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/screens/visual_analytics_screen.dart';

class AdminShell extends StatefulWidget {
  final int initialIndex;

  const AdminShell({super.key, this.initialIndex = 0});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const List<String> titles = [
    'Command Center',
    'Visual Analytics',
    'Resource Monitoring',
    'Evacuation Centers',
  ];

  static const List<Widget> screens = [
    CommandCenterDashboardScreen(),
    VisualAnalyticsScreen(), // Visual Analytics Screen
    ResourceMonitoringScreen(), // Resource Monitoring Screen
    AdminEvacCenterScreens(), // Evacuation Centers Screen
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
            onPressed: () => context.go('/userhome?tab=2'),
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
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart),
            label: 'Monitoring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work_outlined),
            label: 'Centers',
          ),
        ],
      ),
    );
  }
}
