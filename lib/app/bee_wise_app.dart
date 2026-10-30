import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/beewise_screens.dart';
import '../screens/tutor_application_screens.dart';
import '../theme/bee_wise_theme.dart';
import '../viewmodels/app_providers.dart';

class BeeWiseApp extends ConsumerStatefulWidget {
  const BeeWiseApp({super.key});

  @override
  ConsumerState<BeeWiseApp> createState() => _BeeWiseAppState();
}

class _BeeWiseAppState extends ConsumerState<BeeWiseApp> {
  late final GoRouter _router;
  StreamSubscription<String>? _notificationRouteSubscription;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/home',
      redirect: (context, state) async {
        final location = state.matchedLocation;
        final user = ref.read(authStateProvider).asData?.value;
        if (user == null) {
          return location == '/tutor/pending' || location == '/account/check'
              ? '/login'
              : null;
        }
        final service = ref.read(tutorApplicationServiceProvider);
        if (service == null) return null;
        try {
          final isTutorApplicant = await service.hasApplication(user.uid);
          if (isTutorApplicant) {
            return location == '/tutor/pending' ? null : '/tutor/pending';
          }
          if (location == '/tutor/pending' ||
              location == '/tutor/apply' ||
              location == '/account/check') {
            return '/home';
          }
        } catch (_) {
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
        GoRoute(
          path: '/tutor/apply',
          builder: (_, _) => const TutorApplicationScreen(),
        ),
        GoRoute(
          path: '/tutor/pending',
          builder: (_, _) => const TutorApplicationStatusScreen(),
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
          .openedRoutes
          .listen((route) => _router.go(route));
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
  );
}
