import 'package:beewise/services/auth_service.dart';
import 'package:beewise/services/tutor_application_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuth extends Mock implements FirebaseAuth {}

class MockFirestore extends Mock implements FirebaseFirestore {}

class MockUser extends Mock implements User {}

class MockCredential extends Mock implements UserCredential {}

// Firestore marks these types sealed for production, but services require SDK
// doubles to reproduce network/profile failures without a live Firebase account.
// ignore: subtype_of_sealed_class
class MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocument extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockAuth auth;
  late MockFirestore store;
  late MockUser user;
  late MockCredential credential;
  late MockDocument parent;
  late MockDocument application;
  late MockSnapshot profileSnapshot;
  late MockSnapshot applicationSnapshot;
  late FirebaseAuthService service;
  setUp(() {
    auth = MockAuth();
    store = MockFirestore();
    user = MockUser();
    credential = MockCredential();
    parent = MockDocument();
    application = MockDocument();
    profileSnapshot = MockSnapshot();
    applicationSnapshot = MockSnapshot();
    final parents = MockCollection();
    final applications = MockCollection();
    when(() => store.collection('parents')).thenReturn(parents);
    when(() => store.collection('tutorApplications')).thenReturn(applications);
    when(() => parents.doc('alice')).thenReturn(parent);
    when(() => applications.doc('alice')).thenReturn(application);
    when(() => user.uid).thenReturn('alice');
    when(() => user.email).thenReturn('alice@example.test');
    when(() => user.displayName).thenReturn('Alice');
    when(() => credential.user).thenReturn(user);
    when(() => user.updateDisplayName(any())).thenAnswer((_) async {});
    when(
      () => auth.createUserWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => credential);
    when(
      () => auth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => credential);
    when(() => parent.get()).thenAnswer((_) async => profileSnapshot);
    when(() => application.get(const GetOptions(source: Source.server)))
        .thenAnswer((_) async => applicationSnapshot);
    when(() => profileSnapshot.exists).thenReturn(false);
    when(() => applicationSnapshot.exists).thenReturn(false);
    when(() => parent.set(any(), any())).thenAnswer((_) async {});
    service = FirebaseAuthService(auth, store);
  });
  Future<UserCredential> register() => service.registerParent(
    name: 'Alice',
    email: 'alice@example.test',
    phone: '0900000000',
    password: 'test-only-password',
  );
  test(
    'email login bootstraps an absent parent only after its role lookup',
    () async {
      expect(
        await service.signInWithEmail(
          ' Alice@Example.test ',
          'test-only-password',
        ),
        same(credential),
      );
      verifyInOrder([
        () => auth.signInWithEmailAndPassword(
          email: 'alice@example.test',
          password: 'test-only-password',
        ),
        () => application.get(const GetOptions(source: Source.server)),
        () => parent.get(),
        () => parent.set(any(), any()),
      ]);
      verifyNever(() => user.delete());
    },
  );
  test('role retry never uses cached absence after a server error', () async {
    final roles = TutorApplicationService(auth, store);
    when(() => application.get(const GetOptions(source: Source.server)))
        .thenThrow(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        );
    await expectLater(
      roles.hasApplication('alice'),
      throwsA(isA<FirebaseException>()),
    );
    verifyNever(() => parent.set(any(), any()));
    when(() => applicationSnapshot.exists).thenReturn(true);
    when(() => application.get(const GetOptions(source: Source.server)))
        .thenAnswer((_) async => applicationSnapshot);
    expect(await roles.hasApplication('alice'), isTrue);
    verifyNever(() => application.get());
    verifyNever(() => parent.set(any(), any()));
  });
  test(
    'post-auth role permission denial never bypasses parent separation',
    () async {
      when(
        () => application.get(const GetOptions(source: Source.server)),
      ).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await expectLater(
        service.signInWithEmail('alice@example.test', 'test-only-password'),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      verify(
        () => auth.signInWithEmailAndPassword(
          email: 'alice@example.test',
          password: 'test-only-password',
        ),
      ).called(1);
      verifyNever(() => parent.get());
      verifyNever(() => parent.set(any(), any()));
      verifyNever(() => user.delete());
    },
  );
  test(
    'email login for an existing applicant never creates a parent',
    () async {
      when(() => applicationSnapshot.exists).thenReturn(true);
      expect(
        await service.signInWithEmail(
          'alice@example.test',
          'test-only-password',
        ),
        same(credential),
      );
      verifyNever(() => parent.get());
      verifyNever(() => parent.set(any(), any()));
    },
  );
  test(
    'failed profile write is recoverable by authenticated registration retry',
    () async {
      when(() => parent.set(any(), any())).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      await expectLater(register(), throwsA(isA<AuthFlowException>()));
      verifyNever(() => user.delete());
      when(
        () => auth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
      when(() => parent.set(any(), any())).thenAnswer((_) async {});
      expect(await register(), same(credential));
      verify(
        () => auth.signInWithEmailAndPassword(
          email: 'alice@example.test',
          password: 'test-only-password',
        ),
      ).called(1);
      verifyNever(() => user.delete());
    },
  );
  test(
    'existing parent or applicant is never overwritten by registration retry',
    () async {
      when(
        () => auth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
      when(() => profileSnapshot.exists).thenReturn(true);
      await expectLater(register(), throwsA(isA<AuthFlowException>()));
      when(() => profileSnapshot.exists).thenReturn(false);
      when(() => applicationSnapshot.exists).thenReturn(true);
      await expectLater(register(), throwsA(isA<AuthFlowException>()));
      verifyNever(() => parent.set(any(), any()));
      verifyNever(() => user.delete());
    },
  );
  test('incorrect password cannot reconcile another account', () async {
    when(
      () => auth.createUserWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
    when(
      () => auth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(FirebaseAuthException(code: 'invalid-credential'));
    await expectLater(register(), throwsA(isA<AuthFlowException>()));
    verifyNever(() => parent.set(any(), any()));
  });
}
