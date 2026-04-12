import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/providers/supabase_provider.dart';
import 'package:kalig_onan_evac_system/core/providers/user_provider.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/domain/command_center.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/providers/command_center_providers.dart';
import 'package:kalig_onan_evac_system/features/authentication/data/user_dto.dart';
import 'package:kalig_onan_evac_system/features/authentication/data/user_persistence_extensions.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/domain/evacuation_center.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/presentation/providers/evacuation_center_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:uuid/uuid.dart';

final adminUsersProvider = FutureProvider<List<User>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final rows = await supabase
      .from('users')
      .select()
      .order('created_at', ascending: false);

  return [
        for (final row in rows)
          userFromMap(Map<String, dynamic>.from(row as Map)),
      ]
      .where((user) {
        return user.role == UserPermission.user ||
            user.role == UserPermission.staff;
      })
      .toList(growable: false);
});

final commandCenterAccessUsersProvider =
    FutureProvider.family<List<User>, String>((ref, commandCenterId) async {
      final selectedCommandCenterId = commandCenterId.trim();
      if (selectedCommandCenterId.isEmpty) {
        return [];
      }

      final supabase = ref.watch(supabaseProvider);
      final accessRows = await supabase
          .from('user_cmd_centers')
          .select()
          .eq('cmd_center_id', selectedCommandCenterId)
          .eq('active', 1);
      if (accessRows.isEmpty) {
        return [];
      }

      final userIds = <String>{};
      for (final row in accessRows) {
        final rowMap = Map<String, dynamic>.from(row as Map);
        final userId = (rowMap['user_id'] ?? rowMap['userId'])?.toString();
        if (userId != null && userId.isNotEmpty) {
          userIds.add(userId);
        }
      }

      if (userIds.isEmpty) {
        return [];
      }

      final rows = await supabase.from('users').select();
      final users = [
        for (final row in rows)
          userFromMap(Map<String, dynamic>.from(row as Map)),
      ].where((user) => userIds.contains(user.id)).toList(growable: false);
      users.sort((a, b) => a.username.compareTo(b.username));
      return users;
    });

class StaffAccessUserWithCenters {
  final User user;
  final List<EvacuationCenter> evacuationCenters;

  const StaffAccessUserWithCenters({
    required this.user,
    required this.evacuationCenters,
  });
}

final commandCenterStaffAccessUsersProvider =
    FutureProvider.family<List<StaffAccessUserWithCenters>, String>((
      ref,
      commandCenterId,
    ) async {
      final selectedCommandCenterId = commandCenterId.trim();
      if (selectedCommandCenterId.isEmpty) {
        return [];
      }

      final manageableCenters = await ref.watch(
        manageableEvacuationCentersByCommandCenterProvider(
          selectedCommandCenterId,
        ).future,
      );
      if (manageableCenters.isEmpty) {
        return [];
      }

      final allowedCenterIds = manageableCenters
          .map((center) => center.id)
          .toSet();
      final centerLookup = {
        for (final center in manageableCenters) center.id: center,
      };

      final supabase = ref.watch(supabaseProvider);
      final accessRows = await supabase
          .from('user_evac_centers')
          .select()
          .eq('active', 1);

      final userToCenterIds = <String, Set<String>>{};
      for (final row in accessRows) {
        final rowMap = Map<String, dynamic>.from(row as Map);
        final userId = (rowMap['user_id'] ?? rowMap['userId'])?.toString();
        final centerId =
            (rowMap['evac_center_id'] ?? rowMap['evacuationCenterId'])
                ?.toString();
        if (userId == null ||
            userId.isEmpty ||
            centerId == null ||
            centerId.isEmpty) {
          continue;
        }
        if (!allowedCenterIds.contains(centerId)) {
          continue;
        }
        userToCenterIds.putIfAbsent(userId, () => <String>{}).add(centerId);
      }

      if (userToCenterIds.isEmpty) {
        return [];
      }

      final userRows = await supabase.from('users').select();
      final usersById = <String, User>{};
      for (final row in userRows) {
        final user = userFromMap(Map<String, dynamic>.from(row as Map));
        if (user.role == UserPermission.staff) {
          usersById[user.id] = user;
        }
      }

      final items = <StaffAccessUserWithCenters>[];
      for (final entry in userToCenterIds.entries) {
        final user = usersById[entry.key];
        if (user == null) {
          continue;
        }

        final centers = [
          for (final centerId in entry.value)
            if (centerLookup.containsKey(centerId)) centerLookup[centerId]!,
        ]..sort((a, b) => a.name.compareTo(b.name));

        if (centers.isEmpty) {
          continue;
        }

        items.add(
          StaffAccessUserWithCenters(user: user, evacuationCenters: centers),
        );
      }

      items.sort((a, b) => a.user.username.compareTo(b.user.username));
      return items;
    });

