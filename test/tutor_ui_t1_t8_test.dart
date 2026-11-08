import 'dart:async';

import 'package:beewise/app/bee_wise_app.dart';
import 'package:beewise/models/chat_message.dart';
import 'package:beewise/models/tutor.dart';
import 'package:beewise/models/tutor_workspace_models.dart';
import 'package:beewise/screens/tutor_application_screens.dart';
import 'package:beewise/screens/tutor_screens.dart';
import 'package:beewise/services/auth_service.dart';
import 'package:beewise/services/notification_service.dart';
import 'package:beewise/services/tutor_application_service.dart';
import 'package:beewise/services/tutor_repository.dart';
import 'package:beewise/services/tutor_workspace_service.dart';
import 'package:beewise/theme/bee_wise_theme.dart';
import 'package:beewise/viewmodels/app_providers.dart';
import 'package:beewise/viewmodels/controllers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockUser extends Mock implements User {}

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class _MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _MockDoc extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _MockSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

User _fakeUser(
  String uid, {
  String email = 'user@example.test',
  String displayName = 'Gia sư Minh',
}) {
  final u = _MockUser();
  when(() => u.uid).thenReturn(uid);
  when(() => u.email).thenReturn(email);
  when(() => u.displayName).thenReturn(displayName);
  when(() => u.isAnonymous).thenReturn(false);
  when(() => u.updateDisplayName(any())).thenAnswer((_) async {});
  return u;
}

class _FakeAuthService implements AuthService {
  _FakeAuthService([User? initialUser]) : _current = initialUser {
    _controller.add(_current);
  }

  User? _current;
  final _controller = StreamController<User?>.broadcast();

  void emitUser(User? user) {
    _current = user;
    _controller.add(user);
  }

