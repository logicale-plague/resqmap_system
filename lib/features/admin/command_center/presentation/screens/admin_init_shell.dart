import 'package:flutter/material.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/screens/cmd_centers_screen.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/screens/profile_screen.dart';

class AdminInitShell extends StatefulWidget {
  const AdminInitShell({super.key});

  @override
  State<AdminInitShell> createState() => _AdminInitShellState();
}

class _AdminInitShellState extends State<AdminInitShell> {
  static const List<String> titles = ['Overview', 'Command Centers', 'Profile'];

  static const List<Widget> screens = [
    Center(child: Text('Overview', style: TextStyle(fontSize: 24))),
    CmdCentersScreen(), // Command Centers Management Placeholder
    ProfileScreen(), // Profile Screen Placeholder
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work_outlined),
            label: 'Centers',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