final manageableCommandCentersProvider = FutureProvider<List<CommandCenter>>((
  ref,
) async {
  return ref.watch(assignedCommandCentersProvider.future);
});

final manageableEvacuationCentersProvider =
    FutureProvider<List<EvacuationCenter>>((ref) async {
      final assignedCommandCenters = await ref.watch(
        assignedCommandCentersProvider.future,
      );
      if (assignedCommandCenters.isEmpty) {
        return [];
      }

      final uniqueCenters = <String, EvacuationCenter>{};
      for (final commandCenter in assignedCommandCenters) {
        final centers = await ref.watch(
          centersByCommandCenterProvider(commandCenter.id).future,
        );
        for (final center in centers) {
          uniqueCenters[center.id] = center;
        }
      }

      final values = uniqueCenters.values.toList(growable: false)
        ..sort((a, b) => a.name.compareTo(b.name));
      return values;
    });

final manageableEvacuationCentersByCommandCenterProvider =
    FutureProvider.family<List<EvacuationCenter>, String>((
      ref,
      commandCenterId,
    ) async {
      final manageableCommandCenters = await ref.watch(
        manageableCommandCentersProvider.future,
      );
      final canManageCommandCenter = manageableCommandCenters.any(
        (center) => center.id == commandCenterId,
      );
      if (!canManageCommandCenter) {
        return [];
      }

      final centers = await ref.watch(
        centersByCommandCenterProvider(commandCenterId).future,
      );
      centers.sort((a, b) => a.name.compareTo(b.name));
      return centers;
    });

final adminAccessManagementServiceProvider =
    Provider<AdminAccessManagementService>((ref) {
      final supabase = ref.watch(supabaseProvider);
      final databaseService = ref.watch(databaseServiceProvider);
      return AdminAccessManagementService(
        ref: ref,
        supabase: supabase,
        databaseService: databaseService,
      );
    });

class AdminAccessManagementService {
  final Ref _ref;
  final SupabaseClient _supabase;
  final DatabaseService _databaseService;

  AdminAccessManagementService({
    required Ref ref,
    required SupabaseClient supabase,
    required DatabaseService databaseService,
  }) : _ref = ref,
       _supabase = supabase,
       _databaseService = databaseService;

  Future<User> assignUserToEvacuationCenter({
    required String email,
    required String commandCenterId,
    required String evacuationCenterId,
  }) async {
    final currentUser = await _requireAdmin();
    final targetUser = await _getUserByEmail(email);
    if (targetUser == null) {
      throw StateError(
        'No user profile found for that email. Ask the person to create an account first.',
      );
    }

    if (targetUser.role == UserPermission.admin) {
      throw StateError('Admin accounts are not managed from this page.');
    }

    final selectedCommandCenterId = _validateAndTrimCommandCenterId(
      commandCenterId,
    );
    final centerId = evacuationCenterId.trim();
    if (centerId.isEmpty) {
      throw ArgumentError('Select an evacuation center for staff access.');
    }

    await _ensureManagedCommandCenter(selectedCommandCenterId);
    await _ensureManagedEvacuationCenter(selectedCommandCenterId, centerId);

    final relationshipAlreadyExists = await _relationshipAlreadyExists(
      userId: targetUser.id,
      evacuationCenterId: centerId,
    );

    await _supabase
        .from('users')
        .update({'role': UserPermission.staff.toCode()})
        .eq('id', targetUser.id);

    if (relationshipAlreadyExists) {
      await _supabase
          .from('user_evac_centers')
          .update({'active': 1})
          .eq('user_id', targetUser.id)
          .eq('evacuation_center_id', centerId);
      await _databaseService.setUserEvacuationCenterAccessActive(
        targetUser.id,
        centerId,
        true,
      );
    } else {
      await _supabase.from('user_evac_centers').insert({
        'id': const Uuid().v4(),
        'user_id': targetUser.id,
        'evacuation_center_id': centerId,
        'active': 1,
      });

      await _databaseService.insertUserEvacCenterAccessRow(
        userId: targetUser.id,
        evacuationCenterId: centerId,
        active: true,
      );
    }

    final updatedUser = targetUser.copyWith(role: UserPermission.staff);
    if (currentUser.id == targetUser.id) {
      await _databaseService.replaceCurrentUser(updatedUser);
      _ref.invalidate(currentUserProvider);
    }

    _ref.invalidate(adminUsersProvider);
    return updatedUser;
  }