  @override
  Stream<User?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<UserCredential> registerParent({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<UserCredential> signInWithEmail(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<UserCredential> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<void> signOut() async {
    emitUser(null);
  }
}

class _FakeTutorApplicationService extends Fake
    implements TutorApplicationService {
  _FakeTutorApplicationService({
    Map<String, TutorApplicationData>? applications,
    this.roleHook,
  }) : _applications = Map<String, TutorApplicationData>.from(
         applications ?? const {},
       );

  final Map<String, TutorApplicationData> _applications;
  final Future<AccountRoleResolution> Function(String uid)? roleHook;
  Object? resubmitError;

  int submitCallCount = 0;
  int resubmitCallCount = 0;
  Map<String, dynamic>? lastSubmittedPayload;
  Map<String, dynamic>? lastResubmittedPayload;

  void putApplication(TutorApplicationData app) {
    _applications[app.uid] = app;
  }

  @override
  Future<AccountRoleResolution> resolveAccountRole(String uid) async {
    if (roleHook != null) {
      return roleHook!(uid);
    }
    final app = _applications[uid];
    if (app == null) {
      return AccountRoleResolution(kind: AccountRoleKind.parent, uid: uid);
    }
    return AccountRoleResolution(
      kind: app.roleKind,
      uid: uid,
      application: app,
    );
  }

  @override
  Future<bool> hasApplication(String uid) async =>
      _applications.containsKey(uid);

  @override
  Future<String> status(String uid) async {
    final app = _applications[uid];
    if (app == null) throw const TutorApplicationException();
    return app.status;
  }

  @override
  Stream<String> watchStatus(String uid) async* {
    final app = _applications[uid];
    if (app == null) throw const TutorApplicationException();
    yield app.status;
  }

  @override
  Stream<TutorApplicationData?> watchApplicationData(String uid) async* {
    yield _applications[uid];
  }

  @override
  Future<TutorApplicationData?> getApplicationData(String uid) async =>
      _applications[uid];

  @override
  Future<String> submit({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String qualification,
    required String introduction,
    required List<String> subjects,
    required List<String> grades,
    required int hourlyFee,
    required List<String> areas,
    required List<String> teachingModes,
    required String availability,
  }) async {
    submitCallCount++;
    lastSubmittedPayload = {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'qualification': qualification,
      'introduction': introduction,
      'subjects': subjects,
      'grades': grades,
      'hourlyFee': hourlyFee,
      'areas': areas,
      'teachingModes': teachingModes,
      'availability': availability,
    };
    const newUid = 'new_tutor_uid';
    _applications[newUid] = TutorApplicationData(
      uid: newUid,
      name: name,
      email: email,
      phone: phone,
      qualification: qualification,
      introduction: introduction,
      subjects: subjects,
      grades: grades,
      hourlyFee: hourlyFee,
      areas: areas,
      teachingModes: teachingModes,
      availability: availability,
      status: 'pending',
      verified: false,
      active: false,
      createdAt: DateTime(2026, 11, 8),
    );
    return newUid;
  }

  @override
  Future<String> resubmit({
    required String uid,
    required String name,
    required String phone,
    required String qualification,
    required String introduction,
    required List<String> subjects,
    required List<String> grades,
    required int hourlyFee,
    required List<String> areas,
    required List<String> teachingModes,
    required String availability,
  }) async {
    resubmitCallCount++;
    if (resubmitError != null) {
      throw resubmitError!;
    }
    final existing = _applications[uid];
    if (existing == null) throw const TutorApplicationException();
    if (!existing.canEditApplication) {
      throw const TutorApplicationException(
        'Chỉ hồ sơ ở trạng thái cần bổ sung mới có thể cập nhật.',
      );
    }
    lastResubmittedPayload = {
      'uid': uid,
      'name': name,
      'phone': phone,
      'qualification': qualification,
      'introduction': introduction,
      'subjects': subjects,
      'grades': grades,
      'hourlyFee': hourlyFee,
      'areas': areas,
      'teachingModes': teachingModes,
      'availability': availability,
    };
    _applications[uid] = TutorApplicationData(
      uid: uid,
      name: name,
      email: existing.email,
      phone: phone,
      qualification: qualification,
      introduction: introduction,
      subjects: subjects,
      grades: grades,
      hourlyFee: hourlyFee,
      areas: areas,
      teachingModes: teachingModes,
      availability: availability,
      status: 'pending',
      verified: false,
      active: false,
      createdAt: existing.createdAt,
      updatedAt: DateTime(2026, 11, 9),
      previousRejectionReason: existing.rejectionReason,
    );
    return uid;
  }
}

class _FakeTutorWorkspaceService implements TutorWorkspaceService {
  _FakeTutorWorkspaceService({
    this.chatSessions = const {},
    this.classes = const {},
    this.profile,
    this.sendHandler,
  });

  TutorDashboardData dashboard = const TutorDashboardData();
  List<TutorChatSummary> chats = const [];
  Map<String, TutorChatSession> chatSessions;
  Map<String, TutorClassRecord> classes;
  List<TutorLessonSession> schedule = const [];
  TutorProfileViewData? profile;
  Future<void> Function(String tutorUid, String chatId, String body)?
  sendHandler;
  Object? dashboardError;

  final List<Map<String, String>> sentMessages = [];

  @override
  Stream<TutorDashboardData> watchDashboard(String tutorUid) {
    if (dashboardError != null) {
      return Stream.error(dashboardError!);
    }
    return Stream.value(dashboard);
  }

  @override
  Stream<List<TutorChatSummary>> watchTutorChats(String tutorUid) =>
      Stream.value(chats.where((c) => c.tutorId == tutorUid).toList());

  @override
  Stream<TutorChatSession> watchTutorChatSession(
    String tutorUid,
    String chatId,
  ) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(chatId)) {
      return Stream.error(
        const TutorResourceNotFoundException('Mã nhóm chat không hợp lệ.'),
      );
    }
    final session = chatSessions[chatId];
    if (session == null) {
      return Stream.error(
        const TutorResourceNotFoundException('Không tìm thấy nhóm chat này.'),
      );
    }
    if (session.summary.tutorId != tutorUid) {
      return Stream.error(
        const TutorUnauthorizedException(
          'Bạn không có quyền truy cập nhóm chat của gia sư khác.',
        ),
      );
    }
    return Stream.value(session);
  }

  @override
  Future<void> sendTutorMessage({
    required String tutorUid,
    required String chatId,
    required String body,
  }) async {
    if (sendHandler != null) {
      await sendHandler!(tutorUid, chatId, body);
    }
    sentMessages.add({'tutorUid': tutorUid, 'chatId': chatId, 'body': body});
  }

  @override
  Stream<TutorClassRecord> watchTutorClass(String tutorUid, String classId) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(classId)) {
      return Stream.error(
        const TutorResourceNotFoundException('Mã lớp học không hợp lệ.'),
      );
    }
    final cls = classes[classId];
    if (cls == null) {
      return Stream.error(
        const TutorResourceNotFoundException('Không tìm thấy lớp học này.'),
      );
    }
    if (cls.tutorId != tutorUid) {
      return Stream.error(
        const TutorUnauthorizedException(
          'Bạn không có quyền truy cập lớp học của gia sư khác.',
        ),
      );
    }
    return Stream.value(cls);
  }

  @override
  Stream<List<TutorLessonSession>> watchTutorSchedule(String tutorUid) =>
      Stream.value(schedule.where((s) => s.tutorId == tutorUid).toList());

  @override
  Stream<TutorProfileViewData> watchTutorProfile(String tutorUid) {
    if (profile == null) {
      return Stream.error(const TutorUnauthorizedException());
    }
    return Stream.value(profile!);
  }

  @override
  Future<String?> validateTutorNotificationRoute(
    String tutorUid,
    String? rawRoute, {
    String? recipientUid,
  }) async {
    if (recipientUid != null && recipientUid != tutorUid) return null;
    if (rawRoute == null || rawRoute.isEmpty) return null;
    if (rawRoute.startsWith('/tutor/chats/')) {
      final id = rawRoute.split('/').last;
      final s = chatSessions[id];
      if (s == null || s.summary.tutorId != tutorUid) return null;
      return rawRoute;
    }
    if (rawRoute.startsWith('/tutor/class/')) {
      final id = rawRoute.split('/').last;
      final c = classes[id];
      if (c == null || c.tutorId != tutorUid) return null;
      return rawRoute;
    }
    return rawRoute;
  }
}

class _EmptyParentTutorRepo implements TutorRepository {
  const _EmptyParentTutorRepo();
  @override
  Future<List<Tutor>> activeTutors({int limit = 50}) async => const [];
  @override
  Future<Tutor> tutorById(String id) =>
      Future.error(const TutorResourceNotFoundException());
}

