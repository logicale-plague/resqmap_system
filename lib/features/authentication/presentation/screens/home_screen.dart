import 'package:flutter/material.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/screens/profile_screen.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/maps_page.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final List<WidgetBuilder> _pageBuilders = [
    (_) => const Center(child: Text('Home', style: TextStyle(fontSize: 24))),
    (_) => MapsPage(),
    (_) =>
        const Center(child: Text('Settings', style: TextStyle(fontSize: 24))),
    (_) => ProfileScreen(),
  ];
  final Map<int, Widget> _pageCache = {};

  static const List<String> _pageTitles = [
    'Home',
    'Map',
    'Settings',
    'Profile',
  ];

  int _selectedIndex = 0;

  Widget _getPage(int index) {
    return _pageCache.putIfAbsent(index, () => _pageBuilders[index](context));
  }

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
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