  Future<User> assignUserToCommandCenter({
    required String email,
    required String commandCenterId,
  }) async {
    final currentUser = await _requireAdmin();

    final targetUser = await _getUserByEmail(email);
    if (targetUser == null) {
      throw StateError(
        'No user profile found for that email. Ask the person to create an account first.',
      );
    }

    if (targetUser.role == UserPermission.admin) {
      throw StateError('Admin accounts are not managed from this page.');
    }

    final selectedCommandCenterId = _validateAndTrimCommandCenterId(
      commandCenterId,
    );
    await _ensureManagedCommandCenter(selectedCommandCenterId);

    final relationshipAlreadyExists =
        await _commandCenterRelationshipAlreadyExists(
          userId: targetUser.id,
          commandCenterId: selectedCommandCenterId,
        );

    await _supabase
        .from('users')
        .update({'role': UserPermission.admin.toCode()})
        .eq('id', targetUser.id);

    if (relationshipAlreadyExists) {
      await _supabase
          .from('user_cmd_centers')
          .update({'active': 1})
          .eq('user_id', targetUser.id)
          .eq('cmd_center_id', selectedCommandCenterId);
      await _databaseService.setUserCommandCenterAccessActive(
        targetUser.id,
        selectedCommandCenterId,
        true,
      );
    } else {
      await _supabase.from('user_cmd_centers').insert({
        'id': const Uuid().v4(),
        'user_id': targetUser.id,
        'cmd_center_id': selectedCommandCenterId,
        'active': 1,
      });

      await _databaseService.insertUserCommandCenterAccessRow(
        userId: targetUser.id,
        commandCenterId: selectedCommandCenterId,
        active: true,
      );
    }

    final updatedUser = targetUser.copyWith(role: UserPermission.admin);
    if (currentUser.id == targetUser.id) {
      await _databaseService.replaceCurrentUser(updatedUser);
      _ref.invalidate(currentUserProvider);
    }

    _ref.invalidate(adminUsersProvider);
    return updatedUser;
  }

  Future<void> setEvacuationCenterAccessActive({
    required String userId,
    required String commandCenterId,
    required String evacuationCenterId,
    required bool active,
  }) async {
    final currentUser = await _ref.read(currentUserProvider.future);
    if (currentUser?.role != UserPermission.admin) {
      throw StateError('Only admins can manage access.');
    }

    final selectedCommandCenterId = commandCenterId.trim();
    if (selectedCommandCenterId.isEmpty) {
      throw ArgumentError('Select a command center.');
    }

    final centerId = evacuationCenterId.trim();
    if (centerId.isEmpty) {
      throw ArgumentError('Select an evacuation center.');
    }

    final manageableCommandCenters = await _ref.read(
      manageableCommandCentersProvider.future,
    );
    final canManageCommandCenter = manageableCommandCenters.any(
      (center) => center.id == selectedCommandCenterId,
    );
    if (!canManageCommandCenter) {
      throw StateError(
        'You can only update access under command centers you manage.',
      );
    }

    final manageableCentersForCommandCenter = await _ref.read(
      manageableEvacuationCentersByCommandCenterProvider(
        selectedCommandCenterId,
      ).future,
    );
    final canManageCenter = manageableCentersForCommandCenter.any(
      (center) => center.id == centerId,
    );
    if (!canManageCenter) {
      throw StateError(
        'Selected evacuation center does not belong to the selected command center you manage.',
      );
    }

    final activeValue = active ? 1 : 0;
    final remoteRows = await _supabase
        .from('user_evac_centers')
        .select('id')
        .eq('user_id', userId)
        .eq('evacuation_center_id', centerId);
    if (remoteRows.isEmpty) {
      throw StateError('No evacuation center access row exists for that user.');
    }

    await _supabase
        .from('user_evac_centers')
        .update({'active': activeValue})
        .eq('user_id', userId)
        .eq('evacuation_center_id', centerId);

    await _databaseService.setUserEvacuationCenterAccessActive(
      userId,
      centerId,
      active,
    );

    _ref.invalidate(adminUsersProvider);
  }

