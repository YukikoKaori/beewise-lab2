import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../theme/bee_wise_theme.dart';
import '../viewmodels/app_providers.dart';
import '../viewmodels/controllers.dart';
import '../widgets/bee_wise_widgets.dart';

/// 4-tab Bottom Navigation for Tutor experience matching Figma T3, T6, T7
class TutorBottomNavigation extends StatelessWidget {
  const TutorBottomNavigation({super.key, required this.selectedIndex});

  final int selectedIndex;

  static const _routes = [
    '/tutor/home',
    '/tutor/schedule',
    '/tutor/chats/chat_lan_trang',
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
/// Features both Active ("Việc cần làm hôm nay") and Empty ("Chưa có việc cần làm") states
class TutorHomeScreen extends ConsumerStatefulWidget {
  const TutorHomeScreen({super.key, this.forceEmptyState = false});

  final bool forceEmptyState;

  @override
  ConsumerState<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends ConsumerState<TutorHomeScreen> {
  late bool _isEmptyState;

  @override
  void initState() {
    super.initState();
    _isEmptyState = widget.forceEmptyState;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).asData?.value;
    final appData = user != null
        ? ref.watch(tutorApplicationDataProvider(user.uid)).asData?.value
        : null;

    final tutorName = appData?.name.isNotEmpty == true
        ? appData!.name
        : (user?.displayName?.isNotEmpty == true
              ? user!.displayName!
              : 'ThS. Hoàng Thu Trang');

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
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                tooltip: 'Thông báo',
                icon: const Icon(Icons.notifications_none_rounded, size: 26),
                onPressed: () => context.push('/tutor/notifications'),
              ),
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
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: BeeWiseSpace.x4,
            vertical: BeeWiseSpace.x4,
          ),
          children: [
            // Greeting & Headline
            Text(
              'Chào ${tutorName.contains(' ') ? tutorName.split(' ').last : tutorName},',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: BeeWiseColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _isEmptyState ? 'Chưa có việc cần làm' : 'Việc cần làm hôm nay',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: BeeWiseColors.primary,
              ),
            ),
            const SizedBox(height: BeeWiseSpace.x4),

            if (_isEmptyState) ...[
              // EMPTY STATE CARD matching Figma
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

              // Notice Banner
              Container(
                padding: const EdgeInsets.all(BeeWiseSpace.x4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
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
              // ACTIVE STATE SECTIONS matching Figma T3
              // Section 1: Nhóm chat mới
              Text(
                'Nhóm chat mới',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: BeeWiseSpace.x2),
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
                            child: const Text(
                              'LN',
                              style: TextStyle(
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
                              children: const [
                                Text(
                                  'Chị Lan · Toán 9 Ôn thi vào 10',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: BeeWiseColors.ink,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Vừa kết nối từ Ba Đình, Cầu Giấy · Tại nhà',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: BeeWiseColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                      const Text(
                        'Tư vấn viên Hoàng Yến đã vào nhóm và có đề xuất buổi học thử.',
                        style: TextStyle(
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
                            context.push('/tutor/chats/chat_lan_trang'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: BeeWiseSpace.x5),

              // Section 2: Buổi học sắp tới
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
              Card(
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
                        child: const Text(
                          'T3',
                          style: TextStyle(
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
                            const Text(
                              '19:30 - 21:30 · Thứ ba 19/11',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: BeeWiseColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Chị Lan · Toán 9 · Tại nhà Cầu Giấy',
                              style: TextStyle(
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
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(
                                  BeeWiseRadius.full,
                                ),
                              ),
                              child: const Text(
                                'Buổi 1/10 · Đã xác nhận',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF15803D),
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
              const SizedBox(height: BeeWiseSpace.x5),

              // Section 3: Lớp đang dạy
              Text(
                'Lớp đang dạy',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: BeeWiseSpace.x2),
              Card(
                elevation: 0,
                color: BeeWiseColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                  side: const BorderSide(color: BeeWiseColors.border),
                ),
                child: InkWell(
                  onTap: () => context.push('/tutor/class/class_toan9_lan'),
                  borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                  child: Padding(
                    padding: const EdgeInsets.all(BeeWiseSpace.x4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Toán 9 — Ôn thi vào 10',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: BeeWiseColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Chị Lan · T3 & T6 · 19:30 - 21:30',
                                style: TextStyle(
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
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(
                                    BeeWiseRadius.full,
                                  ),
                                ),
                                child: const Text(
                                  'Phụ huynh đã thanh toán',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF15803D),
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
            ],
            const SizedBox(height: BeeWiseSpace.x6),
          ],
        ),
      ),
      bottomNavigationBar: const TutorBottomNavigation(selectedIndex: 0),
    );
  }
}

/// T4: Nhóm chat gia sư (Tutor Group Chat matching Figma T4)
class TutorChatScreen extends StatefulWidget {
  const TutorChatScreen({super.key, required this.chatId});

  final String chatId;

  @override
  State<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends State<TutorChatScreen> {
  final _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isMe': false,
      'sender': 'Chị Lan',
      'role': 'PHỤ HUYNH',
      'time': '10:20',
      'avatar': 'LN',
      'avatarBg': const Color(0xFFFDE047),
      'text': 'Chào cô Trang, con em lớp 9 cần phụ đạo môn Hóa học, cô sắp xếp được Cầu Giấy ạ.',
    },
    {
      'isMe': true,
      'time': '10:24',
      'text': 'Chào chị Lan. T3, T5 tuần tới 19:30 em qua nhà. Em trao đổi cụ thể hơn ạ.',
    },
    {
      'isMe': false,
      'sender': 'Hoàng Yến',
      'role': 'TƯ VẤN VIÊN',
      'time': '10:26',
      'avatar': 'HY',
      'avatarBg': const Color(0xFFF59E0B),
      'text': 'Em đã gửi đề xuất học thử theo giờ cô Trang đưa ra, chị Lan xem giúp em nhé.',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({
        'isMe': true,
        'time': DateFormat('HH:mm').format(DateTime.now()),
        'text': text,
      });
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/tutor/home'),
      ),
      title: const Text(
        'Nhóm: Chị Lan & Cô Tra...',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
        child: Divider(height: 1, thickness: 1, color: BeeWiseColors.border),
      ),
    ),
    body: SafeArea(
      child: Column(
        children: [
          // Group Header Banner matching Figma
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    children: const [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFFFDE047),
                        child: Text(
                          'LN',
                          style: TextStyle(
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
                          backgroundColor: Color(0xFFF59E0B),
                          child: Text(
                            'HY',
                            style: TextStyle(
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
                      const Text(
                        'Phụ huynh Chị Lan · Tư vấn viên Hoàng Yến',
                        style: TextStyle(
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
                        child: const Text(
                          'Chờ phụ huynh xác nhận học thử',
                          style: TextStyle(
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

          // Timestamp notice
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Chị Lan đã kết nối · Nhóm chat được tạo lúc 10:15',
              style: TextStyle(fontSize: 11, color: BeeWiseColors.muted),
            ),
          ),

          // Chat Message Stream
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                ..._messages.map((m) {
                  final isMe = m['isMe'] == true;
                  if (isMe) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Đã gửi · ${m['time']}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: BeeWiseColors.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: BeeWiseColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              m['text'] as String,
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

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: m['avatarBg'] as Color,
                          child: Text(
                            m['avatar'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    m['sender'] as String,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: m['role'] == 'TƯ VẤN VIÊN'
                                          ? const Color(0xFF1E40AF)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      m['role'] as String,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: m['role'] == 'TƯ VẤN VIÊN'
                                            ? Colors.white
                                            : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    m['time'] as String,
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
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: BeeWiseColors.border,
                                  ),
                                ),
                                child: Text(
                                  m['text'] as String,
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
                }),

                // Trial Proposal Card matching Figma
                Container(
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
                        children: const [
                          Icon(
                            Icons.bookmark_border_rounded,
                            color: BeeWiseColors.primary,
                            size: 20,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Đề xuất buổi học thử',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: BeeWiseColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '19:30 - 21:00 · Thứ ba 12/11 · Tại nhà Cầu Giấy',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: BeeWiseColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(
                            BeeWiseRadius.full,
                          ),
                        ),
                        child: const Text(
                          'Chờ phụ huynh phản hồi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
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
                      const SizedBox(height: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(42),
                          side: const BorderSide(color: BeeWiseColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              BeeWiseRadius.full,
                            ),
                          ),
                        ),
                        onPressed: () =>
                            context.push('/tutor/class/class_toan9_lan'),
                        child: const Text(
                          'Xem chi tiết',
                          style: TextStyle(
                            color: BeeWiseColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Composer Dock matching Figma
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: BeeWiseColors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: BeeWiseColors.muted,
                  ),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(BeeWiseRadius.full),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(BeeWiseRadius.full),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: BeeWiseColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _sendMessage,
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

/// T5: Quản lý lớp học (Class Detail matching Figma T5)
class TutorClassDetailScreen extends StatelessWidget {
  const TutorClassDetailScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/tutor/home'),
      ),
      title: const Text(
        'Lớp: Toán 9 — Chị Lan',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: BeeWiseColors.border),
      ),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(BeeWiseSpace.x4),
        children: [
          // 4-Step Stepper matching Figma
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStepItem(title: 'HỌC THỬ', isDone: true, stepNum: 1),
              _buildStepItem(title: 'XÁC NHẬN LỚP', isDone: true, stepNum: 2),
              _buildStepItem(title: 'THANH TOÁN', isDone: true, stepNum: 3),
              _buildStepItem(title: 'LỊCH HỌC', isActive: true, stepNum: 4),
            ],
          ),
          const SizedBox(height: BeeWiseSpace.x4),

          // Verified Payment Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(BeeWiseRadius.full),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: Color(0xFF15803D),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chị Lan đã thanh toán cho 10 buổi học chính thức',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BeeWiseSpace.x3),

          // Title
          Text(
            'Toán 9 — Ôn thi vào 10',
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
                  // Parent Header
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
                        child: const Text(
                          'LN',
                          style: TextStyle(
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
                          children: const [
                            Text(
                              'Chị Lan (Phụ huynh)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: BeeWiseColors.ink,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Học sinh: Mỹ An · Học lực: Khá môn Toán',
                              style: TextStyle(
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
                    icon: Icons.access_time_rounded,
                    title: 'Buổi học thử',
                    value: '19:30 Thứ ba 12/11 · Đã diễn ra',
                  ),
                  const SizedBox(height: BeeWiseSpace.x3),
                  _buildDetailRow(
                    icon: Icons.calendar_month_outlined,
                    title: 'Lịch chính thức',
                    value: 'Thứ Ba & Thứ Sáu · 19:30 - 21:30',
                  ),
                  const SizedBox(height: BeeWiseSpace.x3),
                  _buildDetailRow(
                    icon: Icons.location_on_outlined,
                    title: 'Địa điểm',
                    value: 'Tại nhà · Cầu Giấy, Hà Nội',
                  ),
                  const SizedBox(height: BeeWiseSpace.x3),
                  _buildDetailRow(
                    icon: Icons.payments_outlined,
                    title: 'Học phí khóa',
                    value: '250.000đ/giờ · 2 giờ · 8 buổi = 4.000.000đ',
                  ),
                  const SizedBox(height: BeeWiseSpace.x3),
                  _buildDetailRow(
                    icon: Icons.person_outline_rounded,
                    title: 'Tư vấn viên phụ trách',
                    value: 'Hoàng Yến',
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
              children: const [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: BeeWiseColors.primary,
                ),
                SizedBox(width: BeeWiseSpace.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bạn đang ở chế độ xem',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: BeeWiseColors.primary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Mọi thay đổi lịch hoặc học phí do tư vấn viên xử lý trong nhóm chat. Buổi tiếp theo: dạy buổi đầu tiên 19/11 tại nhà.',
                        style: TextStyle(
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
            onPressed: () => context.push('/tutor/chats/chat_lan_trang'),
          ),
          const SizedBox(height: BeeWiseSpace.x4),
        ],
      ),
    ),
  );

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
class TutorScheduleScreen extends StatefulWidget {
  const TutorScheduleScreen({super.key});

  @override
  State<TutorScheduleScreen> createState() => _TutorScheduleScreenState();
}

class _TutorScheduleScreenState extends State<TutorScheduleScreen> {
  int _selectedDay = 19; // Tuesday 19th

  final _days = [
    {'day': 'T2', 'date': 18, 'hasDot': false},
    {'day': 'T3', 'date': 19, 'hasDot': true},
    {'day': 'T4', 'date': 20, 'hasDot': false},
    {'day': 'T5', 'date': 21, 'hasDot': false},
    {'day': 'T6', 'date': 22, 'hasDot': true},
    {'day': 'T7', 'date': 23, 'hasDot': false},
    {'day': 'CN', 'date': 24, 'hasDot': false},
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text(
        'Lịch dạy',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: BeeWiseColors.border),
      ),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(BeeWiseSpace.x4),
        children: [
          // Week Subheader
          Text(
            'Tuần 18/11 — 24/11',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: BeeWiseColors.ink,
            ),
          ),
          const SizedBox(height: BeeWiseSpace.x3),

          // 7-Day Pill Bar matching Figma
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _days
                .map((d) {
                  final isSelected = d['date'] == _selectedDay;
                  return InkWell(
                    onTap: () =>
                        setState(() => _selectedDay = d['date'] as int),
                    borderRadius: BorderRadius.circular(BeeWiseRadius.full),
                    child: Container(
                      width: 44,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? BeeWiseColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(BeeWiseRadius.full),
                        border: Border.all(
                          color: isSelected
                              ? BeeWiseColors.primary
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            d['day'] as String,
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
                            '${d['date']}',
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
                              color: d['hasDot'] == true
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

          // Lesson Session Cards matching Figma
          _buildLessonCard(
            tileText: 'T3',
            timeText: '19:30 - 21:30 · Thứ ba 19/11',
            classText: 'Chị Lan · Toán 9 · Tại nhà Cầu Giấy',
            pillText: 'Buổi 1/10',
            isPillGreen: true,
          ),
          const SizedBox(height: BeeWiseSpace.x3),
          _buildLessonCard(
            tileText: 'T6',
            timeText: '19:30 - 21:30 · Thứ sáu 22/11',
            classText: 'Chị Lan · Toán 9 · Tại nhà Cầu Giấy',
            pillText: 'Buổi 2/10',
            isPillGreen: false,
          ),
          const SizedBox(height: BeeWiseSpace.x3),
          _buildLessonCard(
            tileText: 'T3',
            timeText: '19:30 - 21:30 · Thứ ba 26/11',
            classText: 'Chị Lan · Toán 9 · Tại nhà Cầu Giấy',
            pillText: 'Buổi 3/10',
            isPillGreen: false,
          ),
          const SizedBox(height: BeeWiseSpace.x5),

          // Bottom Disclaimer Notice
          Container(
            padding: const EdgeInsets.all(BeeWiseSpace.x3),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(BeeWiseRadius.card),
            ),
            child: Row(
              children: const [
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
    ),
    bottomNavigationBar: const TutorBottomNavigation(selectedIndex: 1),
  );

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
class TutorSelfProfileScreen extends ConsumerWidget {
  const TutorSelfProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    final appData = user != null
        ? ref.watch(tutorApplicationDataProvider(user.uid)).asData?.value
        : null;

    final name = appData?.name.isNotEmpty == true
        ? appData!.name
        : (user?.displayName?.isNotEmpty == true
              ? user!.displayName!
              : 'ThS. Hoàng Thu Trang');

    final feeText = appData != null && appData.hourlyFee > 0
        ? '${NumberFormat.decimalPattern('vi_VN').format(appData.hourlyFee)} đ/giờ'
        : '250.000 đ/giờ';

    final areasAndModes = [
      if (appData?.areas.isNotEmpty == true)
        appData!.areas.join(', ')
      else
        'Cầu Giấy, Đống Đa',
      if (appData?.teachingModes.isNotEmpty == true)
        appData!.teachingModes.join(', ')
      else
        'Trực tiếp, Trực tuyến',
    ].join(' · ');

    final availability = appData?.availability.isNotEmpty == true
        ? appData!.availability
        : 'Tối T3, T5, T7';

    final subjectsAndGrades = [
      if (appData?.subjects.isNotEmpty == true)
        appData!.subjects.join(', ')
      else
        'Toán, Hóa học',
      if (appData?.grades.isNotEmpty == true)
        appData!.grades.join(', ')
      else
        'Lớp 9, Ôn thi vào 10',
    ].join(' · ');

    final intro = appData?.introduction.isNotEmpty == true
        ? appData!.introduction
        : 'Dạy Toán THCS và ôn thi vào 10 trường chuyên. Tập trung lấy lại gốc phương pháp giải dễ hiểu; báo tiến độ hàng tuần cho phụ huynh.';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Hồ sơ của tôi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: BeeWiseColors.border),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(BeeWiseSpace.x4),
          children: [
            // Top Preview Notice Card
            Container(
              padding: const EdgeInsets.all(BeeWiseSpace.x3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: BeeWiseColors.primary,
                  ),
                  SizedBox(width: BeeWiseSpace.x2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đây là hồ sơ phụ huynh nhìn thấy',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: BeeWiseColors.primary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Hồ sơ đã được phê duyệt đang hiển thị trong tìm kiếm.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BeeWiseSpace.x4),

            // Profile Card with Avatar & Verified Badge
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
                        name.contains(' ')
                            ? name.split(' ').map((p) => p[0]).take(2).join()
                            : 'TT',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(height: BeeWiseSpace.x3),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: BeeWiseSpace.x2),

                    // Badges Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
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
                        ),
                        const SizedBox(width: 8),
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
                            children: const [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Color(0xFFD97706),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '4.9 (24)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: BeeWiseSpace.x3),
                    Text(
                      subjectsAndGrades,
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
                      value: feeText,
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    _buildProfileRow(
                      icon: Icons.location_on_outlined,
                      label: 'KHU VỰC · HÌNH THỨC',
                      value: areasAndModes,
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    _buildProfileRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'LỊCH RẢNH',
                      value: availability,
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
                      intro,
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
                        borderRadius: BorderRadius.circular(BeeWiseRadius.full),
                      ),
                    ),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
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
class TutorNotificationScreen extends StatelessWidget {
  const TutorNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
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
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: BeeWiseColors.border),
      ),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: BeeWiseSpace.x4,
          vertical: BeeWiseSpace.x3,
        ),
        children: [
          _buildNotificationItem(
            context,
            icon: Icons.chat_bubble_outline_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconFg: BeeWiseColors.primary,
            title: 'Nhóm chat mới với chị Lan',
            body: 'Phụ huynh vừa kết nối. Tư vấn viên Hoàng Yến đã vào nhóm.',
            footer: '10:20 · Bấm để xem · Đề xuất đã được gửi',
            isUnread: true,
            onTap: () => context.push('/tutor/chats/chat_lan_trang'),
          ),
          const SizedBox(height: BeeWiseSpace.x2),
          _buildNotificationItem(
            context,
            icon: Icons.calendar_month_outlined,
            iconBg: const Color(0xFFEFF6FF),
            iconFg: BeeWiseColors.primary,
            title: 'Chị Lan đồng ý lịch học thử',
            body: '19:30 Thứ ba 12/11 tại nhà Cầu Giấy.',
            footer: 'Hôm qua · Xem chi tiết buổi học thử',
            isUnread: true,
            onTap: () => context.push('/tutor/class/class_toan9_lan'),
          ),
          const SizedBox(height: BeeWiseSpace.x2),
          _buildNotificationItem(
            context,
            icon: Icons.payments_outlined,
            iconBg: const Color(0xFFDCFCE7),
            iconFg: const Color(0xFF15803D),
            title: 'Phụ huynh đã thanh toán · Có lớp dạy chính thức',
            body: '8 buổi Toán 9, bắt đầu Thứ Ba 19/11.',
            footer: '12/11 · Đã xong',
            isUnread: false,
            onTap: () => context.go('/tutor/schedule'),
          ),
          const SizedBox(height: BeeWiseSpace.x2),
          _buildNotificationItem(
            context,
            icon: Icons.verified_user_outlined,
            iconBg: const Color(0xFFDCFCE7),
            iconFg: const Color(0xFF15803D),
            title: 'Hồ sơ của bạn đã được duyệt',
            body: 'Hồ sơ đang hiển thị trong tìm kiếm cho phụ huynh',
            footer: '07/11 · Đã xong',
            isUnread: false,
            onTap: () => context.go('/tutor/profile'),
          ),
        ],
      ),
    ),
  );

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
