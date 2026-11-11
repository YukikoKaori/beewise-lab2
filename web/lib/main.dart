import 'dart:async';

import 'package:beewise_core/beewise_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

import 'workspace.dart';

const projectId = 'beewise-lab-3';
const emulatorHost = String.fromEnvironment('BEEWISE_FIREBASE_EMULATOR_HOST');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BeeWiseAdmin());
}

class AdminSession {
  const AdminSession(this.auth, this.store, this.analytics, this.config);

  final FirebaseAuth auth;
  final BeeWiseFirestore store;
  final FirebaseAnalytics? analytics;
  final FirebaseRemoteConfig? config;

  Future<void> event(String name, [Map<String, Object>? params]) async {
    try {
      await analytics?.logEvent(name: name, parameters: params);
    } catch (_) {
      // Telemetry is independent of privileged actions.
    }
  }
}

Future<AdminSession> initialize() async {
  const appId = String.fromEnvironment('BEEWISE_WEB_APP_ID');
  const apiKey = String.fromEnvironment('BEEWISE_WEB_API_KEY');
  const authDomain = String.fromEnvironment('BEEWISE_WEB_AUTH_DOMAIN');
  const measurement = String.fromEnvironment('BEEWISE_WEB_MEASUREMENT_ID');
  const appCheckKey = String.fromEnvironment('BEEWISE_WEB_APPCHECK_SITE_KEY');
  const local = emulatorHost != '';
  if (!local &&
      (appId.isEmpty ||
          apiKey.isEmpty ||
          authDomain.isEmpty ||
          measurement.isEmpty ||
          appCheckKey.isEmpty)) {
    throw StateError('Missing registered BeeWise Firebase Web settings.');
  }
  if (local && emulatorHost != 'localhost' && emulatorHost != '127.0.0.1') {
    throw StateError('Use the local Firebase Emulator Suite on this machine.');
  }
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: local ? 'demo-api-key' : apiKey,
        appId: local ? '1:840483888286:web:0000000000000000000000' : appId,
        messagingSenderId: '840483888286',
        projectId: projectId,
        authDomain: local ? 'localhost' : authDomain,
        measurementId: local ? null : measurement,
      ),
    );
  }
  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;
  if (local) {
    await auth.useAuthEmulator(
      emulatorHost,
      const int.fromEnvironment(
        'BEEWISE_FIREBASE_AUTH_PORT',
        defaultValue: 9099,
      ),
    );
    db.useFirestoreEmulator(
      emulatorHost,
      const int.fromEnvironment('BEEWISE_FIRESTORE_PORT', defaultValue: 8080),
    );
    return AdminSession(auth, BeeWiseFirestore(db), null, null);
  }
  await FirebaseAppCheck.instance.activate(
    providerWeb: ReCaptchaEnterpriseProvider(appCheckKey),
  );
  final config = FirebaseRemoteConfig.instance;
  await config.setDefaults(const {'admin_announcements_enabled': true});
  await config.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(minutes: 5),
    ),
  );
  unawaited(
    config.fetchAndActivate().then<void>((_) {}, onError: (Object _) {}),
  );
  return AdminSession(
    auth,
    BeeWiseFirestore(db),
    FirebaseAnalytics.instance,
    config,
  );
}

class BeeWiseAdmin extends StatefulWidget {
  const BeeWiseAdmin({super.key});

  @override
  State<BeeWiseAdmin> createState() => _BeeWiseAdminState();
}

class _BeeWiseAdminState extends State<BeeWiseAdmin> {
  late var _session = initialize();

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BeeWise Admin',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: BeeWiseColors.primary),
      scaffoldBackgroundColor: BeeWiseColors.canvas,
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: FutureBuilder(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final session = snapshot.data;
        if (session == null) {
          return Scaffold(
            body: Center(
              child: StatusPanel(
                title: 'Chưa thể kết nối BeeWise Admin',
                detail: 'Kiểm tra kết nối và cấu hình Web, sau đó thử lại.',
                action: () => setState(() => _session = initialize()),
              ),
            ),
          );
        }
        final screen = StaffGate(session: session);
        return emulatorHost.isEmpty
            ? screen
            : Banner(
                message: 'EMULATOR',
                location: BannerLocation.topEnd,
                child: screen,
              );
      },
    ),
  );
}

class StaffGate extends StatefulWidget {
  const StaffGate({super.key, required this.session});

