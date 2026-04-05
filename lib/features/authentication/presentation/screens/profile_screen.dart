import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kalig_onan_evac_system/core/auth/auth_service.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    return Scaffold(
      // appBar: AppBar(title: const Text('Profile'), elevation: 0),
      body: currentUserAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No user found'));
          }
          // Extract first letter of first name from username (assume username is 'First Last' or just 'First')
          final firstName = user.username.split(' ').first;
          final firstLetter = firstName.isNotEmpty
              ? firstName[0].toUpperCase()
              : '?';
          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header with Avatar
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      // Avatar with first letter of first name
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            firstLetter,
                            style: const TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // User Name
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // User Email
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // User Information Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Phone Card
                      _buildInfoCard(
                        icon: Icons.phone,
                        title: 'Phone',
                        value: '+1 (555) 123-4567',
                        context: context,
                      ),
                      const SizedBox(height: 16),
                      // Location Card
                      _buildInfoCard(
                        icon: Icons.location_on,
                        title: 'Location',
                        value: user.fullAddress ?? 'N/A',
                        context: context,
                      ),
                      const SizedBox(height: 16),
                      // Status Card
                      _buildInfoCard(
                        icon: Icons.email,
                        title: 'Email',
                        value: user.email,
                        context: context,
                      ),
                      const SizedBox(height: 16),
                      // Status Card
                      _buildInfoCard(
                        icon: Icons.check_circle,
                        title: 'Status',
                        value: 'Active',
                        context: context,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Edit Profile Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Edit profile functionality coming soon',
                                ),
                              ),
                            );
                          },
                          child: const Text('Edit Profile'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        height: 52, // Matched height with your other buttons
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            // Use the error color to subtly indicate this is a destructive/exit action
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.error.withAlpha(50),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) {
                                final theme = Theme.of(dialogContext);
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  icon: Icon(
                                    Icons.logout_rounded,
                                    color: theme.colorScheme.error,
                                    size: 32,
                                  ),
                                  title: const Text('Confirm Logout'),
                                  content: const Text(
                                    'Are you sure you want to log out of your Kalig-onan account?',
                                    textAlign: TextAlign.center,
                                  ),
                                  actionsAlignment: MainAxisAlignment.center,
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.error,
                                        foregroundColor:
                                            theme.colorScheme.onError,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        Navigator.of(dialogContext).pop();

                                        final remoteLogoutSucceeded = await ref
                                            .read(authServiceProvider)
                                            .signOut();

                                        final prefs =
                                            await SharedPreferences.getInstance();
                                        await prefs.remove('offline_user_id');

                                        if (!remoteLogoutSucceeded &&
                                            context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'You were signed out locally. Remote logout will complete when you reconnect.',
                                              ),
                                            ),
                                          );
                                        }

                                        // 4. Send them back to the login screen
                                        if (context.mounted) {
                                          context.go('/login');
                                        }
                                      },
                                      child: const Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required BuildContext context,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(50),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 16),
            // Title and Value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