TutorApplicationData _sampleApplication({
  String uid = 'tutor_1',
  String name = 'Nguyễn Minh Quân',
  String status = 'approved',
  bool verified = true,
  bool active = true,
  String? rejectionReason,
}) => TutorApplicationData(
  uid: uid,
  name: name,
  email: 'quan.nguyen@example.test',
  phone: '0987654321',
  qualification: 'Cử nhân Sư phạm Toán',
  introduction:
      'Kinh nghiệm 4 năm kèm học sinh THCS ôn thi học kỳ và tuyển sinh lớp 10.',
  subjects: const ['Toán', 'Vật lý'],
  grades: const ['Lớp 8', 'Lớp 9'],
  hourlyFee: 220000,
  areas: const ['Cầu Giấy', 'Ba Đình'],
  teachingModes: const ['in_person', 'online'],
  availability: 'T3 tối, T5 tối',
  status: status,
  verified: verified,
  active: active,
  createdAt: DateTime(2026, 11, 1),
  rejectionReason: rejectionReason,
);

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget widget, {
  List<dynamic> overrides = const [],
  Size size = const Size(412, 2600),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(path: '/test', builder: (_, _) => widget),
      GoRoute(
        path: '/tutor/pending',
        builder: (_, _) =>
            const Scaffold(body: Text('Navigated:/tutor/pending')),
      ),
      GoRoute(
        path: '/tutor/home',
        builder: (_, _) => const Scaffold(body: Text('Navigated:/tutor/home')),
      ),
      GoRoute(
        path: '/tutor/profile',
        builder: (_, _) =>
            const Scaffold(body: Text('Navigated:/tutor/profile')),
      ),
      GoRoute(
        path: '/tutor/schedule',
        builder: (_, _) =>
            const Scaffold(body: Text('Navigated:/tutor/schedule')),
      ),
      GoRoute(
        path: '/tutor/chats',
        builder: (_, _) => const Scaffold(body: Text('Navigated:/tutor/chats')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overrides.cast(),
      child: MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: MaterialApp.router(
          theme: BeeWiseTheme.light,
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('1. Role-Aware Routing & Async Account Switching Safety', () {
    Future<GoRouter> pumpRouterApp(
      WidgetTester tester, {
      required _FakeAuthService authService,
      required _FakeTutorApplicationService appService,
      required _FakeTutorWorkspaceService workspaceService,
    }) async {
      tester.view.physicalSize = const Size(412, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            authServiceProvider.overrideWithValue(authService),
            tutorApplicationServiceProvider.overrideWithValue(appService),
            tutorWorkspaceServiceProvider.overrideWithValue(workspaceService),
            tutorRepositoryProvider.overrideWithValue(
              const _EmptyParentTutorRepo(),
            ),
            notificationsProvider.overrideWith(
              (ref) => Stream.value(const <BeeWiseNotification>[]),
            ),
          ],
          child: const BeeWiseApp(),
        ),
      );
      await tester.pumpAndSettle();
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      return materialApp.routerConfig! as GoRouter;
    }

    testWidgets(
      'Guest is redirected from protected tutor routes to /login but can open /tutor/apply',
      (tester) async {
        final auth = _FakeAuthService(null);
        final appService = _FakeTutorApplicationService();
        final workspace = _FakeTutorWorkspaceService();
        final router = await pumpRouterApp(
          tester,
          authService: auth,
          appService: appService,
          workspaceService: workspace,
        );

        router.go('/tutor/home');
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/login'),
        );

        router.go('/tutor/apply');
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/tutor/apply'),
        );
      },
    );

    testWidgets(
      'Parent is redirected away from tutor workspace and /tutor/pending to /home',
      (tester) async {
        final auth = _FakeAuthService(_fakeUser('parent_1'));
        final appService = _FakeTutorApplicationService();
        final workspace = _FakeTutorWorkspaceService();
        final router = await pumpRouterApp(
          tester,
          authService: auth,
          appService: appService,
          workspaceService: workspace,
        );

        router.go('/tutor/home');
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/home'),
        );

        router.go('/tutor/pending');
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/home'),
        );
      },
    );

    testWidgets(
      'Pending, needs_info, rejected, and approved-unverified applicants are confined to allowed routes',
      (tester) async {
        final pendingApp = _sampleApplication(
          uid: 'u_pending',
          status: 'pending',
          verified: false,
          active: false,
        );
        final needsInfoApp = _sampleApplication(
          uid: 'u_needs_info',
          status: 'needs_info',
          verified: false,
          active: false,
          rejectionReason: 'Cần bổ sung bằng cấp',
        );
        final rejectedApp = _sampleApplication(
          uid: 'u_rejected',
          status: 'rejected',
          verified: false,
          active: false,
          rejectionReason: 'Chưa phù hợp',
        );
        final approvedUnverifiedApp = _sampleApplication(
          uid: 'u_unverified',
          status: 'approved',
          verified: false,
          active: true,
        );

        final auth = _FakeAuthService(_fakeUser('u_pending'));
        final appService = _FakeTutorApplicationService(
          applications: {
            'u_pending': pendingApp,
            'u_needs_info': needsInfoApp,
            'u_rejected': rejectedApp,
            'u_unverified': approvedUnverifiedApp,
          },
        );
        final workspace = _FakeTutorWorkspaceService();
        final router = await pumpRouterApp(
          tester,
          authService: auth,
          appService: appService,
          workspaceService: workspace,
        );

        // 1. Pending -> forced to /tutor/pending, cannot open /tutor/home or /tutor/apply
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/tutor/pending'),
        );
        router.go('/tutor/home');
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/tutor/pending'),
        );
        router.go('/tutor/apply');
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/tutor/pending'),
        );

        // 2. Needs Info -> allowed on /tutor/pending and /tutor/apply, blocked from /tutor/home
        auth.emitUser(_fakeUser('u_needs_info'));
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/tutor/pending'),
        );
        router.go('/tutor/apply');
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/tutor/apply'),
        );
        router.go('/tutor/home');
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/tutor/pending'),
        );

        // 3. Rejected -> allowed only on /tutor/pending, blocked from /tutor/apply
        auth.emitUser(_fakeUser('u_rejected'));
        await tester.pumpAndSettle();
        router.go('/tutor/apply');
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/tutor/pending'),
        );

        // 4. Approved but verified == false -> kept on /tutor/pending, blocked from /tutor/home
        auth.emitUser(_fakeUser('u_unverified'));
        await tester.pumpAndSettle();
        router.go('/tutor/home');
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/tutor/pending'),
        );
      },
    );

    testWidgets(
      'Fully authorized tutor enters /tutor/home and role-resolution error fails closed to /account/check',
      (tester) async {
        final authorizedApp = _sampleApplication(
          uid: 'tutor_ok',
          status: 'approved',
          verified: true,
          active: true,
        );
        var throwError = false;
        final auth = _FakeAuthService(_fakeUser('tutor_ok'));
        final appService = _FakeTutorApplicationService(
          applications: {'tutor_ok': authorizedApp},
          roleHook: (uid) async {
            if (throwError) {
              throw Exception('Firestore offline');
            }
            return AccountRoleResolution(
              kind: AccountRoleKind.authorizedTutor,
              uid: uid,
              application: authorizedApp,
            );
          },
        );
        final workspace = _FakeTutorWorkspaceService(
          profile: TutorProfileViewData(application: authorizedApp),
        );
        final router = await pumpRouterApp(
          tester,
          authService: auth,
          appService: appService,
          workspaceService: workspace,
        );

        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/tutor/home'),
        );

        // Trigger role resolution failure -> fails closed to /account/check
        throwError = true;
        router.go('/tutor/schedule');
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/account/check'),
        );
      },
    );

    testWidgets(
      'Stale async role resolution for User A never redirects User B after account switch',
      (tester) async {
        final userACompleter = Completer<AccountRoleResolution>();
        final auth = _FakeAuthService(_fakeUser('user_a'));
        final appService = _FakeTutorApplicationService(
          roleHook: (uid) {
            if (uid == 'user_a') return userACompleter.future;
            // user_b is a normal parent
            return Future.value(
              const AccountRoleResolution(
                kind: AccountRoleKind.parent,
                uid: 'user_b',
              ),
            );
          },
        );
        final workspace = _FakeTutorWorkspaceService();

        tester.view.physicalSize = const Size(412, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              authServiceProvider.overrideWithValue(auth),
              tutorApplicationServiceProvider.overrideWithValue(appService),
              tutorWorkspaceServiceProvider.overrideWithValue(workspace),
              tutorRepositoryProvider.overrideWithValue(
                const _EmptyParentTutorRepo(),
              ),
              notificationsProvider.overrideWith(
                (ref) => Stream.value(const <BeeWiseNotification>[]),
              ),
            ],
            child: const BeeWiseApp(),
          ),
        );
        await tester.pump();

        // Switch to User B (Parent) before User A's pending-tutor resolution completes
        auth.emitUser(_fakeUser('user_b'));
        await tester.pump();

        // Now complete User A's stale future as a pending tutor
        userACompleter.complete(
          AccountRoleResolution(
            kind: AccountRoleKind.pendingApplicant,
            uid: 'user_a',
            application: _sampleApplication(uid: 'user_a', status: 'pending'),
          ),
        );
        await tester.pumpAndSettle();

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        final router = materialApp.routerConfig! as GoRouter;
        // User B must be on /home (parent), NEVER redirected to /tutor/pending!
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals('/home'),
        );
      },
    );
  });

  group('2. T1 & T2 Application Registration, Prefill & Resubmission', () {
    testWidgets(
      'T1 guest registration has no hardcoded sample values and validates all fields before submit',
      (tester) async {
        final appService = _FakeTutorApplicationService();
        await _pumpScreen(
          tester,
          const TutorApplicationScreen(),
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            tutorApplicationServiceProvider.overrideWithValue(appService),
          ],
        );

        // Ensure no hardcoded Trang sample values are prefilled for a guest
        expect(find.text('Hoàng Thu Trang'), findsNothing);
        expect(find.text('trang.hoang@gmail.com'), findsNothing);

        await tester.tap(find.text('Gửi hồ sơ'));
        await tester.pumpAndSettle();

        expect(find.textContaining('mục cần sửa'), findsOneWidget);
        expect(appService.submitCallCount, equals(0));
      },
    );

    testWidgets(
      'T1 needs_info applicant prefills existing application, hides password, preserves UID on resubmit',
      (tester) async {
        final existing = _sampleApplication(
          uid: 'tutor_needs_info',
          name: 'Lê Thu Hà',
          status: 'needs_info',
          verified: false,
          active: false,
          rejectionReason:
              'Vui lòng bổ sung thành tích học sinh ôn thi vào 10.',
        );
        final appService = _FakeTutorApplicationService(
          applications: {'tutor_needs_info': existing},
        );

        await _pumpScreen(
          tester,
          const TutorApplicationScreen(isResubmissionRoute: true),
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_fakeUser('tutor_needs_info')),
            ),
            tutorApplicationServiceProvider.overrideWithValue(appService),
            tutorApplicationDataProvider('tutor_needs_info')
                .overrideWith((ref) => Stream.value(existing)),
          ],
        );

        expect(find.text('Bổ sung hồ sơ gia sư BeeWise'), findsOneWidget);
        expect(
          find.text('Vui lòng bổ sung thành tích học sinh ôn thi vào 10.'),
          findsOneWidget,
        );
        // Existing values are prefilled
        expect(find.text('Lê Thu Hà'), findsOneWidget);
        // Password field is hidden in edit mode
        expect(find.widgetWithText(TextFormField, 'Mật khẩu'), findsNothing);

        // Update introduction and submit
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Bằng cấp / kinh nghiệm'),
          'Thạc sĩ Sư phạm Toán - 6 năm kinh nghiệm',
        );
        await tester.tap(find.text('Gửi lại hồ sơ'));
        await tester.pumpAndSettle();

        expect(appService.submitCallCount, equals(0));
        expect(appService.resubmitCallCount, equals(1));
        expect(
          appService.lastResubmittedPayload?['uid'],
          equals('tutor_needs_info'),
        );
        final updated = await appService.getApplicationData('tutor_needs_info');
        expect(updated?.status, equals('pending'));
        expect(updated?.verified, isFalse);
        expect(updated?.active, isFalse);
        expect(
          updated?.previousRejectionReason,
          equals('Vui lòng bổ sung thành tích học sinh ôn thi vào 10.'),
        );
      },
    );

    testWidgets(
      'TutorApplicationService.resubmit surfaces permission-denied rule error honestly without faking success',
      (tester) async {
        final mockAuth = _MockAuth();
        final mockStore = _MockFirestore();
        final mockCol = _MockCollection();
        final mockDoc = _MockDoc();
        final mockSnap = _MockSnapshot();
        final user = _fakeUser('tutor_needs_info');

        when(() => mockAuth.currentUser).thenReturn(user);
        when(() => mockStore.collection('tutorApplications'))
            .thenReturn(mockCol);
        when(() => mockCol.doc('tutor_needs_info')).thenReturn(mockDoc);
        when(() => mockDoc.get()).thenAnswer((_) async => mockSnap);
        when(() => mockSnap.exists).thenReturn(true);
        when(() => mockSnap.data()).thenReturn({
          'name': 'Lê Thu Hà',
          'email': 'ha@example.test',
          'phone': '0987654321',
          'qualification': 'Cử nhân',
          'introduction': 'Kinh nghiệm 4 năm dạy Toán THCS.',
          'subjects': ['Toán'],
          'grades': ['Lớp 9'],
          'hourlyFee': 200000,
          'areas': ['Cầu Giấy'],
          'teachingModes': ['online'],
          'availability': 'T3 tối',
          'status': 'needs_info',
          'verified': false,
          'active': false,
        });
        when(() => mockDoc.update(any())).thenThrow(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        );

        final realService = TutorApplicationService(mockAuth, mockStore);
        await expectLater(
          realService.resubmit(
            uid: 'tutor_needs_info',
            name: 'Lê Thu Hà',
            phone: '0987654321',
            qualification: 'Thạc sĩ',
            introduction: 'Kinh nghiệm 5 năm dạy Toán THCS chuyên sâu.',
            subjects: const ['Toán'],
            grades: const ['Lớp 9'],
            hourlyFee: 220000,
            areas: const ['Cầu Giấy'],
            teachingModes: const ['online'],
            availability: 'T3 tối',
          ),
          throwsA(
            isA<TutorApplicationException>().having(
              (e) => e.isBackendRuleBlocked,
              'isBackendRuleBlocked',
              isTrue,
            ),
          ),
        );
      },
    );

    testWidgets(
      'T2 distinguishes rejected (no resubmit button) and approved-pending-activation (no enter workspace button)',
      (tester) async {
        final rejected = _sampleApplication(
          uid: 'u_rej',
          status: 'rejected',
          verified: false,
          active: false,
          rejectionReason: 'Hồ sơ không đạt yêu cầu xác minh.',
        );
        await _pumpScreen(
          tester,
          const TutorApplicationStatusScreen(),
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_fakeUser('u_rej')),
            ),
            tutorApplicationDataProvider('u_rej')
                .overrideWith((ref) => Stream.value(rejected)),
            tutorApplicationStatusProvider('u_rej')
                .overrideWith((ref) => Stream.value('rejected')),
          ],
        );

        expect(find.text('Từ chối duyệt'), findsOneWidget);
        expect(find.text('Cập nhật hồ sơ'), findsNothing);
        expect(find.text('Vào trang gia sư'), findsNothing);

        final unverifiedApproved = _sampleApplication(
          uid: 'u_unv',
          status: 'approved',
          verified: false,
          active: true,
        );
        await _pumpScreen(
          tester,
          const TutorApplicationStatusScreen(),
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_fakeUser('u_unv')),
            ),
            tutorApplicationDataProvider('u_unv')
                .overrideWith((ref) => Stream.value(unverifiedApproved)),
            tutorApplicationStatusProvider('u_unv')
                .overrideWith((ref) => Stream.value('approved')),
          ],
        );

        expect(find.text('Đã duyệt — Chờ kích hoạt'), findsOneWidget);
        expect(find.text('Vào trang gia sư'), findsNothing);
      },
    );
  });

  group('3. T3–T8 Real Data, Empty/Error/Unauthorized States & No Fake Records', () {
    testWidgets(
      'T3 TutorHomeScreen shows empty state when tutor has no chats/classes and never shows fake Chị Lan data',
      (tester) async {
        final app = _sampleApplication(uid: 'tutor_1', name: 'Đặng Quốc Bảo');
        await _pumpScreen(
          tester,
          const TutorHomeScreen(),
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_fakeUser('tutor_1')),
            ),
            tutorApplicationDataProvider('tutor_1')
                .overrideWith((ref) => Stream.value(app)),
            tutorDashboardProvider.overrideWith(
              (ref) => Stream.value(const TutorDashboardData()),
            ),
            notificationsProvider.overrideWith(
              (ref) => Stream.value(const <BeeWiseNotification>[]),
            ),
          ],
        );

        expect(find.text('Chưa có việc cần làm'), findsOneWidget);
        expect(find.text('Chưa có nhóm chat nào'), findsOneWidget);
        // No fabricated records
        expect(find.textContaining('Chị Lan'), findsNothing);
        expect(find.textContaining('Hoàng Thu Trang'), findsNothing);
        expect(find.textContaining('Hoàng Yến'), findsNothing);
      },
    );

    testWidgets(
      'T3 TutorHomeScreen & T5 TutorClassDetailScreen show verified payment badge ONLY when paymentStatus == verified',
      (tester) async {
        final pendingClass = const TutorClassRecord(
          id: 'class_pending_1',
          tutorId: 'tutor_1',
          parentId: 'parent_9',
          title: 'Vật lý 9 — Học kỳ 1',
          parentName: 'Anh Tuấn',
          scheduleSummary: 'T2 & T5 · 18:00 - 20:00',
          locationSummary: 'Tại nhà · Đống Đa',
          paymentStatus: 'pending',
          onboardingStage: 3,
        );
        final verifiedClass = const TutorClassRecord(
          id: 'class_verified_1',
          tutorId: 'tutor_1',
          parentId: 'parent_10',
          title: 'Toán 9 — Chuyên',
          parentName: 'Chị Mai',
          scheduleSummary: 'T3 & T6 · 19:00 - 21:00',
          locationSummary: 'Tại nhà · Cầu Giấy',
          paymentStatus: 'verified',
          totalSessions: 8,
          onboardingStage: 4,
        );

        await _pumpScreen(
          tester,
          const TutorClassDetailScreen(classId: 'class_pending_1'),
          overrides: [
            tutorClassDetailProvider('class_pending_1')
                .overrideWith((ref) => Stream.value(pendingClass)),
          ],
        );

        expect(
          find.text('Chờ xác nhận thanh toán học phí từ Anh Tuấn'),
          findsOneWidget,
        );
        expect(find.textContaining('đã thanh toán'), findsNothing);

        await _pumpScreen(
          tester,
          const TutorClassDetailScreen(classId: 'class_verified_1'),
          overrides: [
            tutorClassDetailProvider('class_verified_1')
                .overrideWith((ref) => Stream.value(verifiedClass)),
          ],
        );

        expect(
          find.text('Chị Mai đã thanh toán cho 8 buổi học chính thức'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'T5 unauthorized class ID and T4 missing chat ID render explicit access/not-found states',
      (tester) async {
        final workspace = _FakeTutorWorkspaceService(classes: const {});
        await _pumpScreen(
          tester,
          const TutorClassDetailScreen(classId: 'other_tutor_class'),
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_fakeUser('tutor_1')),
            ),
            tutorWorkspaceServiceProvider.overrideWithValue(workspace),
            tutorClassDetailProvider('other_tutor_class').overrideWith(
              (ref) => Stream.error(
                const TutorUnauthorizedException(
                  'Bạn không có quyền truy cập lớp học của gia sư khác.',
                ),
              ),
            ),
          ],
        );

        expect(find.text('Không có quyền truy cập lớp học'), findsOneWidget);

        await _pumpScreen(
          tester,
          const TutorChatScreen(chatId: 'missing_chat_99'),
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_fakeUser('tutor_1')),
            ),
            tutorWorkspaceServiceProvider.overrideWithValue(workspace),
          ],
        );

        expect(find.text('Không tìm thấy nhóm chat'), findsOneWidget);
      },
    );

    testWidgets(
      'T3 Firestore query failure renders ErrorStateView and recovers on retry',
      (tester) async {
        var shouldFail = true;
        final app = _sampleApplication(uid: 'tutor_1', name: 'Trần Văn Nam');
        final chat = const TutorChatSummary(
          id: 'chat_real_1',
          parentId: 'parent_1',
          tutorId: 'tutor_1',
          parentName: 'Phụ huynh Minh',
          onboardingStatus: 'trial_proposed',
          subjectSummary: 'Toán 8',
          isNew: true,
        );

        await _pumpScreen(
          tester,
          const TutorHomeScreen(),
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_fakeUser('tutor_1')),
            ),
            tutorApplicationDataProvider('tutor_1')
                .overrideWith((ref) => Stream.value(app)),
            tutorDashboardProvider.overrideWith((ref) {
              if (shouldFail) {
                return Stream.error(
                  FirebaseException(
                    plugin: 'cloud_firestore',
                    code: 'unavailable',
                  ),
                );
              }
              return Stream.value(TutorDashboardData(chats: [chat]));
            }),
            notificationsProvider.overrideWith(
              (ref) => Stream.value(const <BeeWiseNotification>[]),
            ),
          ],
        );

        expect(
          find.textContaining('Không kết nối được dịch vụ'),
          findsOneWidget,
        );

        shouldFail = false;
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();

        expect(find.text('Việc cần làm hôm nay'), findsOneWidget);
        expect(find.text('Phụ huynh Minh · Toán 8'), findsOneWidget);
      },
    );

    testWidgets(
      'T6 TutorScheduleScreen uses real week dates and T7 TutorSelfProfileScreen shows Chưa có đánh giá when unrated',
      (tester) async {
        final sessionDate = DateTime(2026, 11, 10, 19, 0); // Tuesday 10/11/2026
        final session = TutorLessonSession(
          id: 'sess_1',
          classId: 'cls_1',
          tutorId: 'tutor_1',
          subjectTitle: 'Toán 8',
          parentName: 'Anh Khoa',
          locationSummary: 'Trực tuyến',
          startTime: sessionDate,
          endTime: sessionDate.add(const Duration(hours: 2)),
          sessionNumber: 1,
          totalSessions: 8,
          confirmed: true,
        );

        await _pumpScreen(
          tester,
          TutorScheduleScreen(initialDate: sessionDate),
          overrides: [
            tutorScheduleProvider.overrideWith(
              (ref) => Stream.value([session]),
            ),
          ],
        );

        expect(find.text('Tuần 09/11 — 15/11'), findsOneWidget);
        expect(find.text('Buổi 1/8 · Đã xác nhận'), findsOneWidget);

        final app = _sampleApplication(
          uid: 'tutor_1',
          name: 'Nguyễn Minh Quân',
        );
        await _pumpScreen(
          tester,
          const TutorSelfProfileScreen(),
          overrides: [
            tutorProfileViewProvider.overrideWith(
              (ref) => Stream.value(
                TutorProfileViewData(
                  application: app,
                  publicCatalogProfile: null,
                ),
              ),
            ),
          ],
        );

        expect(find.text('Nguyễn Minh Quân'), findsOneWidget);
        expect(find.text('Chưa có đánh giá'), findsOneWidget);
        expect(find.text('4.9 (24)'), findsNothing);
        expect(
          find.text('Hồ sơ đã duyệt — Đang chờ đồng bộ danh mục'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'T8 TutorNotificationScreen shows empty state when no notifications exist and blocks unauthorized deep links',
      (tester) async {
        final workspace = _FakeTutorWorkspaceService(chatSessions: const {});
        await _pumpScreen(
          tester,
          const TutorNotificationScreen(),
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_fakeUser('tutor_1')),
            ),
            tutorWorkspaceServiceProvider.overrideWithValue(workspace),
            notificationsProvider.overrideWith(
              (ref) => Stream.value(const <BeeWiseNotification>[]),
            ),
          ],
        );

        expect(find.text('Chưa có thông báo mới'), findsOneWidget);
        expect(find.text('Nhóm chat mới với chị Lan'), findsNothing);

        final badNotif = BeeWiseNotification(
          id: 'n1',
          title: 'Thông báo thử nghiệm',
          body: 'Liên kết tới nhóm chat không thuộc quyền sở hữu',
          route: '/tutor/chats/unauthorized_chat',
          receivedAt: DateTime(2026, 11, 8, 10, 0),
          recipientUid: 'tutor_1',
        );

        await _pumpScreen(
          tester,
          const TutorNotificationScreen(),
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_fakeUser('tutor_1')),
            ),
            tutorWorkspaceServiceProvider.overrideWithValue(workspace),
            notificationsProvider.overrideWith(
              (ref) => Stream.value([badNotif]),
            ),
          ],
        );

        await tester.tap(find.text('Thông báo thử nghiệm'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Không thể mở liên kết này'),
          findsOneWidget,
        );
      },
    );
  });

  group('4. T4 Tutor Chat Send, Retry, Duplicate Prevention & Account-Switch Isolation', () {
    testWidgets(
      'T4 disables composer when canSendMessages == false and supports send/fail/retry/duplicate lock when permitted',
      (tester) async {
        final summary = const TutorChatSummary(
          id: 'chat_1',
          parentId: 'parent_1',
          tutorId: 'tutor_1',
          parentName: 'Chị Hương',
          consultantName: 'Minh Tâm',
          onboardingStatus: 'trial_proposed',
          classId: 'class_1',
        );
        final messages = [
          ChatMessage(
            id: 'm1',
            senderId: 'parent_1',
            senderName: 'Chị Hương',
            role: 'parent',
            body: 'Chào thầy Quân, gia đình muốn trao đổi lịch học.',
            createdAt: DateTime(2026, 11, 8, 9, 30),
          ),
          ChatMessage(
            id: 'm2',
            senderId: 'cons_1',
            senderName: 'Minh Tâm',
            role: 'consultant',
            body: 'Đề xuất buổi học thử',
            kind: 'trial_proposal',
            payload: const {
              'schedule': '19:00 Thứ Năm 12/11',
              'location': 'Tại nhà Ba Đình',
            },
            createdAt: DateTime(2026, 11, 8, 9, 35),
          ),
        ];

        // 1. Disabled composer when rules block tutor writes
        await _pumpScreen(
          tester,
          const TutorChatScreen(chatId: 'chat_1'),
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_fakeUser('tutor_1')),
            ),
            tutorChatSessionProvider('chat_1').overrideWith(
              (ref) => Stream.value(
                TutorChatSession(
                  summary: summary,
                  messages: messages,
                  canSendMessages: false,
                  sendDisabledReason:
                      FirebaseTutorWorkspaceService.tutorSendRuleReason,
                ),
              ),
            ),
          ],
        );

        expect(find.text('Đề xuất buổi học thử'), findsOneWidget);
        expect(
          find.text(FirebaseTutorWorkspaceService.tutorSendRuleReason),
          findsOneWidget,
        );
        final disabledField = tester.widget<TextField>(find.byType(TextField));
        expect(disabledField.enabled, isFalse);

        // 2. Enabled composer: fail -> no fake bubble -> retry succeeds
        var failNext = true;
        final sendCompleter = Completer<void>();
        final workspace = _FakeTutorWorkspaceService(
          chatSessions: {
            'chat_1': TutorChatSession(
              summary: summary,
              messages: messages,
              canSendMessages: true,
            ),
          },
          sendHandler: (tutorUid, chatId, body) async {
            if (failNext) {
              throw const TutorBackendRulesDependencyException(
                'Lỗi gửi thử nghiệm',
              );
            }
            await sendCompleter.future;
          },
        );
        final auth = _FakeAuthService(_fakeUser('tutor_1'));

        await _pumpScreen(
          tester,
          const TutorChatScreen(chatId: 'chat_1'),
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            authStateProvider.overrideWith(
              (ref) => Stream.value(_fakeUser('tutor_1')),
            ),
            tutorWorkspaceServiceProvider.overrideWithValue(workspace),
          ],
        );

        await tester.enterText(
          find.byType(TextField),
          'Em xác nhận lịch học thử này ạ.',
        );
        await tester.tap(find.byTooltip('Gửi tin nhắn'));
        await tester.pumpAndSettle();

        // Error banner shown, message NOT falsely appended as sent bubble
        expect(find.text('Lỗi gửi thử nghiệm'), findsOneWidget);
        expect(find.text('Thử lại'), findsOneWidget);

        // Now allow send and test duplicate-send lock while in-flight
        failNext = false;
        await tester.tap(find.text('Thử lại'));
        await tester.pump();
        // Second tap while in-flight is ignored
        await tester.tap(find.byTooltip('Gửi tin nhắn'), warnIfMissed: false);
        sendCompleter.complete();
        await tester.pumpAndSettle();

        expect(workspace.sentMessages.length, equals(1));
        expect(
          workspace.sentMessages.single['body'],
          equals('Em xác nhận lịch học thử này ạ.'),
        );
      },
    );

    test('TutorChatComposerController discards in-flight send when account switches User A -> User B', () async {
      final sendCompleter = Completer<void>();
      final auth = _FakeAuthService(_fakeUser('tutor_a'));
      User? currentUser = _fakeUser('tutor_a');
      final workspace = _FakeTutorWorkspaceService(
        sendHandler: (_, _, _) => sendCompleter.future,
      );

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          currentAuthenticatedUidProvider.overrideWith(
            (ref) => currentUser?.uid,
          ),
          tutorWorkspaceServiceProvider.overrideWithValue(workspace),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        tutorChatComposerControllerProvider.notifier,
      );
      final sendFuture = controller.send(
        chatId: 'chat_a',
        text: 'Tin nhắn của A',
      );
      expect(
        container.read(tutorChatComposerControllerProvider).isSending,
        isTrue,
      );

      // Switch account to tutor_b while send is in flight
      currentUser = _fakeUser('tutor_b');
      container.invalidate(currentAuthenticatedUidProvider);
      auth.emitUser(currentUser);
      await Future<void>.delayed(Duration.zero);

      sendCompleter.complete();
      final result = await sendFuture;

      expect(result, isFalse);
      expect(
        container.read(tutorChatComposerControllerProvider).stage,
        equals(TutorChatSendStage.idle),
      );
      expect(
        container.read(tutorChatComposerControllerProvider).ownerUid,
        isNull,
      );
    });
  });

  group(
    '5. Responsive Layout & Text-Scale Verification (360dp, 412dp, 1.25x)',
    () {
      final app = _sampleApplication(uid: 'tutor_1', name: 'Nguyễn Minh Quân');
      final dashboard = TutorDashboardData(
        chats: const [
          TutorChatSummary(
            id: 'c1',
            parentId: 'p1',
            tutorId: 'tutor_1',
            parentName: 'Chị Hương',
            onboardingStatus: 'trial_proposed',
            subjectSummary: 'Toán 9',
            isNew: true,
          ),
        ],
        activeClasses: const [
          TutorClassRecord(
            id: 'cls_1',
            tutorId: 'tutor_1',
            parentId: 'p1',
            title: 'Toán 9 — Học kỳ 1',
            parentName: 'Chị Hương',
            scheduleSummary: 'T3 & T6 · 19:00 - 21:00',
            locationSummary: 'Cầu Giấy',
            paymentStatus: 'verified',
          ),
        ],
      );

      for (final width in [360.0, 412.0]) {
        testWidgets('T1–T8 screens render without overflow at ${width}dp', (
          tester,
        ) async {
          final overrides = [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_fakeUser('tutor_1')),
            ),
            tutorApplicationDataProvider('tutor_1')
                .overrideWith((ref) => Stream.value(app)),
            tutorDashboardProvider.overrideWith(
              (ref) => Stream.value(dashboard),
            ),
            tutorClassDetailProvider('cls_1').overrideWith(
              (ref) => Stream.value(dashboard.activeClasses.single),
            ),
            tutorScheduleProvider.overrideWith((ref) => Stream.value(const [])),
            tutorProfileViewProvider.overrideWith(
              (ref) => Stream.value(TutorProfileViewData(application: app)),
            ),
            notificationsProvider.overrideWith((ref) => Stream.value(const [])),
          ];

          for (final screen in [
            const TutorHomeScreen(),
            const TutorClassDetailScreen(classId: 'cls_1'),
            const TutorScheduleScreen(),
            const TutorSelfProfileScreen(),
            const TutorNotificationScreen(),
          ]) {
            await _pumpScreen(
              tester,
              screen,
              overrides: overrides,
              size: Size(width, 900),
              textScaler: const TextScaler.linear(1.25),
            );
            expect(tester.takeException(), isNull);
          }
        });
      }
    },
  );
}
