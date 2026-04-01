import 'package:flutter/material.dart';
import 'package:kalig_onan_evac_system/core/indices/staff_screens_index.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/screens/profile_screen.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/maps_page.dart';

class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  final List<WidgetBuilder> _pageBuilders = [
    (_) => DashboardScreen(),
    (_) => SyncScreen(),
    (_) => MapsPage(),
    (_) => ProfileScreen(),
  ];
  final Map<int, Widget> _pageCache = {};

  Widget _getPage(int index) {
    return _pageCache.putIfAbsent(index, () => _pageBuilders[index](context));
  }

  static const List<String> _pageTitles = [
    'Dashboard',
    'Sync Status',
    'Map',
    'Profile',
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(_pageBuilders.length, _getPage),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.sync), label: 'Sync Status'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
