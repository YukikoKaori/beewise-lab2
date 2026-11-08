import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/beewise_screens.dart';
import '../services/firebase_bootstrap.dart';
import '../services/notification_service.dart';
import '../screens/tutor_application_screens.dart';
import '../screens/tutor_screens.dart';

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

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/home',
      redirect: (context, state) async {
        final location = state.matchedLocation;
        final user = ref.read(authStateProvider).asData?.value;

        // 1. Guest
        if (user == null) {
          final isTutorProtected =
              location.startsWith('/tutor/') && location != '/tutor/apply';
          return isTutorProtected || location == '/account/check'
              ? '/login'
              : null;
        }

        final service = ref.read(tutorApplicationServiceProvider);
        if (service == null) return null;

        try {
          final isTutorApplicant = await service.hasApplication(user.uid);
          if (isTutorApplicant) {
            final status = await service.status(user.uid);

            // 5. Approved Tutor
            if (status == 'approved') {
              // Approved tutors navigate freely in tutor sections;
              // redirect apply or fallback check to tutor home
              if (location == '/tutor/apply' || location == '/account/check') {
                return '/tutor/home';
              }
              return null;
            }

            // 4. Tutor applicant requiring correction
            if (status == 'needs_info' || status == 'rejected') {
              if (location == '/tutor/pending' ||
                  location == '/tutor/apply' ||
                  location == '/tutor/profile') {
                return null;
              }
              return '/tutor/pending';
            }

            // 3. Tutor applicant awaiting approval (pending)
            if (location == '/tutor/pending' || location == '/tutor/profile') {
              return null;
            }
            return '/tutor/pending';
          }

          // 2. Parent
          // Non-tutor accounts should not enter protected tutor routes
          if (location.startsWith('/tutor/') && location != '/tutor/apply') {
            return '/home';
          }
          if (location == '/account/check') {
            return '/home';
          }
        } catch (_) {
          // 6. Unresolved / connection error
          return location == '/account/check' ? null : '/account/check';
        }
        return null;
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
        // T1 Tutor Registration
        GoRoute(
          path: '/tutor/apply',
          builder: (_, _) => const TutorApplicationScreen(),
        ),
        // T2 Tutor Application Status
        GoRoute(
          path: '/tutor/pending',
          builder: (_, _) => const TutorApplicationStatusScreen(),
        ),
        // T3 Tutor Home / Dashboard
        GoRoute(
          path: '/tutor/home',
          builder: (_, state) => TutorHomeScreen(
            forceEmptyState: state.uri.queryParameters['empty'] == 'true',
          ),
        ),
        // T4 Tutor Group Chat
        GoRoute(
          path: '/tutor/chats/:chatId',
          builder: (_, state) => TutorChatScreen(
            chatId: state.pathParameters['chatId'] ?? 'chat_lan_trang',
          ),
        ),
        // T5 Tutor Class Detail
        GoRoute(
          path: '/tutor/class/:classId',
          builder: (_, state) => TutorClassDetailScreen(
            classId: state.pathParameters['classId'] ?? 'class_toan9_lan',
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
    ref.listenManual(authStateProvider, (_, _) => _router.refresh());
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
