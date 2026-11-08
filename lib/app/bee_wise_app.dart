import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/tutor_workspace_models.dart';
import '../screens/beewise_screens.dart';
import '../screens/tutor_application_screens.dart';
import '../screens/tutor_screens.dart';
import '../services/firebase_bootstrap.dart';
import '../services/notification_service.dart';
import '../theme/bee_wise_theme.dart';
import '../viewmodels/app_providers.dart';

class BeeWiseApp extends ConsumerStatefulWidget {
  const BeeWiseApp({super.key});

  @override
  ConsumerState<BeeWiseApp> createState() => _BeeWiseAppState();
}

class _BeeWiseAppState extends ConsumerState<BeeWiseApp> {
  late final GoRouter _router;
  StreamSubscription<BeeWiseNotification>? _notificationRouteSubscription;
  ProviderSubscription<AsyncValue<dynamic>>? _tutorAppSubscription;
  String? _watchedTutorUid;

  void _syncTutorApplicationWatcher(String? uid) {
    if (_watchedTutorUid == uid) return;
    _tutorAppSubscription?.close();
    _tutorAppSubscription = null;
    _watchedTutorUid = uid;
    if (uid != null) {
      _tutorAppSubscription = ref.listenManual(
        tutorApplicationDataProvider(uid),
        (previous, next) {
          final prevData = previous?.asData?.value;
          final nextData = next.asData?.value;
          if (previous?.hasError != next.hasError ||
              (prevData == null) != (nextData == null) ||
              prevData?.status != nextData?.status ||
              prevData?.verified != nextData?.verified ||
              prevData?.active != nextData?.active) {
            _router.refresh();
          }
        },
      );
    }
  }

