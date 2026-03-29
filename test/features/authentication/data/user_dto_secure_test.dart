import 'package:flutter_test/flutter_test.dart';
import 'package:kalig_onan_evac_system/core/services/user_pii_cipher.dart';
import 'package:kalig_onan_evac_system/features/authentication/data/user_dto.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';

void main() {
  group('User local secure DTO mapping', () {
    late UserPiiCipher cipher;

    setUp(() {
      cipher = UserPiiCipher(keyStore: InMemoryUserPiiKeyStore());
    });

    test('encrypts sensitive fields before local storage', () async {
      final user = User(
        id: 'u1',
        username: 'alice',
        email: 'alice@example.com',
        dateOfBirth: DateTime.parse('1990-05-01T00:00:00.000Z'),
        postalCode: '1000',
        fullAddress: 'Sample Street',
        role: UserPermission.staff,
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final map = await userToLocalDbMap(user, cipher: cipher);

      expect(map['email'], isNot(equals(user.email)));
      expect(
        map['dateOfBirth'],
        isNot(equals(user.dateOfBirth.toIso8601String())),
      );
      expect(map['postalCode'], isNot(equals(user.postalCode)));
      expect(map['fullAddress'], isNot(equals(user.fullAddress)));
      expect(cipher.isEncryptedPayload(map['email'] as String), isTrue);
      expect(cipher.isEncryptedPayload(map['dateOfBirth'] as String), isTrue);
      expect(cipher.isEncryptedPayload(map['postalCode'] as String), isTrue);
      expect(cipher.isEncryptedPayload(map['fullAddress'] as String), isTrue);
      expect(map['role'], equals('staff'));
    });

    test('decrypts sensitive fields on retrieval', () async {
      final user = User(
        id: 'u2',
        username: 'bob',
        email: 'bob@example.com',
        dateOfBirth: DateTime.parse('1988-02-02T00:00:00.000Z'),
        postalCode: '2000',
        fullAddress: 'Another Street',
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final encrypted = await userToLocalDbMap(user, cipher: cipher);
      final decrypted = await userFromLocalDbMap(encrypted, cipher: cipher);

      expect(decrypted.id, user.id);
      expect(decrypted.username, user.username);
      expect(decrypted.email, user.email);
      expect(decrypted.dateOfBirth, user.dateOfBirth);
      expect(decrypted.postalCode, user.postalCode);
      expect(decrypted.fullAddress, user.fullAddress);
      expect(decrypted.createdAt, user.createdAt);
    });

    test('supports key rotation and re-encryption', () async {
      final user = User(
        id: 'u3',
        username: 'carol',
        email: 'carol@example.com',
        dateOfBirth: DateTime.parse('1995-03-03T00:00:00.000Z'),
        postalCode: '3000',
        fullAddress: 'Third Street',
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final encryptedV1 = await userToLocalDbMap(user, cipher: cipher);
      expect((encryptedV1['email'] as String).startsWith('enc:v1:'), isTrue);

      await cipher.rotateToNextVersion();
      final encryptedV2 = await rotateLocalUserPiiFields(
        encryptedV1,
        cipher: cipher,
      );
      expect((encryptedV2['email'] as String).startsWith('enc:v2:'), isTrue);

      final decrypted = await userFromLocalDbMap(encryptedV2, cipher: cipher);
      expect(decrypted.email, user.email);
      expect(decrypted.dateOfBirth, user.dateOfBirth);
      expect(decrypted.postalCode, user.postalCode);
      expect(decrypted.fullAddress, user.fullAddress);
    });

    test('supports legacy ordinal role values on read', () async {
      final user = User(
        id: 'u4',
        username: 'dave',
        email: 'dave@example.com',
        dateOfBirth: DateTime.parse('1992-04-04T00:00:00.000Z'),
        fullAddress: 'Fourth Street',
        role: UserPermission.admin,
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final encrypted = await userToLocalDbMap(user, cipher: cipher);
      encrypted['role'] = 0;

      final decrypted = await userFromLocalDbMap(encrypted, cipher: cipher);
      expect(decrypted.role, UserPermission.admin);
    });

    test('throws clear error on unknown role code', () async {
      final user = User(
        id: 'u5',
        username: 'eve',
        email: 'eve@example.com',
        dateOfBirth: DateTime.parse('1993-06-06T00:00:00.000Z'),
        role: UserPermission.user,
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final encrypted = await userToLocalDbMap(user, cipher: cipher);
      encrypted['role'] = 'superadmin';

      expect(
        () => userFromLocalDbMap(encrypted, cipher: cipher),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Unknown user role code'),
          ),
        ),
      );
    });
  });
}
