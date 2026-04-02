import 'package:flutter/material.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/screens/profile_screen.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/maps_page.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  late final List<Widget> _pages = [
    const Center(child: Text('Home', style: TextStyle(fontSize: 24))),
    MapsPage(),
    const Center(child: Text('Settings', style: TextStyle(fontSize: 24))),
    ProfileScreen(),
  ];

  static const List<String> _pageTitles = [
    'Home',
    'Map',
    'Settings',
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
      // Render only the active page from _selectedIndex instead of using
      // IndexedStack, so heavy pages like MapsPage are not kept mounted.
      // If _pageBuilders/_getPage are reintroduced later, decide explicitly
      // whether preserving tab state is worth the memory tradeoff.
      body: _pages[_selectedIndex],
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