  Future<void> setCommandCenterAccessActive({
    required String userId,
    required String commandCenterId,
    required bool active,
  }) async {
    final currentUser = await _ref.read(currentUserProvider.future);
    if (currentUser?.role != UserPermission.admin) {
      throw StateError('Only admins can manage access.');
    }

    final selectedCommandCenterId = commandCenterId.trim();
    if (selectedCommandCenterId.isEmpty) {
      throw ArgumentError('Select a command center.');
    }

    final manageableCommandCenters = await _ref.read(
      manageableCommandCentersProvider.future,
    );
    final canManageCommandCenter = manageableCommandCenters.any(
      (center) => center.id == selectedCommandCenterId,
    );
    if (!canManageCommandCenter) {
      throw StateError(
        'You can only update access under command centers you manage.',
      );
    }

    final remoteRows = await _supabase
        .from('user_cmd_centers')
        .select('id')
        .eq('user_id', userId)
        .eq('cmd_center_id', selectedCommandCenterId);
    if (remoteRows.isEmpty) {
      throw StateError('No command center access row exists for that user.');
    }

    await _supabase
        .from('user_cmd_centers')
        .update({'active': active ? 1 : 0})
        .eq('user_id', userId)
        .eq('cmd_center_id', selectedCommandCenterId);

    await _databaseService.setUserCommandCenterAccessActive(
      userId,
      selectedCommandCenterId,
      active,
    );

    _ref.invalidate(adminUsersProvider);
  }

  Future<void> removeCommandCenterAccess({
    required String userId,
    required String commandCenterId,
  }) async {
    final currentUser = await _requireAdmin();
    final selectedCommandCenterId = commandCenterId.trim();
    if (selectedCommandCenterId.isEmpty) {
      throw ArgumentError('Select a command center.');
    }

    final manageableCommandCenters = await _ref.read(
      manageableCommandCentersProvider.future,
    );
    final canManageCommandCenter = manageableCommandCenters.any(
      (center) => center.id == selectedCommandCenterId,
    );
    if (!canManageCommandCenter) {
      throw StateError(
        'You can only update access under command centers you manage.',
      );
    }

    final remoteRows = await _supabase
        .from('user_cmd_centers')
        .select('id, active')
        .eq('user_id', userId)
        .eq('cmd_center_id', selectedCommandCenterId)
        .limit(1);
    if (remoteRows.isEmpty) {
      throw StateError('No command center access row exists for that user.');
    }

    await _supabase
        .from('user_cmd_centers')
        .update({'active': 0})
        .eq('user_id', userId)
        .eq('cmd_center_id', selectedCommandCenterId);

    await _databaseService.setUserCommandCenterAccessActive(
      userId,
      selectedCommandCenterId,
      false,
    );

    final hasActiveEvacAccess = await _hasAnyActiveEvacuationAccess(userId);
    final nextRole = hasActiveEvacAccess
        ? UserPermission.staff
        : UserPermission.user;
    await _supabase
        .from('users')
        .update({'role': nextRole.toCode()})
        .eq('id', userId);

    if (currentUser.id == userId) {
      final current = currentUser.copyWith(role: nextRole);
      await _databaseService.replaceCurrentUser(current);
      _ref.invalidate(currentUserProvider);
    }

    _ref.invalidate(commandCenterAccessUsersProvider(selectedCommandCenterId));
    _ref.invalidate(
      commandCenterStaffAccessUsersProvider(selectedCommandCenterId),
    );
    _ref.invalidate(adminUsersProvider);
  }

  Future<void> removeEvacuationCenterAccess({
    required String userId,
    required String commandCenterId,
    required String evacuationCenterId,
  }) async {
    final currentUser = await _requireAdmin();

    final selectedCommandCenterId = commandCenterId.trim();
    if (selectedCommandCenterId.isEmpty) {
      throw ArgumentError('Select a command center.');
    }

    final centerId = evacuationCenterId.trim();
    if (centerId.isEmpty) {
      throw ArgumentError('Select an evacuation center.');
    }

    await _ensureManagedCommandCenter(selectedCommandCenterId);
    await _ensureManagedEvacuationCenter(selectedCommandCenterId, centerId);

    final remoteRows = await _supabase
        .from('user_evac_centers')
        .select('id, active')
        .eq('user_id', userId)
        .eq('evac_center_id', centerId)
        .limit(1);
    if (remoteRows.isEmpty) {
      throw StateError('No evacuation center access row exists for that user.');
    }

    await _supabase
        .from('user_evac_centers')
        .update({'active': 0})
        .eq('user_id', userId)
        .eq('evac_center_id', centerId);

    await _databaseService.setUserEvacuationCenterAccessActive(
      userId,
      centerId,
      false,
    );

    final hasActiveEvacAccess = await _hasAnyActiveEvacuationAccess(userId);
    final nextRole = hasActiveEvacAccess
        ? UserPermission.staff
        : UserPermission.user;
    await _supabase
        .from('users')
        .update({'role': nextRole.toCode()})
        .eq('id', userId);

    if (currentUser.id == userId) {
      final current = currentUser.copyWith(role: nextRole);
      await _databaseService.replaceCurrentUser(current);
      _ref.invalidate(currentUserProvider);
    }

    _ref.invalidate(commandCenterAccessUsersProvider(selectedCommandCenterId));
    _ref.invalidate(
      commandCenterStaffAccessUsersProvider(selectedCommandCenterId),
    );
    _ref.invalidate(adminUsersProvider);
  }