  final AdminSession session;

  @override
  State<StaffGate> createState() => _StaffGateState();
}

class _StaffGateState extends State<StaffGate> {
  late final Stream<User?> _auth = widget.session.auth.idTokenChanges();
  var _working = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await widget.session.auth.signInWithPopup(GoogleAuthProvider());
      unawaited(widget.session.event('admin_google_sign_in'));
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(
          () => _error = switch (e.code) {
            'popup-closed-by-user' || 'cancelled-popup-request' =>
              'Bạn đã đóng cửa sổ đăng nhập. Bạn có thể thử lại.',
            'popup-blocked' => 'Hãy cho phép cửa sổ đăng nhập rồi thử lại.',
            'network-request-failed' =>
              'Mất kết nối. Kiểm tra mạng rồi thử lại.',
            _ => 'Google Sign-In chưa thành công. Hãy thử lại.',
          },
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: _auth,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Scaffold(
          body: Center(
            child: Text('Lỗi khôi phục phiên đăng nhập. Hãy tải lại trang.'),
          ),
        );
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final user = snapshot.data;
      if (user != null) {
        return StaffRoleGate(
          key: ValueKey(user.uid),
          session: widget.session,
          user: user,
        );
      }
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 450,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.hive_rounded,
                        size: 48,
                        color: BeeWiseColors.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'BeeWise Admin',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Quản lý hồ sơ gia sư và thông báo BeeWise. Chỉ dành cho nhân viên được cấp quyền.',
                      ),
                      const SizedBox(height: 24),
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: const TextStyle(color: BeeWiseColors.error),
                        ),
                        const SizedBox(height: 16),
                      ],
                      FilledButton.icon(
                        onPressed: _working ? null : _login,
                        icon: const Icon(Icons.login),
                        label: Text(
                          _working
                              ? 'Đang đăng nhập…'
                              : 'Đăng nhập bằng Google',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class StaffRoleGate extends StatefulWidget {
  const StaffRoleGate({super.key, required this.session, required this.user});

  final AdminSession session;
  final User user;

  @override
  State<StaffRoleGate> createState() => _StaffRoleGateState();
}

class _StaffRoleGateState extends State<StaffRoleGate> {
  late var _claims = widget.user.getIdTokenResult();
  late var _role = _watchRole();

  Stream<DocumentSnapshot<Map<String, dynamic>>> _watchRole() => widget
      .session
      .store
      .user(widget.user.uid)
      .snapshots(includeMetadataChanges: true);

  @override
  void didUpdateWidget(StaffRoleGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.user, widget.user)) {
      _claims = widget.user.getIdTokenResult();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _claims,
    builder: (context, token) {
      if (token.hasError) {
        return _deny('Không xác minh được phiên Google.', retry: true);
      }
      if (token.connectionState == ConnectionState.waiting) return _waiting();
      if (token.data?.signInProvider != 'google.com' ||
          token.data?.claims?['email_verified'] != true) {
        return _deny(
          'Hãy dùng tài khoản Google đã xác minh của nhân viên BeeWise.',
        );
      }
      return StreamBuilder(
        stream: _role,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _deny('Không thể kiểm tra quyền truy cập.', retry: true);
          }
          final doc = snapshot.data;
          if (doc == null ||
              doc.metadata.isFromCache ||
              doc.metadata.hasPendingWrites) {
            return _waiting();
          }
          final role = BeeWiseRole.fromValue(doc.data()?['role']);
          if (!role.canReview) {
            return _deny(
              'Tài khoản này không có quyền nhân viên. Hãy dùng tài khoản khác.',
            );
          }
          return Navigator(
            key: ValueKey(role),
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => AdminWorkspace(
                session: widget.session,
                uid: widget.user.uid,
                role: role,
              ),
            ),
          );
        },
      );
    },
  );

  Widget _waiting() => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          const Text('Đang xác minh quyền truy cập…'),
          TextButton(
            onPressed: widget.session.auth.signOut,
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    ),
  );

  Widget _deny(String message, {bool retry = false}) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusPanel(
            title: 'Chưa mở được trang quản trị',
            detail: message,
            action: retry
                ? () => setState(() {
                    _claims = widget.user.getIdTokenResult(true);
                    _role = _watchRole();
                  })
                : null,
          ),
          TextButton(
            onPressed: widget.session.auth.signOut,
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    ),
  );
}