  String? _guestRedirectFor(String location) {
    final isTutorProtected =
        location == '/tutor' ||
        (location.startsWith('/tutor/') && location != '/tutor/apply');
    return isTutorProtected || location == '/account/check' ? '/login' : null;
  }

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/home',
      redirect: (context, state) async {
        final location = state.matchedLocation;

        while (true) {
          final user = ref.read(authStateProvider).asData?.value;
          final uid = user?.isAnonymous == false ? user!.uid : null;

          // 1. Guest
          if (uid == null) {
            return _guestRedirectFor(location);
          }

          final service = ref.read(tutorApplicationServiceProvider);
          if (service == null) return null;

          AccountRoleResolution resolution;
          try {
            resolution = await service.resolveAccountRole(uid);
          } catch (error) {
            resolution = AccountRoleResolution(
              kind: AccountRoleKind.unresolved,
              uid: uid,
              error: error,
            );
          }

          if (!mounted) return null;
          final latestUser = ref.read(authStateProvider).asData?.value;
          final latestUid = latestUser?.isAnonymous == false
              ? latestUser!.uid
              : null;
          if (latestUid != uid) {
            // Auth state changed while role resolution was in flight.
            // Re-evaluate immediately for the current account (or guest)
            // so stale User A redirects never apply to User B or logged-out state.
            continue;
          }

          return switch (resolution.kind) {
            AccountRoleKind.guest => _guestRedirectFor(location),
            AccountRoleKind.parent => () {
              final isBlockedTutorRoute =
                  location == '/tutor' ||
                  (location.startsWith('/tutor/') &&
                      location != '/tutor/apply');
              if (isBlockedTutorRoute || location == '/account/check') {
                return '/home';
              }
              return null;
            }(),
            AccountRoleKind.pendingApplicant =>
              location == '/tutor/pending' ? null : '/tutor/pending',
            AccountRoleKind.needsInfoApplicant =>
              (location == '/tutor/pending' ||
                      location == '/tutor/apply' ||
                      location == '/tutor/apply/edit')
                  ? null
                  : '/tutor/pending',
            AccountRoleKind.rejectedApplicant =>
              location == '/tutor/pending' ? null : '/tutor/pending',
            AccountRoleKind.approvedPendingVerification =>
              location == '/tutor/pending' ? null : '/tutor/pending',
            AccountRoleKind.authorizedTutor => () {
              if (location == '/tutor' ||
                  location == '/tutor/apply' ||
                  location == '/tutor/apply/edit' ||
                  location == '/account/check' ||
                  location == '/home' ||
                  location == '/login' ||
                  location == '/register' ||
                  location == '/messages' ||
                  location == '/profile') {
                return '/tutor/home';
              }
              return null;
            }(),
            AccountRoleKind.unresolved =>
              location == '/account/check' ? null : '/account/check',
          };
        }
      },
      routes: [
        GoRoute(path: '/', redirect: (_, _) => '/home'),
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/search',
          builder: (_, state) =>
              SearchScreen(initialQuery: state.uri.queryParameters['q'] ?? ''),
        ),
        GoRoute(path: '/matching', builder: (_, _) => const MatchingScreen()),
        GoRoute(
          path: '/tutors/:id',
          builder: (_, state) =>
              TutorProfileScreen(tutorId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/login',
          builder: (_, state) =>
              LoginScreen(tutorId: state.uri.queryParameters['tutorId']),
        ),
        GoRoute(
          path: '/register',
          builder: (_, state) =>
              RegisterScreen(tutorId: state.uri.queryParameters['tutorId']),
        ),
        GoRoute(path: '/tutor', redirect: (_, _) => '/tutor/home'),
        // T1 Tutor Registration & Needs-Info Resubmission
        GoRoute(
          path: '/tutor/apply',
          builder: (_, _) => const TutorApplicationScreen(),
        ),
        GoRoute(
          path: '/tutor/apply/edit',
          builder: (_, _) =>
              const TutorApplicationScreen(isResubmissionRoute: true),
        ),
        // T2 Tutor Application Status
        GoRoute(
          path: '/tutor/pending',
          builder: (_, _) => const TutorApplicationStatusScreen(),
        ),
        // T3 Tutor Home / Dashboard
        GoRoute(
          path: '/tutor/home',
          builder: (_, _) => const TutorHomeScreen(),
        ),
        // T4 Tutor Group Chat
        GoRoute(
          path: '/tutor/chats',
          builder: (_, _) => const TutorChatScreen(),
        ),
        GoRoute(
          path: '/tutor/chats/:chatId',
          builder: (_, state) =>
              TutorChatScreen(chatId: state.pathParameters['chatId']),
        ),
        // T5 Tutor Class Detail
        GoRoute(
          path: '/tutor/class/:classId',
          builder: (_, state) => TutorClassDetailScreen(
            classId: state.pathParameters['classId'] ?? '',
          ),
        ),
        // T6 Tutor Schedule
        GoRoute(
          path: '/tutor/schedule',
          builder: (_, _) => const TutorScheduleScreen(),
        ),
        // T7 Tutor Self Profile
        GoRoute(
          path: '/tutor/profile',
          builder: (_, _) => const TutorSelfProfileScreen(),
        ),
        // T8 Tutor Notifications
        GoRoute(
          path: '/tutor/notifications',
          builder: (_, _) => const TutorNotificationScreen(),
        ),
        GoRoute(
          path: '/account/check',
          builder: (_, _) => const AccountRoleCheckScreen(),
        ),
        GoRoute(
          path: '/connection/:tutorId',
          builder: (_, state) =>
              ConnectionScreen(tutorId: state.pathParameters['tutorId']!),
        ),
        GoRoute(
          path: '/chats/:chatId',
          builder: (_, state) =>
              ChatScreen(chatId: state.pathParameters['chatId']!),
        ),
        GoRoute(
          path: '/trial/:chatId/:proposalId',
          builder: (_, state) => TrialScreen(
            chatId: state.pathParameters['chatId']!,
            proposalId: state.pathParameters['proposalId']!,
          ),
        ),
        GoRoute(
          path: '/class/:chatId/:revisionId',
          builder: (_, state) => ClassRevisionScreen(
            chatId: state.pathParameters['chatId']!,
            revisionId: state.pathParameters['revisionId']!,
          ),
        ),
        GoRoute(
          path: '/payment/:invoiceId',
          builder: (_, state) =>
              PaymentScreen(invoiceId: state.pathParameters['invoiceId']!),
        ),
        GoRoute(
          path: '/schedule/:classId',
          builder: (_, state) =>
              ScheduleScreen(classId: state.pathParameters['classId']!),
        ),
        GoRoute(path: '/messages', builder: (_, _) => const MessagesScreen()),
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      ],
      errorBuilder: (_, state) => RouteErrorScreen(
        message: state.error?.toString() ?? 'Không tìm thấy màn hình.',
      ),
    );
    ref.listenManual(authStateProvider, (_, next) {
      final user = next.asData?.value;
      final uid = user?.isAnonymous == false ? user!.uid : null;
      _syncTutorApplicationWatcher(uid);
      _router.refresh();
    }, fireImmediately: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(remoteConfigInitializationProvider);
      ref.read(notificationInitializationProvider);
      _notificationRouteSubscription = ref
          .read(notificationServiceProvider)
          .openedNotifications
          .listen((item) async {
            final route = await ref
                .read(notificationServiceProvider)
                .routeForNotification(item);
            if (mounted && route != null) _router.go(route);
          });
    });
  }

  @override
  void dispose() {
    _notificationRouteSubscription?.cancel();
    _tutorAppSubscription?.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'BeeWise',
    debugShowCheckedModeBanner: false,
    theme: BeeWiseTheme.light,
    routerConfig: _router,
    // Make EMULATOR demo recordings impossible to mistake for live data.
    builder: (context, child) => usesFirebaseEmulators
        ? Banner(
            message: 'EMULATOR',
            location: BannerLocation.topEnd,
            child: child ?? const SizedBox.shrink(),
          )
        : child ?? const SizedBox.shrink(),
  );
}