  Future<User?> _getUserByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw ArgumentError('Email is required.');
    }

    final targetRow = await _supabase
        .from('users')
        .select()
        .ilike('email', normalizedEmail)
        .maybeSingle();
    if (targetRow == null) {
      return null;
    }

    return userFromMap(Map<String, dynamic>.from(targetRow as Map));
  }

  Future<User> _requireAdmin() async {
    final currentUser = await _ref.read(currentUserProvider.future);
    if (currentUser?.role != UserPermission.admin) {
      throw StateError('Only admins can manage access.');
    }
    return currentUser!;
  }

  Future<void> _ensureManagedCommandCenter(String commandCenterId) async {
    final manageableCommandCenters = await _ref.read(
      manageableCommandCentersProvider.future,
    );
    final canManageCommandCenter = manageableCommandCenters.any(
      (center) => center.id == commandCenterId,
    );
    if (!canManageCommandCenter) {
      throw StateError(
        'You can only manage command centers you are assigned to.',
      );
    }
  }

  Future<void> _ensureManagedEvacuationCenter(
    String commandCenterId,
    String evacuationCenterId,
  ) async {
    final manageableCentersForCommandCenter = await _ref.read(
      manageableEvacuationCentersByCommandCenterProvider(
        commandCenterId,
      ).future,
    );
    final canManageCenter = manageableCentersForCommandCenter.any(
      (center) => center.id == evacuationCenterId,
    );
    if (!canManageCenter) {
      throw StateError(
        'Selected evacuation center does not belong to the selected command center you manage.',
      );
    }
  }

  String _validateAndTrimCommandCenterId(String commandCenterId) {
    final selectedCommandCenterId = commandCenterId.trim();
    if (selectedCommandCenterId.isEmpty) {
      throw ArgumentError('Select a command center.');
    }
    return selectedCommandCenterId;
  }

  Future<bool> _commandCenterRelationshipAlreadyExists({
    required String userId,
    required String commandCenterId,
  }) async {
    final localRows = await _databaseService.getUserCommandCenterAccessRows(
      userId,
      includeInactive: true,
    );
    if (localRows.any((row) {
      final rowCommandCenterId =
          (row['commandCenterId'] ?? row['cmd_center_id'])?.toString();
      return rowCommandCenterId == commandCenterId;
    })) {
      return true;
    }

    final remoteRows = await _supabase
        .from('user_cmd_centers')
        .select('id, active')
        .eq('user_id', userId)
        .eq('cmd_center_id', commandCenterId)
        .limit(1);
    return remoteRows.isNotEmpty;
  }

  Future<bool> _relationshipAlreadyExists({
    required String userId,
    required String evacuationCenterId,
  }) async {
    final localRows = await _databaseService.getUserEvacuationCenterAccessRows(
      userId,
      includeInactive: true,
    );
    if (localRows.any((row) {
      final rowCenterId = (row['evacuationCenterId'] ?? row['evac_center_id'])
          ?.toString();
      return rowCenterId == evacuationCenterId;
    })) {
      return true;
    }

    final remoteRows = await _supabase
        .from('user_evac_centers')
        .select('id, active')
        .eq('user_id', userId)
        .eq('evac_center_id', evacuationCenterId)
        .limit(1);
    return remoteRows.isNotEmpty;
  }

  Future<bool> _hasAnyActiveEvacuationAccess(String userId) async {
    final localRows = await _databaseService.getUserEvacuationCenterAccessRows(
      userId,
    );
    if (localRows.isNotEmpty) {
      return true;
    }

    final remoteRows = await _supabase
        .from('user_evac_centers')
        .select('id')
        .eq('user_id', userId)
        .eq('active', 1)
        .limit(1);
    return remoteRows.isNotEmpty;
  }
}
