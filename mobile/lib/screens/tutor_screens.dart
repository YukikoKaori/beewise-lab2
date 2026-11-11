import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../models/tutor_workspace_models.dart';
import '../services/notification_service.dart';
import '../services/tutor_workspace_service.dart';
import '../theme/bee_wise_theme.dart';
import '../viewmodels/app_providers.dart';
import '../viewmodels/controllers.dart';
import '../widgets/bee_wise_widgets.dart';

String _tutorFriendlyError(Object error) {
  final state = classifyTutorDataError(error);
  if (state == TutorDataSourceState.rulesBlocked) {
    if (error is TutorBackendRulesDependencyException) {
      return error.message;
    }
    return FirebaseTutorWorkspaceService.tutorRulesBlockedMessage;
  }
  if (state == TutorDataSourceState.networkError) {
    if (error is TutorNetworkException) return error.message;
    return 'Không kết nối được dịch vụ. Hãy kiểm tra mạng rồi thử lại.';
  }
  return friendlyError(error);
}

Widget _buildTutorRulesBlockedCard({
  required String title,
  required String message,
  VoidCallback? onRetry,
}) => Container(
  padding: const EdgeInsets.all(BeeWiseSpace.x4),
  decoration: BoxDecoration(
    color: const Color(0xFFFFFBEB),
    borderRadius: BorderRadius.circular(BeeWiseRadius.card),
    border: Border.all(color: const Color(0xFFFDE68A)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_clock_outlined,
            size: 20,
            color: Color(0xFFD97706),
          ),
          const SizedBox(width: BeeWiseSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF78350F),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      if (onRetry != null) ...[
        const SizedBox(height: BeeWiseSpace.x3),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Thử lại'),
          ),
        ),
      ],
    ],
  ),
);

/// 4-tab Bottom Navigation for Tutor experience matching Figma T3, T6, T7
class TutorBottomNavigation extends StatelessWidget {
  const TutorBottomNavigation({super.key, required this.selectedIndex});

  final int selectedIndex;

  static const _routes = [
    '/tutor/home',
    '/tutor/schedule',
    '/tutor/chats',
    '/tutor/profile',
  ];

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: (index) {
      if (index < _routes.length) {
        context.go(_routes[index]);
      }
    },
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Trang chủ',
      ),
      NavigationDestination(
        icon: Icon(Icons.calendar_today_outlined),
        selectedIcon: Icon(Icons.calendar_month_rounded),
        label: 'Lịch dạy',
      ),
      NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline_rounded),
        selectedIcon: Icon(Icons.chat_bubble_rounded),
        label: 'Tin nhắn',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Hồ sơ',
      ),
    ],
  );
}

/// T3: Trang chủ gia sư (Tutor Dashboard / Home)
/// Driven by real authenticated tutor data via [tutorDashboardProvider].
class TutorHomeScreen extends ConsumerWidget {
  const TutorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    final uid = user?.isAnonymous == false ? user!.uid : null;
    final appData = uid != null
        ? ref.watch(tutorApplicationDataProvider(uid)).asData?.value
        : null;
    final dashboardAsync = ref.watch(tutorDashboardProvider);
    final notifications =
        ref.watch(notificationsProvider).asData?.value ?? const [];
    final seenAt = ref.watch(notificationsSeenAtProvider);
    final hasNotifications = notifications.any(
      (n) =>
          (n.recipientUid == null || n.recipientUid == uid) &&
          (seenAt == null || n.receivedAt.isAfter(seenAt)),
    );

