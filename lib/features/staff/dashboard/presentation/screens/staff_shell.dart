import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/indices/provider_index.dart';
import 'package:kalig_onan_evac_system/core/indices/staff_screens_index.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/providers/user_provider.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/screens/profile_screen.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/maps_page.dart';

class StaffShell extends ConsumerStatefulWidget {
  final int initialIndex;

  const StaffShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends ConsumerState<StaffShell> {
  static const int _centersTabIndex = 0;
  static const int _syncTabIndex = 1;
  static const int _mapTabIndex = 2;
  static const int _profileTabIndex = 3;

  final List<Widget?> _pages = [
    CentersScreen(),
    SyncScreen(),
    null,
    ProfileScreen(),
  ];

  final List<bool> _visitedTabs = [true, false, false, false];

  static const List<String> _pageTitles = [
    'Centers',
    'Sync Status',
    'Map',
    'Profile',
  ];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _pages.length - 1);
    if (_selectedIndex == _mapTabIndex) {
      _ensureMapPageInitialized();
      _visitedTabs[_mapTabIndex] = true;
    }
  }

  void _ensureMapPageInitialized() {
    _pages[_mapTabIndex] ??= MapsPage();
  }

  void _refreshTabData(int index) {
    if (index == _centersTabIndex) {
      ref.invalidate(allCentersProvider);
      return;
    }

    if (index == _syncTabIndex) {
      ref
        ..invalidate(syncStatusProvider)
        ..invalidate(unsyncedCentersProvider)
        ..invalidate(unsyncedEvacueesProvider)
        ..invalidate(unsyncedSuppliesProvider);
      return;
    }

    if (index == _profileTabIndex) {
      ref.invalidate(currentUserProvider);
    }
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
        children: [
          for (int i = 0; i < _pages.length; i++)
            _visitedTabs[i]
                ? (_pages[i] ?? const SizedBox.shrink())
                : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          _refreshTabData(index);
          setState(() {
            _selectedIndex = index;
            _visitedTabs[index] = true;
            if (index == _mapTabIndex) {
              _ensureMapPageInitialized();
            }
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Centers'),
          BottomNavigationBarItem(icon: Icon(Icons.sync), label: 'Sync Status'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
