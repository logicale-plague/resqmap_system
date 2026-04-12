import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kalig_onan_evac_system/features/admin/access_management/application/access_management_service.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/providers/user_provider.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/domain/evacuation_center.dart';

class AccessManagementScreen extends ConsumerStatefulWidget {
  final String? initialCommandCenterId;

  const AccessManagementScreen({super.key, this.initialCommandCenterId});

  @override
  ConsumerState<AccessManagementScreen> createState() =>
      _AccessManagementScreenState();
}

class _AccessManagementScreenState
    extends ConsumerState<AccessManagementScreen> {
  final TextEditingController _emailController = TextEditingController();

  String? _selectedCommandCenterId;
  String? _selectedCenterId;
  UserPermission _selectedRole = UserPermission.admin;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCommandCenterId = widget.initialCommandCenterId;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onRoleChanged(UserPermission? role) {
    if (role == null) {
      return;
    }

    setState(() {
      _selectedRole = role;
      if (role != UserPermission.staff) {
        _selectedCenterId = null;
      }
    });
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();
    final commandCenterId = _selectedCommandCenterId;
    final role = _selectedRole;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final service = ref.read(adminAccessManagementServiceProvider);
      if (role == UserPermission.admin) {
        await service.assignUserToCommandCenter(
          email: email,
          commandCenterId: commandCenterId ?? '',
        );
      } else {
        await service.assignUserToEvacuationCenter(
          email: email,
          commandCenterId: commandCenterId ?? '',
          evacuationCenterId: _selectedCenterId ?? '',
        );
      }

      if (!mounted) {
        return;
      }

      if (commandCenterId != null && commandCenterId.isNotEmpty) {
        ref.invalidate(commandCenterAccessUsersProvider(commandCenterId));
        ref.invalidate(commandCenterStaffAccessUsersProvider(commandCenterId));
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            role == UserPermission.admin
                ? 'Command center access assigned for $email.'
                : 'Staff access assigned for $email.',
          ),
        ),
      );
      _emailController.clear();
      setState(() {
        _selectedCenterId = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: currentUserAsync.when(
        data: (currentUser) {
          if (currentUser?.role != UserPermission.admin) {
            return const Center(child: Text('Only admins can manage access.'));
          }

          final manageableCommandCentersAsync = ref.watch(
            manageableCommandCentersProvider,
          );
          final AsyncValue<List<EvacuationCenter>> manageableCentersAsync =
              _selectedCommandCenterId == null
              ? const AsyncValue.data(<EvacuationCenter>[])
              : ref.watch(
                  manageableEvacuationCentersByCommandCenterProvider(
                    _selectedCommandCenterId!,
                  ),
                );

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Manage access',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Assign admin or staff access for a managed command center. Staff access also requires an evacuation center.',
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'User email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<UserPermission>(
                            value: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'Access level',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: UserPermission.admin,
                                child: Text('admin'),
                              ),
                              DropdownMenuItem(
                                value: UserPermission.staff,
                                child: Text('staff'),
                              ),
                            ],
                            onChanged: _onRoleChanged,
                          ),
                          const SizedBox(height: 12),
                          manageableCommandCentersAsync.when(
                            data: (commandCenters) {
                              if (commandCenters.isEmpty) {
                                return const Text(
                                  'No managed command centers are available for your account.',
                                  style: TextStyle(color: Colors.red),
                                );
                              }

                              return DropdownButtonFormField<String>(
                                value: _selectedCommandCenterId,
                                decoration: const InputDecoration(
                                  labelText: 'Command center',
                                  border: OutlineInputBorder(),
                                ),
                                hint: const Text('Choose a command center'),
                                items: [
                                  for (final commandCenter in commandCenters)
                                    DropdownMenuItem(
                                      value: commandCenter.id,
                                      child: Text(commandCenter.name),
                                    ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCommandCenterId = value;
                                    _selectedCenterId = null;
                                  });
                                },
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: LinearProgressIndicator(),
                            ),
                            error: (error, _) => Text(
                              'Failed to load managed command centers: $error',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_selectedRole == UserPermission.staff) ...[
                            const SizedBox(height: 12),
                            manageableCentersAsync.when(
                              data: (centers) {
                                if (_selectedCommandCenterId == null) {
                                  return const Text(
                                    'Select a command center first.',
                                    style: TextStyle(color: Colors.red),
                                  );
                                }

                                if (centers.isEmpty) {
                                  return const Text(
                                    'No evacuation centers are available under the selected command center.',
                                    style: TextStyle(color: Colors.red),
                                  );
                                }

                                return DropdownButtonFormField<String>(
                                  value: _selectedCenterId,
                                  decoration: const InputDecoration(
                                    labelText: 'Evacuation center',
                                    border: OutlineInputBorder(),
                                  ),
                                  hint: const Text('Choose a center'),
                                  items: [
                                    for (final center in centers)
                                      DropdownMenuItem(
                                        value: center.id,
                                        child: Text(center.name),
                                      ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCenterId = value;
                                    });
                                  },
                                );
                              },
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: LinearProgressIndicator(),
                              ),
                              error: (error, _) => Text(
                                'Failed to load manageable centers: $error',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text('Save access'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Only command centers you manage are available here.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed to load current user: $error')),
      ),
    );
  }
}