    final tutorName = appData?.name.trim().isNotEmpty == true
        ? appData!.name.trim()
        : (user?.displayName?.trim().isNotEmpty == true
              ? user!.displayName!.trim()
              : 'Chưa cập nhật');
    final shortName = tutorName != 'Chưa cập nhật' && tutorName.contains(' ')
        ? tutorName.split(RegExp(r'\s+')).last
        : (tutorName != 'Chưa cập nhật' ? tutorName : 'bạn');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 68,
        title: Row(
          children: [
            Image.asset(
              'assets/brand/logo-horizontal.png',
              height: 28,
              errorBuilder: (_, _, _) => const Text(
                'BeeWise',
                style: TextStyle(
                  color: BeeWiseColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: BeeWiseSpace.x2),
            Expanded(
              child: Text(
                'Gia sư: $tutorName',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BeeWiseColors.muted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới dữ liệu',
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: () => ref.invalidate(tutorDashboardProvider),
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                tooltip: 'Thông báo',
                icon: const Icon(Icons.notifications_none_rounded, size: 26),
                onPressed: () => context.push('/tutor/notifications'),
              ),
              if (hasNotifications)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: BeeWiseColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: BeeWiseColors.border),
        ),
      ),
      body: SafeArea(
        child: dashboardAsync.when(
          skipLoadingOnReload: false,
          skipLoadingOnRefresh: false,
          skipError: false,
          loading: () => const LoadingStateView(),
          error: (error, _) {
            if (error is TutorUnauthorizedException) {
              return Padding(
                padding: const EdgeInsets.all(BeeWiseSpace.x4),
                child: EmptyStateView(
                  title: 'Không có quyền truy cập',
                  message: error.message,
                  icon: Icons.lock_outline_rounded,
                  action: BeeWiseButton(
                    label: 'Kiểm tra trạng thái hồ sơ',
                    onPressed: () => context.go('/tutor/pending'),
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(BeeWiseSpace.x4),
              children: [
                ErrorStateView(
                  message: _tutorFriendlyError(error),
                  onRetry: () => ref.invalidate(tutorDashboardProvider),
                ),
              ],
            );
          },
          data: (dashboard) {
            if (dashboard.isFullyRulesBlocked) {
              return ListView(
                padding: const EdgeInsets.all(BeeWiseSpace.x4),
                children: [
                  ErrorStateView(
                    message:
                        dashboard.backendAccessLimitation ??
                        FirebaseTutorWorkspaceService.tutorRulesBlockedMessage,
                    onRetry: () => ref.invalidate(tutorDashboardProvider),
                  ),
                ],
              );
            }

            final isVerifiedEmpty = dashboard.isVerifiedEmpty;
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(tutorDashboardProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: BeeWiseSpace.x4,
                  vertical: BeeWiseSpace.x4,
                ),
                children: [
                  Text(
                    'Chào $shortName,',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: BeeWiseColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isVerifiedEmpty
                        ? 'Chưa có việc cần làm'
                        : 'Việc cần làm hôm nay',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: BeeWiseColors.primary,
                    ),
                  ),
                  const SizedBox(height: BeeWiseSpace.x4),

                  if (dashboard.backendAccessLimitation != null) ...[
                    StatusBanner(message: dashboard.backendAccessLimitation!),
                    const SizedBox(height: BeeWiseSpace.x3),
                  ],

                  if (isVerifiedEmpty) ...[
                    // EMPTY STATE CARD matching Figma T3
                    Card(
                      elevation: 0,
                      color: BeeWiseColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                        side: const BorderSide(color: BeeWiseColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BeeWiseSpace.x4,
                          vertical: BeeWiseSpace.x6,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(
                                  BeeWiseRadius.card,
                                ),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 32,
                                color: BeeWiseColors.primary,
                              ),
                            ),
                            const SizedBox(height: BeeWiseSpace.x4),
                            Text(
                              'Chưa có nhóm chat nào',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: BeeWiseSpace.x2),
                            const Text(
                              'Khi phụ huynh bấm kết nối với bạn, nhóm chat cùng tư vấn viên sẽ mở tại đây.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: BeeWiseColors.muted,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: BeeWiseSpace.x5),
                            BeeWiseButton(
                              label: 'Xem hồ sơ công khai',
                              onPressed: () => context.go('/tutor/profile'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: BeeWiseSpace.x4),

                    Container(
                      padding: const EdgeInsets.all(BeeWiseSpace.x4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: BeeWiseColors.primary,
                          ),
                          SizedBox(width: BeeWiseSpace.x3),
                          Expanded(
                            child: Text(
                              'Hồ sơ đầy đủ lịch rảnh và học phí rõ ràng giúp phụ huynh dễ kết nối hơn.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF78350F),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Section 1: Nhóm chat mới
                    if (dashboard.isChatsRulesBlocked) ...[
                      _buildTutorRulesBlockedCard(
                        title: 'Nhóm chat chưa cấp quyền đồng bộ',
                        message:
                            dashboard.chatsBlockMessage ??
                            FirebaseTutorWorkspaceService
                                .tutorRulesBlockedMessage,
                        onRetry: () => ref.invalidate(tutorDashboardProvider),
                      ),
                      const SizedBox(height: BeeWiseSpace.x3),
                    ] else if (dashboard.chats.isNotEmpty) ...[
                      Text(
                        'Nhóm chat',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: BeeWiseSpace.x2),
                      for (final chat in dashboard.chats) ...[
                        Card(
                          elevation: 0,
                          color: BeeWiseColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              BeeWiseRadius.card,
                            ),
                            side: const BorderSide(color: BeeWiseColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(BeeWiseSpace.x4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFDE047),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        chat.parentInitials,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: BeeWiseSpace.x3),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            chat.subjectSummary.isNotEmpty
                                                ? '${chat.parentName} · ${chat.subjectSummary}'
                                                : chat.parentName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: BeeWiseColors.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            chat.areaSummary.isNotEmpty
                                                ? chat.areaSummary
                                                : chat.onboardingStatusLabel,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: BeeWiseColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (chat.isNew)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E40AF),
                                          borderRadius: BorderRadius.circular(
                                            BeeWiseRadius.full,
                                          ),
                                        ),
                                        child: const Text(
                                          'Mới',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: BeeWiseSpace.x3),
                                Text(
                                  (chat.lastMessageText != null &&
                                          chat.lastMessageText!.isNotEmpty)
                                      ? chat.lastMessageText!
                                      : chat.onboardingStatusLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF334155),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: BeeWiseSpace.x4),
                                BeeWiseButton(
                                  label: 'Vào nhóm chat',
                                  icon: Icons.chat_bubble_outline_rounded,
                                  onPressed: () =>
                                      context.push('/tutor/chats/${chat.id}'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: BeeWiseSpace.x3),
                      ],
                      const SizedBox(height: BeeWiseSpace.x2),
                    ],

                    if (dashboard.isClassesRulesBlocked) ...[
                      _buildTutorRulesBlockedCard(
                        title: 'Lớp học & lịch dạy chưa cấp quyền đồng bộ',
                        message:
                            dashboard.classesBlockMessage ??
                            FirebaseTutorWorkspaceService
                                .tutorRulesBlockedMessage,
                        onRetry: () => ref.invalidate(tutorDashboardProvider),
                      ),
                      const SizedBox(height: BeeWiseSpace.x3),
                    ],

                    // Section 2: Buổi học sắp tới
                    if (!dashboard.isClassesRulesBlocked &&
                        dashboard.upcomingSessions.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Buổi học sắp tới',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: BeeWiseSpace.x2),
                          InkWell(
                            onTap: () => context.go('/tutor/schedule'),
                            child: const Text(
                              'Lịch dạy',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: BeeWiseColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: BeeWiseSpace.x2),
                      for (final session in dashboard.upcomingSessions) ...[
                        Card(
                          elevation: 0,
                          color: BeeWiseColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              BeeWiseRadius.card,
                            ),
                            side: const BorderSide(color: BeeWiseColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(BeeWiseSpace.x4),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: BeeWiseColors.primary,
                                    borderRadius: BorderRadius.circular(
                                      BeeWiseRadius.md,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    session.weekdayTileLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: BeeWiseSpace.x3),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        session.timeAndDateLabel,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: BeeWiseColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        session.subtitleLabel,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: BeeWiseColors.muted,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: session.confirmed
                                              ? const Color(0xFFDCFCE7)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(
                                            BeeWiseRadius.full,
                                          ),
                                        ),
                                        child: Text(
                                          session.sessionProgressLabel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: session.confirmed
                                                ? const Color(0xFF15803D)
                                                : const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: BeeWiseSpace.x3),
                      ],
                      const SizedBox(height: BeeWiseSpace.x2),
                    ],

                    // Section 3: Lớp đang dạy
                    if (!dashboard.isClassesRulesBlocked &&
                        dashboard.activeClasses.isNotEmpty) ...[
                      Text(
                        'Lớp đang dạy',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: BeeWiseSpace.x2),
                      for (final cls in dashboard.activeClasses) ...[
                        Card(
                          elevation: 0,
                          color: BeeWiseColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              BeeWiseRadius.card,
                            ),
                            side: const BorderSide(color: BeeWiseColors.border),
                          ),
                          child: InkWell(
                            onTap: () => context.push('/tutor/class/${cls.id}'),
                            borderRadius: BorderRadius.circular(
                              BeeWiseRadius.card,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(BeeWiseSpace.x4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cls.title,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: BeeWiseColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${cls.parentName} · ${cls.scheduleSummary}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: BeeWiseColors.muted,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: cls.isPaymentVerified
                                                ? const Color(0xFFDCFCE7)
                                                : const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(
                                              BeeWiseRadius.full,
                                            ),
                                          ),
                                          child: Text(
                                            cls.isPaymentVerified
                                                ? 'Phụ huynh đã thanh toán'
                                                : 'Chờ xác nhận thanh toán',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: cls.isPaymentVerified
                                                  ? const Color(0xFF15803D)
                                                  : const Color(0xFF92400E),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: BeeWiseColors.muted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: BeeWiseSpace.x3),
                      ],
                    ],
                  ],
                  const SizedBox(height: BeeWiseSpace.x6),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const TutorBottomNavigation(selectedIndex: 0),
    );
  }
}

/// T4: Nhóm chat gia sư (Tutor Group Chat matching Figma T4)
/// Supports both `/tutor/chats` (list of authorized chats) and `/tutor/chats/:chatId`.
class TutorChatScreen extends ConsumerStatefulWidget {
  const TutorChatScreen({super.key, this.chatId});

  final String? chatId;

  @override
  ConsumerState<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends ConsumerState<TutorChatScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String chatId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final sent = await ref
        .read(tutorChatComposerControllerProvider.notifier)
        .send(chatId: chatId, text: text);
    if (sent && mounted) {
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeChatId = widget.chatId?.trim();
    if (activeChatId == null || activeChatId.isEmpty) {
      return _buildChatListScaffold(context);
    }
    return _buildChatSessionScaffold(context, activeChatId);
  }

  Widget _buildChatListScaffold(BuildContext context) {
    final chatsAsync = ref.watch(tutorChatsProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Tin nhắn nhóm',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới danh sách chat',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(tutorChatsProvider),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: BeeWiseColors.border),
        ),
      ),
      body: SafeArea(
        child: chatsAsync.when(
          skipLoadingOnReload: false,
          skipLoadingOnRefresh: false,
          skipError: false,
          loading: () => const LoadingStateView(),
          error: (error, _) {
            if (error is TutorUnauthorizedException) {
              return Padding(
                padding: const EdgeInsets.all(BeeWiseSpace.x4),
                child: EmptyStateView(
                  title: 'Không có quyền truy cập',
                  message: error.message,
                  icon: Icons.lock_outline_rounded,
                  action: BeeWiseButton(
                    label: 'Kiểm tra trạng thái hồ sơ',
                    onPressed: () => context.go('/tutor/pending'),
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(BeeWiseSpace.x4),
              children: [
                ErrorStateView(
                  message: _tutorFriendlyError(error),
                  onRetry: () => ref.invalidate(tutorChatsProvider),
                ),
              ],
            );
          },
          data: (chats) {
            if (chats.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(BeeWiseSpace.x4),
                child: EmptyStateView(
                  title: 'Chưa có nhóm chat nào',
                  message: 'Khi phụ huynh gửi yêu cầu kết nối với bạn, nhóm chat cùng tư vấn viên sẽ hiển thị tại đây.',
                  icon: Icons.chat_bubble_outline_rounded,
                  action: BeeWiseButton(
                    label: 'Về trang chủ gia sư',
                    secondary: true,
                    onPressed: () => context.go('/tutor/home'),
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(tutorChatsProvider),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(BeeWiseSpace.x4),
                itemCount: chats.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: BeeWiseSpace.x3),
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  return Card(
                    elevation: 0,
                    color: BeeWiseColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                      side: const BorderSide(color: BeeWiseColors.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(BeeWiseSpace.x3),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFFDE047),
                        child: Text(
                          chat.parentInitials,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      title: Text(
                        chat.subjectSummary.isNotEmpty
                            ? '${chat.parentName} · ${chat.subjectSummary}'
                            : chat.parentName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        chat.lastMessageText?.isNotEmpty == true
                            ? chat.lastMessageText!
                            : chat.onboardingStatusLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/tutor/chats/${chat.id}'),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const TutorBottomNavigation(selectedIndex: 2),
    );
  }

  Widget _buildChatSessionScaffold(BuildContext context, String chatId) {
    final sessionAsync = ref.watch(tutorChatSessionProvider(chatId));
    final sendState = ref.watch(tutorChatComposerControllerProvider);

    return sessionAsync.when(
      skipLoadingOnReload: false,
      skipLoadingOnRefresh: false,
      skipError: false,
      loading: () => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/tutor/home'),
          ),
          title: const Text('Nhóm chat'),
        ),
        body: const LoadingStateView(),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/tutor/home'),
          ),
          title: const Text('Nhóm chat'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(BeeWiseSpace.x4),
          children: [
            if (error is TutorUnauthorizedException)
              EmptyStateView(
                title: 'Không có quyền truy cập nhóm chat',
                message: error.message,
                icon: Icons.lock_outline_rounded,
                action: BeeWiseButton(
                  label: 'Về trang chủ gia sư',
                  onPressed: () => context.go('/tutor/home'),
                ),
              )
            else if (error is TutorResourceNotFoundException)
              EmptyStateView(
                title: 'Không tìm thấy nhóm chat',
                message: error.message,
                icon: Icons.search_off_rounded,
                action: BeeWiseButton(
                  label: 'Về trang chủ gia sư',
                  onPressed: () => context.go('/tutor/home'),
                ),
              )
            else
              ErrorStateView(
                message: _tutorFriendlyError(error),
                onRetry: () => ref.invalidate(tutorChatSessionProvider(chatId)),
              ),
          ],
        ),
      ),
      data: (session) {
        final summary = session.summary;
        final canSend = session.canSendMessages && !sendState.isSending;
        final hasSendFailure =
            sendState.hasFailed && sendState.chatId == chatId;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/tutor/home'),
            ),
            title: Text(
              'Nhóm: ${summary.parentName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Nhóm hỗ trợ chính thức gồm Phụ huynh, Gia sư và Tư vấn viên BeeWise.',
                    ),
                  ),
                ),
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 1,
                color: BeeWiseColors.border,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Group Header Banner matching Figma T4
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                    border: Border.all(color: BeeWiseColors.border),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        height: 32,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFFFDE047),
                              child: Text(
                                summary.parentInitials,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFFF59E0B),
                                child: Text(
                                  summary.consultantInitials,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary.consultantName != null
                                  ? 'Phụ huynh ${summary.parentName} · ${tutorConsultantLabel(summary.consultantName!)}'
                                  : 'Phụ huynh ${summary.parentName}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: BeeWiseColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(
                                  BeeWiseRadius.full,
                                ),
                              ),
                              child: Text(
                                summary.onboardingStatusLabel,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (summary.createdAt != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${summary.parentName} đã kết nối · Nhóm chat tạo lúc ${DateFormat('HH:mm').format(summary.createdAt!)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: BeeWiseColors.muted,
                      ),
                    ),
                  ),

                // Chat Message Stream
                Expanded(
                  child: session.messages.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(BeeWiseSpace.x4),
                            child: EmptyStateView(
                              title: 'Chưa có tin nhắn',
                              message: 'Tin nhắn từ phụ huynh, gia sư và tư vấn viên trong nhóm này sẽ hiển thị tại đây.',
                              icon: Icons.chat_bubble_outline_rounded,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: session.messages.length,
                          itemBuilder: (context, index) =>
                              _buildChatMessageItem(
                                context,
                                summary: summary,
                                message: session.messages[index],
                              ),
                        ),
                ),

                // Send Failure Banner + Retry
                if (hasSendFailure)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFFEF2F2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: BeeWiseColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sendState.errorMessage ??
                                'Gửi tin nhắn thất bại. Vui lòng thử lại.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: sendState.isSending
                              ? null
                              : () async {
                                  final ok = await ref
                                      .read(
                                        tutorChatComposerControllerProvider
                                            .notifier,
                                      )
                                      .retry();
                                  if (ok && mounted) {
                                    _messageController.clear();
                                  }
                                },
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),

                // Rules Limitation Notice when composer is disabled
                if (!session.canSendMessages &&
                    session.sendDisabledReason != null)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFFFFBEB),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_clock_outlined,
                          size: 16,
                          color: Color(0xFF92400E),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            session.sendDisabledReason!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF78350F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Composer Dock matching Figma T4
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: BeeWiseColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          enabled: canSend,
                          decoration: InputDecoration(
                            hintText: session.canSendMessages
                                ? 'Nhập tin nhắn...'
                                : 'Gia sư chưa thể gửi tin nhắn trong nhóm',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                BeeWiseRadius.full,
                              ),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                BeeWiseRadius.full,
                              ),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          onSubmitted: canSend
                              ? (_) => _sendMessage(chatId)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: canSend
                              ? BeeWiseColors.primary
                              : const Color(0xFFCBD5E1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          tooltip: 'Gửi tin nhắn',
                          icon: sendState.isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                          onPressed: canSend
                              ? () => _sendMessage(chatId)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatMessageItem(
    BuildContext context, {
    required TutorChatSummary summary,
    required ChatMessage message,
  }) {
    final timeStr = DateFormat('HH:mm').format(message.createdAt);

    if (message.kind == 'trial_proposal' || message.kind == 'class_revision') {
      final isTrial = message.kind == 'trial_proposal';
      final proposal = message.payload;
      final scheduleLine = tutorProposalSummaryLine(proposal, isTrial: isTrial);
      final status = tutorProposalStatus(proposal);

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(BeeWiseRadius.card),
          border: Border.all(color: BeeWiseColors.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bookmark_border_rounded,
                  color: BeeWiseColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isTrial
                        ? 'Đề xuất buổi học thử'
                        : 'Thông tin lớp học đề xuất',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: BeeWiseColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              scheduleLine.isNotEmpty ? scheduleLine : message.body,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: BeeWiseColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: status.background,
                borderRadius: BorderRadius.circular(BeeWiseRadius.full),
              ),
              child: Text(
                status.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: status.foreground,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chỉ tư vấn viên gửi đề xuất và phụ huynh xác nhận. Bạn theo dõi thông tin tại đây.',
              style: TextStyle(
                fontSize: 12,
                color: BeeWiseColors.muted,
                height: 1.35,
              ),
            ),
            if (summary.classId != null && summary.classId!.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                  side: const BorderSide(color: BeeWiseColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(BeeWiseRadius.full),
                  ),
                ),
                onPressed: () =>
                    context.push('/tutor/class/${summary.classId}'),
                child: const Text(
                  'Xem chi tiết',
                  style: TextStyle(
                    color: BeeWiseColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (message.role == 'tutor') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeStr.isNotEmpty ? 'Đã gửi · $timeStr' : 'Đã gửi',
              style: const TextStyle(fontSize: 11, color: BeeWiseColors.muted),
            ),
            const SizedBox(height: 4),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BeeWiseColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.body,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isConsultant =
        message.role == 'consultant' || message.role == 'system';
    final senderName = isConsultant
        ? (summary.consultantName ?? 'Tư vấn viên')
        : summary.parentName;
    final roleBadge = isConsultant ? 'TƯ VẤN VIÊN' : 'PHỤ HUYNH';
    final avatarText = isConsultant
        ? summary.consultantInitials
        : summary.parentInitials;
    final avatarBg = isConsultant
        ? const Color(0xFFF59E0B)
        : const Color(0xFFFDE047);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: avatarBg,
            child: Text(
              avatarText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isConsultant ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      senderName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isConsultant
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        roleBadge,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isConsultant
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    if (timeStr.isNotEmpty)
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 10,
                          color: BeeWiseColors.muted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BeeWiseColors.border),
                  ),
                  child: Text(
                    message.body,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: BeeWiseColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// T5: Quản lý lớp học (Class Detail matching Figma T5)
/// Driven by real authorized class record via [tutorClassDetailProvider].
class TutorClassDetailScreen extends ConsumerWidget {
  const TutorClassDetailScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classAsync = ref.watch(tutorClassDetailProvider(classId));

    return classAsync.when(
      skipLoadingOnReload: false,
      skipLoadingOnRefresh: false,
      skipError: false,
      loading: () => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/tutor/home'),
          ),
          title: const Text('Chi tiết lớp học'),
        ),
        body: const LoadingStateView(),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/tutor/home'),
          ),
          title: const Text('Chi tiết lớp học'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(BeeWiseSpace.x4),
          children: [
            if (error is TutorUnauthorizedException)
              EmptyStateView(
                title: 'Không có quyền truy cập lớp học',
                message: error.message,
                icon: Icons.lock_outline_rounded,
                action: BeeWiseButton(
                  label: 'Về trang chủ gia sư',
                  onPressed: () => context.go('/tutor/home'),
                ),
              )
            else if (error is TutorResourceNotFoundException)
              EmptyStateView(
                title: 'Không tìm thấy lớp học',
                message: error.message,
                icon: Icons.search_off_rounded,
                action: BeeWiseButton(
                  label: 'Về trang chủ gia sư',
                  onPressed: () => context.go('/tutor/home'),
                ),
              )
            else
              ErrorStateView(
                message: _tutorFriendlyError(error),
                onRetry: () =>
                    ref.invalidate(tutorClassDetailProvider(classId)),
              ),
          ],
        ),
      ),
      data: (cls) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/tutor/home'),
          ),
          title: Text(
            'Lớp: ${cls.title} — ${cls.parentName}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(
              height: 1,
              thickness: 1,
              color: BeeWiseColors.border,
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(BeeWiseSpace.x4),
            children: [
              // 4-Step Stepper matching Figma T5
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStepItem(
                    title: 'HỌC THỬ',
                    isDone: cls.onboardingStage > 1,
                    isActive: cls.onboardingStage == 1,
                    stepNum: 1,
                  ),
                  _buildStepItem(
                    title: 'XÁC NHẬN LỚP',
                    isDone: cls.onboardingStage > 2,
                    isActive: cls.onboardingStage == 2,
                    stepNum: 2,
                  ),
                  _buildStepItem(
                    title: 'THANH TOÁN',
                    isDone: cls.isPaymentVerified,
                    isActive:
                        cls.onboardingStage == 3 && !cls.isPaymentVerified,
                    stepNum: 3,
                  ),
                  _buildStepItem(
                    title: 'LỊCH HỌC',
                    isDone: false,
                    isActive: cls.isPaymentVerified,
                    stepNum: 4,
                  ),
                ],
              ),
              const SizedBox(height: BeeWiseSpace.x4),

              // Payment Status Banner — ONLY green when server-verified
              if (cls.isPaymentVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(BeeWiseRadius.full),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: Color(0xFF15803D),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cls.totalSessions != null && cls.totalSessions! > 0
                              ? '${cls.parentName} đã thanh toán cho ${cls.totalSessions} buổi học chính thức'
                              : '${cls.parentName} đã thanh toán học phí chính thức',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(BeeWiseRadius.full),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: Color(0xFF92400E),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chờ xác nhận thanh toán học phí từ ${cls.parentName}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: BeeWiseSpace.x3),

              // Title
              Text(
                cls.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: BeeWiseColors.primary,
                ),
              ),
              const SizedBox(height: BeeWiseSpace.x3),

              // Main Info Card
              Card(
                elevation: 0,
                color: BeeWiseColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                  side: const BorderSide(color: BeeWiseColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(BeeWiseSpace.x4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFDE047),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              cls.parentInitials,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          const SizedBox(width: BeeWiseSpace.x3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${cls.parentName} (Phụ huynh)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: BeeWiseColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cls.studentSummaryText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: BeeWiseColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: BeeWiseSpace.x3),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: BeeWiseSpace.x3),

                      _buildDetailRow(
                        icon: Icons.calendar_month_outlined,
                        title: 'Lịch chính thức',
                        value: cls.scheduleSummary,
                      ),
                      const SizedBox(height: BeeWiseSpace.x3),
                      _buildDetailRow(
                        icon: Icons.location_on_outlined,
                        title: 'Địa điểm',
                        value: cls.locationSummary,
                      ),
                      const SizedBox(height: BeeWiseSpace.x3),
                      _buildDetailRow(
                        icon: Icons.payments_outlined,
                        title: 'Học phí khóa',
                        value: cls.feeBreakdownText,
                      ),
                      const SizedBox(height: BeeWiseSpace.x3),
                      _buildDetailRow(
                        icon: Icons.person_outline_rounded,
                        title: 'Tư vấn viên phụ trách',
                        value: cls.consultantName?.isNotEmpty == true
                            ? cls.consultantName!
                            : 'Đang phân công',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: BeeWiseSpace.x4),

              // Read-only Disclaimer Card
              Container(
                padding: const EdgeInsets.all(BeeWiseSpace.x4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: BeeWiseColors.primary,
                    ),
                    const SizedBox(width: BeeWiseSpace.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bạn đang ở chế độ xem',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: BeeWiseColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cls.nextSessionSummary?.isNotEmpty == true
                                ? 'Mọi thay đổi lịch hoặc học phí do tư vấn viên xử lý trong nhóm chat. ${cls.nextSessionSummary}'
                                : 'Mọi thay đổi lịch hoặc học phí do tư vấn viên xử lý trong nhóm chat.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1E3A8A),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BeeWiseSpace.x5),

              // Primary CTA: Mở nhóm chat
              BeeWiseButton(
                label: 'Mở nhóm chat',
                icon: Icons.chat_bubble_outline_rounded,
                onPressed: () => context.push(
                  cls.chatId != null && cls.chatId!.isNotEmpty
                      ? '/tutor/chats/${cls.chatId}'
                      : '/tutor/chats',
                ),
              ),
              const SizedBox(height: BeeWiseSpace.x4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required String title,
    bool isDone = false,
    bool isActive = false,
    required int stepNum,
  }) => Expanded(
    child: Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? const Color(0xFF16A34A)
                : (isActive ? BeeWiseColors.primary : const Color(0xFFE2E8F0)),
            shape: BoxShape.circle,
          ),
          child: isDone
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Center(
                  child: Text(
                    '$stepNum',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isDone || isActive
                ? BeeWiseColors.ink
                : const Color(0xFF94A3B8),
          ),
        ),
      ],
    ),
  );

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(BeeWiseRadius.sm),
        ),
        child: Icon(icon, size: 20, color: BeeWiseColors.primary),
      ),
      const SizedBox(width: BeeWiseSpace.x3),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: BeeWiseColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: BeeWiseColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// T6: Lịch dạy (Teaching Schedule matching Figma T6)
/// Uses real calendar week calculation and [tutorScheduleProvider].
class TutorScheduleScreen extends ConsumerStatefulWidget {
  const TutorScheduleScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  ConsumerState<TutorScheduleScreen> createState() =>
      _TutorScheduleScreenState();
}

class _TutorScheduleScreenState extends ConsumerState<TutorScheduleScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final base = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(base.year, base.month, base.day);
  }

  DateTime get _weekMonday =>
      _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));

  List<DateTime> get _weekDays => List.generate(
    7,
    (index) => _weekMonday.add(Duration(days: index)),
    growable: false,
  );

  String _weekdayShort(int weekday) => switch (weekday) {
    DateTime.monday => 'T2',
    DateTime.tuesday => 'T3',
    DateTime.wednesday => 'T4',
    DateTime.thursday => 'T5',
    DateTime.friday => 'T6',
    DateTime.saturday => 'T7',
    DateTime.sunday => 'CN',
    _ => 'T2',
  };

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(tutorScheduleProvider);
    final weekDays = _weekDays;
    final weekStart = weekDays.first;
    final weekEnd = weekDays.last;
    final weekHeader =
        'Tuần ${DateFormat('dd/MM').format(weekStart)} — ${DateFormat('dd/MM').format(weekEnd)}';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Lịch dạy',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới lịch dạy',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(tutorScheduleProvider),
          ),
          IconButton(
            tooltip: 'Tuần trước',
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => setState(
              () => _selectedDate = _selectedDate.subtract(
                const Duration(days: 7),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Tuần sau',
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => setState(
              () => _selectedDate = _selectedDate.add(const Duration(days: 7)),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: BeeWiseColors.border),
        ),
      ),
      body: SafeArea(
        child: scheduleAsync.when(
          skipLoadingOnReload: false,
          skipLoadingOnRefresh: false,
          skipError: false,
          loading: () => const LoadingStateView(),
          error: (error, _) {
            if (error is TutorUnauthorizedException) {
              return Padding(
                padding: const EdgeInsets.all(BeeWiseSpace.x4),
                child: EmptyStateView(
                  title: 'Không có quyền truy cập',
                  message: error.message,
                  icon: Icons.lock_outline_rounded,
                  action: BeeWiseButton(
                    label: 'Kiểm tra trạng thái hồ sơ',
                    onPressed: () => context.go('/tutor/pending'),
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(BeeWiseSpace.x4),
              children: [
                ErrorStateView(
                  message: _tutorFriendlyError(error),
                  onRetry: () => ref.invalidate(tutorScheduleProvider),
                ),
              ],
            );
          },
          data: (allSessions) {
            final weekEndExclusive = weekEnd.add(const Duration(days: 1));
            final weekSessions = allSessions
                .where(
                  (s) =>
                      !s.startTime.isBefore(weekStart) &&
                      s.startTime.isBefore(weekEndExclusive),
                )
                .toList(growable: false);
            final selectedDaySessions = weekSessions
                .where((s) => _isSameDay(s.startTime, _selectedDate))
                .toList(growable: false);
            final visibleSessions = selectedDaySessions.isNotEmpty
                ? selectedDaySessions
                : weekSessions;

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(tutorScheduleProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(BeeWiseSpace.x4),
                children: [
                  Text(
                    weekHeader,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: BeeWiseColors.ink,
                    ),
                  ),
                  const SizedBox(height: BeeWiseSpace.x3),

                  // 7-Day Pill Bar matching Figma T6
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: weekDays
                        .map((day) {
                          final isSelected = _isSameDay(day, _selectedDate);
                          final hasDot = weekSessions.any(
                            (s) => _isSameDay(s.startTime, day),
                          );
                          return InkWell(
                            onTap: () => setState(() => _selectedDate = day),
                            borderRadius: BorderRadius.circular(
                              BeeWiseRadius.full,
                            ),
                            child: Container(
                              width: 44,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? BeeWiseColors.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(
                                  BeeWiseRadius.full,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? BeeWiseColors.primary
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _weekdayShort(day.weekday),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : BeeWiseColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? Colors.white
                                          : BeeWiseColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: hasDot
                                          ? (isSelected
                                                ? Colors.white
                                                : BeeWiseColors.primary)
                                          : Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                  const SizedBox(height: BeeWiseSpace.x5),

                  if (visibleSessions.isEmpty) ...[
                    const EmptyStateView(
                      title: 'Chưa có lịch dạy trong tuần này',
                      message: 'Các buổi học chính thức sau khi phụ huynh hoàn tất thanh toán sẽ hiển thị tại đây.',
                      icon: Icons.event_busy_outlined,
                    ),
                  ] else ...[
                    for (final session in visibleSessions) ...[
                      _buildLessonCard(
                        tileText: session.weekdayTileLabel,
                        timeText: session.timeAndDateLabel,
                        classText: session.subtitleLabel,
                        pillText: session.sessionProgressLabel,
                        isPillGreen: session.confirmed,
                      ),
                      const SizedBox(height: BeeWiseSpace.x3),
                    ],
                  ],
                  const SizedBox(height: BeeWiseSpace.x4),

                  // Bottom Disclaimer Notice
                  Container(
                    padding: const EdgeInsets.all(BeeWiseSpace.x3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: BeeWiseColors.primary,
                        ),
                        SizedBox(width: BeeWiseSpace.x2),
                        Expanded(
                          child: Text(
                            'Lịch hiển thị các buổi học chính thức khi phụ huynh thanh toán qua BeeWise.',
                            style: TextStyle(
                              fontSize: 12,
                              color: BeeWiseColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: BeeWiseSpace.x6),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const TutorBottomNavigation(selectedIndex: 1),
    );
  }

  Widget _buildLessonCard({
    required String tileText,
    required String timeText,
    required String classText,
    required String pillText,
    required bool isPillGreen,
  }) => Card(
    elevation: 0,
    color: BeeWiseColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(BeeWiseRadius.card),
      side: const BorderSide(color: BeeWiseColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(BeeWiseSpace.x4),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BeeWiseColors.primary,
              borderRadius: BorderRadius.circular(BeeWiseRadius.md),
            ),
            alignment: Alignment.center,
            child: Text(
              tileText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: BeeWiseSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: BeeWiseColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  classText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: BeeWiseColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPillGreen
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(BeeWiseRadius.full),
                  ),
                  child: Text(
                    pillText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isPillGreen
                          ? const Color(0xFF15803D)
                          : const Color(0xFF475569),
                    ),
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

/// T7: Hồ sơ của tôi (Tutor Profile Preview matching Figma T7)
/// Driven by [tutorProfileViewProvider] combining `tutorApplications/{uid}` and `tutors/{uid}`.
class TutorSelfProfileScreen extends ConsumerWidget {
  const TutorSelfProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(tutorProfileViewProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Hồ sơ của tôi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới hồ sơ',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(tutorProfileViewProvider),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: BeeWiseColors.border),
        ),
      ),
      body: SafeArea(
        child: profileAsync.when(
          skipLoadingOnReload: false,
          skipLoadingOnRefresh: false,
          skipError: false,
          loading: () => const LoadingStateView(),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(BeeWiseSpace.x4),
            children: [
              ErrorStateView(
                message: _tutorFriendlyError(error),
                onRetry: () => ref.invalidate(tutorProfileViewProvider),
              ),
              const SizedBox(height: BeeWiseSpace.x3),
              BeeWiseButton(
                label: 'Đăng xuất',
                secondary: true,
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) context.go('/home');
                },
              ),
            ],
          ),
          data: (profile) => ListView(
            padding: const EdgeInsets.all(BeeWiseSpace.x4),
            children: [
              // Top Preview Notice Card — distinguishes catalog publication vs approval
              Container(
                padding: const EdgeInsets.all(BeeWiseSpace.x3),
                decoration: BoxDecoration(
                  color: profile.isPublishedInCatalog
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                  border: Border.all(
                    color: profile.isPublishedInCatalog
                        ? const Color(0xFFBFDBFE)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: profile.isPublishedInCatalog
                          ? BeeWiseColors.primary
                          : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: BeeWiseSpace.x2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.isPublishedInCatalog
                                ? 'Đây là hồ sơ phụ huynh nhìn thấy'
                                : 'Hồ sơ đã duyệt — Đang chờ đồng bộ danh mục',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: profile.isPublishedInCatalog
                                  ? BeeWiseColors.primary
                                  : const Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.isPublishedInCatalog
                                ? 'Hồ sơ đã được phê duyệt đang hiển thị trong tìm kiếm.'
                                : 'Hồ sơ đăng ký đã duyệt; bản ghi danh mục công khai (tutors) đang chờ xuất bản.',
                            style: TextStyle(
                              fontSize: 11,
                              color: profile.isPublishedInCatalog
                                  ? const Color(0xFF1E3A8A)
                                  : const Color(0xFF78350F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BeeWiseSpace.x4),

              // Profile Card with Avatar & Verified / Rating Badges
              Card(
                elevation: 0,
                color: BeeWiseColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                  side: const BorderSide(color: BeeWiseColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BeeWiseSpace.x4,
                    vertical: BeeWiseSpace.x5,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFDE047),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          profile.initials,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(height: BeeWiseSpace.x3),
                      Text(
                        profile.displayName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      if (profile.qualificationText != 'Chưa cập nhật') ...[
                        const SizedBox(height: 4),
                        Text(
                          profile.qualificationText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: BeeWiseColors.muted,
                          ),
                        ),
                      ],
                      const SizedBox(height: BeeWiseSpace.x2),

                      // Badges Row
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (profile.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(
                                  BeeWiseRadius.full,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 13,
                                    color: Color(0xFF15803D),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Đã xác thực',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(
                                  BeeWiseRadius.full,
                                ),
                              ),
                              child: const Text(
                                'Chưa xác thực',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          if (profile.ratingText != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(
                                  BeeWiseRadius.full,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile.ratingText!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(
                                  BeeWiseRadius.full,
                                ),
                              ),
                              child: const Text(
                                'Chưa có đánh giá',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: BeeWiseColors.muted,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: BeeWiseSpace.x3),
                      Text(
                        profile.subjectsAndGradesText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: BeeWiseColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: BeeWiseSpace.x4),

              // Information Rows Card
              Card(
                elevation: 0,
                color: BeeWiseColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                  side: const BorderSide(color: BeeWiseColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(BeeWiseSpace.x4),
                  child: Column(
                    children: [
                      _buildProfileRow(
                        icon: Icons.payments_outlined,
                        label: 'HỌC PHÍ',
                        value: profile.hourlyFeeText,
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      _buildProfileRow(
                        icon: Icons.location_on_outlined,
                        label: 'KHU VỰC · HÌNH THỨC',
                        value: profile.areasAndModesText,
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      _buildProfileRow(
                        icon: Icons.calendar_month_outlined,
                        label: 'LỊCH RẢNH',
                        value: profile.availabilityText,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: BeeWiseSpace.x4),

              // Bio Section
              Card(
                elevation: 0,
                color: BeeWiseColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                  side: const BorderSide(color: BeeWiseColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(BeeWiseSpace.x4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giới thiệu',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: BeeWiseSpace.x2),
                      Text(
                        profile.introductionText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF334155),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: BeeWiseSpace.x4),

              // Support Card: Cần sửa hồ sơ?
              Container(
                padding: const EdgeInsets.all(BeeWiseSpace.x4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cần sửa hồ sơ?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF78350F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sau khi duyệt, để tránh làm rối phụ huynh, việc sửa đổi hồ sơ do đội ngũ BeeWise hỗ trợ hoặc đăng ký đợt duyệt mới.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: BeeWiseSpace.x3),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD97706)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            BeeWiseRadius.full,
                          ),
                        ),
                      ),
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Yêu cầu hỗ trợ đã được ghi nhận. BeeWise sẽ liên hệ qua email/SĐT.',
                              ),
                            ),
                          ),
                      child: const Text(
                        'Liên hệ BeeWise',
                        style: TextStyle(
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BeeWiseSpace.x3),

              // Sign Out Button
              Center(
                child: TextButton(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) context.go('/home');
                  },
                  child: const Text(
                    'Đăng xuất',
                    style: TextStyle(
                      color: BeeWiseColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: BeeWiseSpace.x6),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const TutorBottomNavigation(selectedIndex: 3),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(BeeWiseRadius.sm),
        ),
        child: Icon(icon, size: 20, color: BeeWiseColors.primary),
      ),
      const SizedBox(width: BeeWiseSpace.x3),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: BeeWiseColors.muted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: BeeWiseColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// T8: Thông báo gia sư (Tutor Notifications matching Figma T8)
/// Driven by real UID-scoped notifications from [notificationsProvider].
class TutorNotificationScreen extends ConsumerWidget {
  const TutorNotificationScreen({super.key});

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    String uid,
    BeeWiseNotification item,
  ) async {
    try {
      final targetRoute = await ref
          .read(tutorWorkspaceServiceProvider)
          .validateTutorNotificationRoute(
            uid,
            item.route,
            recipientUid: item.recipientUid,
          );
      if (!context.mounted) return;
      if (ref.read(currentAuthenticatedUidProvider) != uid) return;
      if (targetRoute == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể mở liên kết này do dữ liệu không tồn tại hoặc không thuộc quyền truy cập.',
            ),
          ),
        );
        return;
      }
      context.push(targetRoute);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_tutorFriendlyError(error))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentAuthenticatedUidProvider);
    final notificationsAsync = ref.watch(notificationsProvider);
    // Opening this screen counts as reading what is listed, which clears the bell's dot.
    final seenAt = ref.watch(notificationsSeenAtProvider);
    final hasUnseen = (notificationsAsync.asData?.value ?? const []).any(
      (n) => seenAt == null || n.receivedAt.isAfter(seenAt),
    );
    if (hasUnseen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(notificationsSeenAtProvider.notifier).markSeen();
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/tutor/home'),
        ),
        title: const Text(
          'Thông báo',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới thông báo',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(notificationsProvider),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: BeeWiseColors.border),
        ),
      ),
      body: SafeArea(
        child: notificationsAsync.when(
          skipLoadingOnReload: false,
          skipLoadingOnRefresh: false,
          skipError: false,
          loading: () => const LoadingStateView(),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(BeeWiseSpace.x4),
            children: [
              ErrorStateView(
                message: _tutorFriendlyError(error),
                onRetry: () => ref.invalidate(notificationsProvider),
              ),
            ],
          ),
          data: (rawItems) {
            final items = rawItems
                .where(
                  (item) =>
                      uid != null &&
                      (item.recipientUid == null || item.recipientUid == uid),
                )
                .toList(growable: false);

            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(BeeWiseSpace.x4),
                child: EmptyStateView(
                  title: 'Chưa có thông báo mới',
                  message: 'Khi phụ huynh gửi yêu cầu kết nối, xác nhận lịch học thử hoặc hoàn tất thanh toán, thông báo sẽ hiển thị tại đây.',
                  icon: Icons.notifications_none_rounded,
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: BeeWiseSpace.x4,
                vertical: BeeWiseSpace.x3,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: BeeWiseSpace.x2),
              itemBuilder: (context, index) {
                final item = items[index];
                final route = item.route;
                final isPaymentOrApproved =
                    route.contains('schedule') || route.contains('profile');
                return _buildNotificationItem(
                  context,
                  icon: route.contains('chats')
                      ? Icons.chat_bubble_outline_rounded
                      : route.contains('class') || route.contains('schedule')
                      ? Icons.calendar_month_outlined
                      : Icons.notifications_none_rounded,
                  iconBg: isPaymentOrApproved
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFEFF6FF),
                  iconFg: isPaymentOrApproved
                      ? const Color(0xFF15803D)
                      : BeeWiseColors.primary,
                  title: item.labeledTitle,
                  body: item.body,
                  footer: DateFormat('HH:mm · dd/MM').format(item.receivedAt),
                  isUnread: index == 0,
                  onTap: () {
                    if (uid != null) {
                      _openNotification(context, ref, uid, item);
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconFg,
    required String title,
    required String body,
    required String footer,
    required bool isUnread,
    required VoidCallback onTap,
  }) => Card(
    elevation: 0,
    color: BeeWiseColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(BeeWiseRadius.card),
      side: const BorderSide(color: BeeWiseColors.border),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BeeWiseRadius.card),
      child: Padding(
        padding: const EdgeInsets.all(BeeWiseSpace.x4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(BeeWiseRadius.sm),
              ),
              child: Icon(icon, size: 20, color: iconFg),
            ),
            const SizedBox(width: BeeWiseSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                      color: BeeWiseColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    footer,
                    style: const TextStyle(
                      fontSize: 11,
                      color: BeeWiseColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: BeeWiseColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// One-line summary of a consultant proposal, built from the fields the trusted
/// backend really writes (trial: subject/date/time/location; class revision:
/// subject/schedule/time/location). Empty when none of them is present.
String tutorProposalSummaryLine(
  Map<String, dynamic> proposal, {
  required bool isTrial,
}) {
  String? text(String key) {
    final value = proposal[key];
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  final when = isTrial
      ? [text('date'), text('time')].whereType<String>().join(' lúc ')
      : [text('schedule'), text('time')].whereType<String>().join(' · ');
  return [
    text('subject'),
    when.isEmpty ? null : when,
    text('location'),
  ].whereType<String>().join(' · ');
}

/// Parent-response state of a proposal for the tutor's read-only view.
/// `payload.status` is written only by the backend; an unanswered proposal
/// whose `expiresAt` has passed is shown as expired.
({String label, Color background, Color foreground}) tutorProposalStatus(
  Map<String, dynamic> proposal, {
  DateTime? now,
}) {
  const waiting = (
    background: Color(0xFFFEF3C7),
    foreground: Color(0xFF92400E),
  );
  const done = (background: Color(0xFFD1FAE5), foreground: Color(0xFF065F46));
  const neutral = (
    background: Color(0xFFE5E7EB),
    foreground: Color(0xFF374151),
  );
  switch (proposal['status']) {
    case 'accepted':
      return (
        label: 'Phụ huynh đã đồng ý',
        background: done.background,
        foreground: done.foreground,
      );
    case 'confirmed':
      return (
        label: 'Phụ huynh đã xác nhận',
        background: done.background,
        foreground: done.foreground,
      );
    case 'alternate_requested':
      return (
        label: 'Phụ huynh đề xuất giờ khác',
        background: waiting.background,
        foreground: waiting.foreground,
      );
    case 'adjustment_requested':
      return (
        label: 'Phụ huynh yêu cầu điều chỉnh',
        background: waiting.background,
        foreground: waiting.foreground,
      );
    case 'superseded':
      return (
        label: 'Đã có đề xuất mới',
        background: neutral.background,
        foreground: neutral.foreground,
      );
  }
  final expiresAt = proposal['expiresAt'];
  final expiry = expiresAt is Timestamp
      ? expiresAt.toDate()
      : (expiresAt is DateTime ? expiresAt : null);
  if (expiry != null && expiry.isBefore(now ?? DateTime.now())) {
    return (
      label: 'Đề xuất đã hết hạn',
      background: neutral.background,
      foreground: neutral.foreground,
    );
  }
  return (
    label: 'Chờ phụ huynh phản hồi',
    background: waiting.background,
    foreground: waiting.foreground,
  );
}

/// "Tư vấn viên Lan", without doubling the prefix when the stored name already is one
/// (the default consultant name is "Tư vấn viên BeeWise").
String tutorConsultantLabel(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Tư vấn viên BeeWise';
  return trimmed.toLowerCase().startsWith('tư vấn viên')
      ? trimmed
      : 'Tư vấn viên $trimmed';
}
