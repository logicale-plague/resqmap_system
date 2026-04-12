import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/providers/user_provider.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/screens/access_list_screen.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/screens/home_screen.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/screens/profile_screen.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/maps_page.dart';

class UserShell extends ConsumerStatefulWidget {
  final int initialIndex;

  const UserShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<UserShell> createState() => _UserShellState();
}

class _UserShellState extends ConsumerState<UserShell> {
  late int _selectedIndex;

  final List<bool> _visitedTabs = [true, false, false, false];

  bool _canAccessManagement(UserPermission? role) {
    return role == UserPermission.admin || role == UserPermission.staff;
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _visitedTabs.length - 1);
    _visitedTabs[_selectedIndex] = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final role = ref
        .read(currentUserProvider)
        .maybeWhen(data: (user) => user?.role, orElse: () => null);
    _clampSelectedIndex(_canAccessManagement(role) ? 3 : 2);
  }

  void _clampSelectedIndex(int maxIndex) {
    if (_selectedIndex > maxIndex) {
      setState(() {
        _selectedIndex = maxIndex;
      });
    }
  }

  void _adjustSelectedIndexForManagementTabChange({
    required bool previousHasManagementTab,
    required bool nextHasManagementTab,
  }) {
    var nextIndex = _selectedIndex;

    if (!previousHasManagementTab && nextHasManagementTab && nextIndex >= 2) {
      nextIndex += 1;
    } else if (previousHasManagementTab && !nextHasManagementTab) {
      if (nextIndex > 2) {
        nextIndex -= 1;
      }
    }

    final maxIndex = nextHasManagementTab ? 3 : 2;
    if (nextIndex > maxIndex) {
      nextIndex = maxIndex;
    }

    if (nextIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = nextIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final role = currentUserAsync.maybeWhen(
      data: (user) => user?.role,
      orElse: () => null,
    );
    final hasManagementTab = _canAccessManagement(role);

    final pageTitles = [
      'Home',
      'Map',
      if (hasManagementTab) 'Management',
      'Profile',
    ];

    final effectiveIndex = _selectedIndex.clamp(0, pageTitles.length - 1);

    ref.listen<AsyncValue<User?>>(currentUserProvider, (previous, next) {
      final previousRole = previous?.maybeWhen(
        data: (user) => user?.role,
        orElse: () => null,
      );
      final nextRole = next.maybeWhen(
        data: (user) => user?.role,
        orElse: () => null,
      );
      _adjustSelectedIndexForManagementTabChange(
        previousHasManagementTab: _canAccessManagement(previousRole),
        nextHasManagementTab: _canAccessManagement(nextRole),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitles[effectiveIndex]),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),

      body: IndexedStack(
        index: effectiveIndex,
        children: [
          // Home is always rendered because _visitedTabs[0] is true
          _visitedTabs[0] ? const HomeScreen() : const SizedBox.shrink(),

          // MapsPage is just an empty box until they click the Map tab
          _visitedTabs[1] ? const MapsPage() : const SizedBox.shrink(),

          if (hasManagementTab)
            _visitedTabs[2]
                ? const AccessListScreen()
                : const SizedBox.shrink(),

          _visitedTabs[hasManagementTab ? 3 : 2]
              ? const ProfileScreen()
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          if (hasManagementTab)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Management',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: effectiveIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _visitedTabs[index] = true;
          });
        },
      ),
    );
  }
}
