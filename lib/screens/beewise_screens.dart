import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../models/chat_preview.dart';
import '../models/tutor.dart';
import '../services/tutor_repository.dart';
import '../theme/bee_wise_theme.dart';
import '../viewmodels/app_providers.dart';
import '../viewmodels/controllers.dart';
import '../widgets/bee_wise_widgets.dart';

/// 1.5 -> "1,5 giờ", 2 -> "2 giờ".
String _formatHours(Object? value) {
  if (value is! num) return 'Chưa cập nhật';
  final text = value == value.roundToDouble()
      ? value.round().toString()
      : value.toString().replaceAll('.', ',');
  return '$text giờ';
}

String _formatWorkflowAmount(Object? value) {
  if (value is num) {
    return '${NumberFormat.decimalPattern('vi_VN').format(value)}đ';
  }
  if (value is String) {
    final normalized = value
        .replaceAll(RegExp(r'[^0-9,.-]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final amount = num.tryParse(normalized);
    if (amount != null) {
      return '${NumberFormat.decimalPattern('vi_VN').format(amount)}đ';
    }
    if (value.trim().isNotEmpty) return value.trim();
  }
  return 'Chưa cập nhật';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutors = ref.watch(activeTutorsProvider);
    return BeeWiseScaffold(
      title: 'BeeWise',
      titleWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BeeWiseLogo(height: 28),
          const SizedBox(height: 2),
          Text(
            'Gia sư uy tín cho con',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: BeeWiseColors.muted),
          ),
        ],
      ),
      bottomNavigationIndex: 0,
      actions: [
        IconButton(
          tooltip: 'Thông báo',
          onPressed: () => context.push('/profile'),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(activeTutorsProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Chào bạn 👋',
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: BeeWiseColors.muted),
            ),
            const SizedBox(height: 4),
            Text(
              'Cùng con tìm người đồng hành học tập',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 18),
            InkWell(
              borderRadius: BorderRadius.circular(BeeWiseRadius.field),
              onTap: () => context.push('/search'),
              child: IgnorePointer(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Môn học, lớp hoặc khu vực',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: () => context.push('/search'),
                      icon: const Icon(Icons.tune),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: BeeWiseColors.primary,
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: BeeSticker.wand(size: 88),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 84),
                        Text(
                          'Tìm gia sư phù hợp với nhu cầu của con',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Mô tả mục tiêu học tập để AI gợi ý từ hồ sơ gia sư thật.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: BeeWiseColors.accent,
                            foregroundColor: BeeWiseColors.ink,
                          ),
                          onPressed: () => context.push('/matching'),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Bắt đầu ghép AI'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SectionTitle('Khám phá theo môn học'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final subject in [
                    'Toán',
                    'Tiếng Anh',
                    'Ngữ văn',
                    'Vật lý',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(subject),
                        onPressed: () => context.push(
                          '/search?q=${Uri.encodeQueryComponent(subject)}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SectionTitle(
              'Gia sư đang hoạt động',
              trailing: TextButton(
                onPressed: () => context.push('/search'),
                child: const Text('Xem tất cả'),
              ),
            ),
            tutors.when(
              loading: () => const LoadingTutorList(),
              error: (error, _) => Column(
                children: [
                  if (!ref.watch(firebaseReadyProvider))
                    const FirebaseSetupNotice()
                  else
                    ErrorStateView(
                      message: friendlyError(error),
                      onRetry: () => ref.invalidate(activeTutorsProvider),
                    ),
                  const SizedBox(height: 12),
                  const EmptyStateView(
                    title: 'Danh sách sẽ xuất hiện tại đây',
                    message: 'Kết nối Firebase và thêm hồ sơ gia sư đã được xác minh để bắt đầu khám phá.',
                  ),
                ],
              ),
              data: (items) => items.isEmpty
                  ? const EmptyStateView(
                      title: 'Chưa có gia sư phù hợp',
                      message: 'Hồ sơ gia sư đang hoạt động sẽ xuất hiện ở đây khi được cập nhật từ hệ thống.',
                      icon: Icons.school_outlined,
                      sticker: BeeSticker.cheer(size: 96),
                    )
                  : Column(
                      children: [
                        for (final tutor in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TutorCard(
                              tutor: tutor,
                              onOpen: () => context.push('/tutors/${tutor.id}'),
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
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});
  final String initialQuery;
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _query;
  String? _subject;
  String? _area;
  String? _mode;
  bool _sort = false;
  int? _fee;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final criteria = TutorSearchCriteria(
      query: _query.text,
      subject: _subject,
      area: _area,
      teachingMode: switch (_mode) {
        'Online' => 'online',
        'Trực tiếp' => 'in_person',
        _ => null,
      },
      maxHourlyFee: _fee,
      sortByPrice: _sort,
    );
    final results = ref.watch(tutorSearchProvider(criteria));
    return BeeWiseScaffold(
      title: 'Tìm gia sư',
      showBack: true,
      bottomNavigationIndex: 1,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _query,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) async {
              final resultCount = await ref
                  .read(tutorSearchProvider(criteria).future)
                  .then((items) => items.length, onError: (_) => -1);
              await ref
                  .read(analyticsServiceProvider)
                  .search(
                    queryLength: _query.text.trim().length,
                    filterCount: [
                      _subject,
                      _area,
                      _mode,
                      _fee,
                    ].where((value) => value != null).length,
                    sortMode: _sort ? 'price_ascending' : 'relevance',
                    resultCount: resultCount < 0 ? 0 : resultCount,
                    outcome: resultCount < 0
                        ? 'error'
                        : resultCount == 0
                        ? 'empty'
                        : 'results',
                  );
            },
            decoration: InputDecoration(
              hintText: 'Môn học, lớp, tên hoặc khu vực',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _query.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Bộ lọc',
            icon: Icons.tune_rounded,
            children: [
              FilterGroup(
                label: 'Môn học',
                columns: 2,
                chips: [
                  for (final v in ['Toán', 'Tiếng Anh', 'Ngữ văn', 'Vật lý'])
                    FilterPill(
                      label: v,
                      selected: _subject == v,
                      onTap: () =>
                          setState(() => _subject = _subject == v ? null : v),
                    ),
                ],
              ),
              FilterGroup(
                label: 'Khu vực',
                columns: 3,
                chips: [
                  for (final v in ['Quận 1', 'Quận 3', 'Thủ Đức'])
                    FilterPill(
                      label: v,
                      selected: _area == v,
                      onTap: () =>
                          setState(() => _area = _area == v ? null : v),
                    ),
                ],
              ),
              FilterGroup(
                label: 'Hình thức dạy',
                columns: 2,
                chips: [
                  for (final v in ['Online', 'Trực tiếp'])
                    FilterPill(
                      label: v,
                      selected: _mode == v,
                      onTap: () =>
                          setState(() => _mode = _mode == v ? null : v),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Học phí tối đa',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      Text(
                        _fee == null
                            ? 'Không giới hạn'
                            : '${NumberFormat.decimalPattern('vi_VN').format(_fee)}đ/giờ',
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: BeeWiseColors.primary),
                      ),
                    ],
                  ),
                  Slider(
                    value: (_fee ?? 1000000).toDouble(),
                    min: 100000,
                    max: 1000000,
                    divisions: 9,
                    label: _fee == null
                        ? 'Không giới hạn'
                        : '${NumberFormat.decimalPattern('vi_VN').format(_fee)}đ',
                    onChanged: (value) => setState(() => _fee = value.round()),
                  ),
                  if (_fee != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () => setState(() => _fee = null),
                        child: const Text('Bỏ giới hạn'),
                      ),
                    ),
                  const Divider(height: BeeWiseSpace.x6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Xếp theo học phí thấp',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      Switch(
                        value: _sort,
                        onChanged: (value) => setState(() => _sort = value),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          results.when(
            loading: () => const LoadingTutorList(),
            error: (error, _) => Column(
              children: [
                if (!ref.watch(firebaseReadyProvider))
                  const FirebaseSetupNotice()
                else
                  ErrorStateView(
                    message: friendlyError(error),
                    onRetry: () =>
                        ref.invalidate(tutorSearchProvider(criteria)),
                  ),
              ],
            ),
            data: (items) => items.isEmpty
                ? EmptyStateView(
                    title: 'Chưa tìm thấy gia sư',
                    message:
                        _query.text.isEmpty && _subject == null && _area == null
                        ? 'Khi có hồ sơ gia sư đang hoạt động, danh sách sẽ hiển thị tại đây.'
                        : 'Thử bỏ bớt bộ lọc hoặc đổi từ khóa để tìm rộng hơn.',
                    action: TextButton(
                      onPressed: () {
                        _query.clear();
                        _subject = null;
                        _area = null;
                        _fee = null;
                        setState(() {});
                      },
                      child: const Text('Xóa bộ lọc'),
                    ),
                  )
                : Column(
                    children: [
                      Text(
                        '${items.length} gia sư phù hợp',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      for (final tutor in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TutorCard(
                            tutor: tutor,
                            onOpen: () => context.push('/tutors/${tutor.id}'),
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

class MatchingScreen extends ConsumerStatefulWidget {
  const MatchingScreen({super.key});
  @override
  ConsumerState<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends ConsumerState<MatchingScreen> {
  final _need = TextEditingController();
  @override
  void dispose() {
    _need.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(matchingControllerProvider);
    return BeeWiseScaffold(
      title: 'Ghép gia sư bằng AI',
      showBack: true,
      bottomNavigationIndex: 2,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Điều con đang cần',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Chia sẻ môn học, lớp, mục tiêu, lịch học và hình thức mong muốn. Không nhập thông tin nhận diện cá nhân.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _need,
            maxLength: 500,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Ví dụ: Con học lớp 8, cần củng cố Đại số và luyện giải bài tập, học online buổi tối…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          BeeWiseButton(
            label: 'Tìm gia sư phù hợp',
            icon: Icons.auto_awesome,
            loading: result.isLoading,
            onPressed: result.isLoading
                ? null
                : () {
                    if (_need.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Bạn hãy mô tả nhu cầu học tập trước nhé.',
                          ),
                        ),
                      );
                      return;
                    }
                    ref
                        .read(matchingControllerProvider.notifier)
                        .match(_need.text);
                  },
          ),
          TextButton(
            onPressed: () => context.go('/search'),
            child: const Text('Hoặc tự tìm theo bộ lọc'),
          ),
          if (result.hasError)
            ErrorStateView(
              message: friendlyError(result.error!),
              onRetry: () => ref
                  .read(matchingControllerProvider.notifier)
                  .match(_need.text),
            ),
          if (result.isLoading)
            const LoadingStateView(label: 'Đang so khớp với hồ sơ gia sư…'),
          if (result.hasValue &&
              result.value!.isEmpty &&
              !result.isLoading &&
              _need.text.trim().isNotEmpty)
            const EmptyStateView(
              title: 'Chưa có hồ sơ phù hợp',
              message: 'Không có gia sư nào trong dữ liệu hiện tại khớp với mô tả. Bạn có thể đổi yêu cầu hoặc tự tìm.',
              icon: Icons.auto_awesome_outlined,
              sticker: BeeSticker.robot(size: 140),
            ),
          if (result.hasValue && result.value!.isNotEmpty) ...[
            const SectionTitle('Gợi ý từ hồ sơ đang hoạt động'),
            for (final recommendation in result.value!)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    StatusBanner(message: recommendation.reason),
                    const SizedBox(height: 8),
                    TutorCard(
                      tutor: recommendation.tutor,
                      onOpen: () =>
                          context.push('/tutors/${recommendation.tutor.id}'),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class TutorProfileScreen extends ConsumerWidget {
  const TutorProfileScreen({super.key, required this.tutorId});
  final String tutorId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutor = ref.watch(tutorProvider(tutorId));
    ref.listen(tutorProvider(tutorId), (previous, next) {
      next.whenData(
        (item) => ref
            .read(analyticsServiceProvider)
            .tutorViewed(
              subjectCount: item.subjects.length,
              entrySource: 'profile_route',
            ),
      );
    });
    return BeeWiseScaffold(
      title: 'Hồ sơ gia sư',
      showBack: true,
      body: tutor.when(
        loading: () => const Center(child: LoadingStateView()),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!ref.watch(firebaseReadyProvider))
              const FirebaseSetupNotice()
            else
              ErrorStateView(
                message: friendlyError(error),
                onRetry: () => ref.invalidate(tutorProvider(tutorId)),
              ),
          ],
        ),
        data: (item) => _TutorProfileContent(tutor: item),
      ),
    );
  }
}

class _TutorProfileContent extends ConsumerWidget {
  const _TutorProfileContent({required this.tutor});
  final Tutor tutor;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fee = NumberFormat.decimalPattern('vi_VN').format(tutor.hourlyFee);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TutorAvatar(tutor: tutor, radius: 34),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tutor.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                if (tutor.credential.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(tutor.credential),
                                ],
                                if (tutor.isDemoProfile) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    Tutor.demoDisclosure,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    Tutor.demoDisclaimer,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                                if (tutor.verified) ...[
                                  const SizedBox(height: 8),
                                  const Chip(
                                    avatar: Icon(
                                      Icons.verified,
                                      color: BeeWiseColors.success,
                                      size: 18,
                                    ),
                                    label: Text('Đã xác minh'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final item in [
                            '${tutor.experienceYears} năm kinh nghiệm',
                            '${tutor.subjects.length} môn học',
                            ...tutor.teachingModes.map(teachingModeLabel),
                          ])
                            Chip(label: Text(item)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Giới thiệu',
                icon: Icons.info_outline_rounded,
                children: [
                  Text(
                    tutor.introduction.isEmpty
                        ? 'Gia sư chưa cập nhật phần giới thiệu.'
                        : tutor.introduction,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Chuyên môn và lịch dạy',
                icon: Icons.school_outlined,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final value in tutor.subjects)
                        Chip(label: Text(value)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InfoRow(
                    label: 'Lớp nhận dạy',
                    value: tutor.grades.join(', ').ifEmpty('Chưa cập nhật'),
                    icon: Icons.menu_book_outlined,
                  ),
                  const SizedBox(height: 14),
                  InfoRow(
                    label: 'Lịch có thể dạy',
                    value: tutor.availability.ifEmpty('Chưa cập nhật'),
                    icon: Icons.calendar_month_outlined,
                  ),
                  const SizedBox(height: 14),
                  InfoRow(
                    label: 'Khu vực',
                    value: tutor.areas.join(', ').ifEmpty('Chưa cập nhật'),
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 14),
                  InfoRow(
                    label: 'Học phí tham khảo',
                    value: '$feeđ/giờ',
                    icon: Icons.payments_outlined,
                  ),
                ],
              ),
              if (tutor.rating != null && tutor.reviewCount > 0) ...[
                const SizedBox(height: 20),
                const SectionTitle('Đánh giá'),
                Text(
                  '${tutor.rating!.toStringAsFixed(1)} ★  ·  ${tutor.reviewCount} đánh giá',
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(reportControllerProvider.notifier).generate(tutor),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Xuất hồ sơ PDF'),
              ),
              const _ReportActions(),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BeeWiseButton(
              label: 'Gửi yêu cầu kết nối',
              icon: Icons.chat_bubble_outline,
              onPressed: () => _openConnection(context, ref, tutor.id),
            ),
          ),
        ),
      ],
    );
  }

  void _openConnection(BuildContext context, WidgetRef ref, String id) {
    ref
        .read(authStateProvider)
        .when(
          data: (user) => context.push(
            user == null ? '/login?tutorId=$id' : '/connection/$id',
          ),
          error: (_, _) => context.push('/login?tutorId=$id'),
          loading: () => context.push('/login?tutorId=$id'),
        );
  }
}

extension _NonEmptyString on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.tutorId});
  final String? tutorId;
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && mounted) {
          context.go(
            widget.tutorId == null ? '/home' : '/connection/${widget.tutorId}',
          );
        }
      });
    });
    return BeeWiseScaffold(
      title: 'Đăng nhập',
      showBack: true,
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Center(child: BeeWiseLogo(height: 44)),
            const SizedBox(height: 16),
            Text(
              'Chào mừng trở lại',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Đăng nhập để kết nối với gia sư và theo dõi hành trình học của con.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Nhập email hợp lệ.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: !_showPassword,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              validator: (v) => v == null || v.length < 8
                  ? 'Mật khẩu cần ít nhất 8 ký tự.'
                  : null,
            ),
            const SizedBox(height: 16),
            if (state.hasError)
              ErrorStateView(message: friendlyError(state.error!)),
            BeeWiseButton(
              label: 'Đăng nhập',
              loading: state.isLoading,
              onPressed: state.isLoading
                  ? null
                  : () {
                      if (_form.currentState!.validate()) {
                        ref
                            .read(authControllerProvider.notifier)
                            .emailSignIn(_email.text, _password.text);
                      }
                    },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => ref
                        .read(authControllerProvider.notifier)
                        .googleSignIn(),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: BeeWiseColors.ink,
                side: const BorderSide(color: BeeWiseColors.borderStrong),
              ),
              icon: const GoogleLogo(),
              label: const Text('Tiếp tục với Google'),
            ),
            TextButton(
              onPressed: () => context.push(
                '/register${widget.tutorId == null ? '' : '?tutorId=${widget.tutorId}'}',
              ),
              child: const Text('Chưa có tài khoản? Đăng ký'),
            ),
            TextButton.icon(
              onPressed: () => context.push('/tutor/apply'),
              icon: const Icon(Icons.school_outlined),
              label: const Text('Bạn là gia sư? Gửi hồ sơ đăng ký'),
            ),
            if (!ref.watch(firebaseReadyProvider)) const FirebaseSetupNotice(),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.tutorId});
  final String? tutorId;
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _consent = false;
  bool _showPassword = false;
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    ref.listen(authStateProvider, (_, next) {
      next.whenData((user) {
        if (user != null && mounted) {
          context.go(
            widget.tutorId == null ? '/home' : '/connection/${widget.tutorId}',
          );
        }
      });
    });
    return BeeWiseScaffold(
      title: 'Tạo tài khoản',
      showBack: true,
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Center(child: BeeWiseLogo(height: 44)),
            const SizedBox(height: 16),
            Text(
              'Bắt đầu cùng BeeWise',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'Tạo tài khoản phụ huynh để gửi yêu cầu kết nối và nhận cập nhật.',
            ),
            const SizedBox(height: 4),
            SectionCard(
              title: 'Thông tin phụ huynh',
              icon: Icons.person_outline_rounded,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Họ và tên'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  validator: (v) => v == null || v.trim().length < 9
                      ? 'Nhập số điện thoại hợp lệ.'
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Tài khoản đăng nhập',
              icon: Icons.lock_outline_rounded,
              children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Nhập email hợp lệ.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    helperText: 'Ít nhất 8 ký tự và có một chữ số.',
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.length < 8 || !RegExp(r'\d').hasMatch(v)
                      ? 'Mật khẩu cần ít nhất 8 ký tự và một chữ số.'
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Tôi đồng ý để BeeWise sử dụng thông tin này để hỗ trợ kết nối gia sư.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 12),
            if (state.hasError) ...[
              ErrorStateView(message: friendlyError(state.error!)),
              const SizedBox(height: 12),
            ],
            BeeWiseButton(
              label: 'Tạo tài khoản',
              loading: state.isLoading,
              onPressed: state.isLoading
                  ? null
                  : () {
                      if (!_consent) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Vui lòng xác nhận đồng ý trước khi đăng ký.',
                            ),
                          ),
                        );
                        return;
                      }
                      if (_form.currentState!.validate()) {
                        ref
                            .read(authControllerProvider.notifier)
                            .register(
                              name: _name.text,
                              phone: _phone.text,
                              email: _email.text,
                              password: _password.text,
                            );
                      }
                    },
            ),
            TextButton.icon(
              onPressed: () => context.push('/tutor/apply'),
              icon: const Icon(Icons.school_outlined),
              label: const Text('Bạn là gia sư? Gửi hồ sơ đăng ký'),
            ),
            if (!ref.watch(firebaseReadyProvider)) const FirebaseSetupNotice(),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) => value == null || value.trim().length < 2
      ? 'Vui lòng nhập ít nhất 2 ký tự.'
      : null;
}

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key, required this.tutorId});
  final String tutorId;
  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  final _form = GlobalKey<FormState>();
  final _goal = TextEditingController();
  final _area = TextEditingController();
  final _schedule = TextEditingController();
  final _note = TextEditingController();
  @override
  void dispose() {
    _goal.dispose();
    _area.dispose();
    _schedule.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tutor = ref.watch(tutorProvider(widget.tutorId));
    final user = ref.watch(authStateProvider).asData?.value;
    final state = ref.watch(connectionControllerProvider);
    ref.listen(connectionControllerProvider, (_, next) {
      next.whenData((chatId) {
        if (chatId != null && mounted) context.go('/chats/$chatId');
      });
    });
    return BeeWiseScaffold(
      title: 'Yêu cầu kết nối',
      showBack: true,
      body: user == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: EmptyStateView(
                  title: 'Đăng nhập để gửi yêu cầu',
                  message: 'Sau khi đăng nhập, BeeWise sẽ giữ lại hồ sơ gia sư bạn đã chọn.',
                  icon: Icons.lock_outline,
                  action: FilledButton(
                    onPressed: () =>
                        context.push('/login?tutorId=${widget.tutorId}'),
                    child: const Text('Đăng nhập hoặc đăng ký'),
                  ),
                ),
              ),
            )
          : tutor.when(
              loading: () => const LoadingStateView(),
              error: (e, _) => ListView(
                padding: const EdgeInsets.all(16),
                children: [ErrorStateView(message: friendlyError(e))],
              ),
              data: (item) => Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: withGaps([
                    TutorCard(
                      tutor: item,
                      onOpen: () => context.push('/tutors/${item.id}'),
                    ),
                    SectionCard(
                      title: 'Thông tin học tập',
                      icon: Icons.menu_book_outlined,
                      children: [
                        TextFormField(
                          controller: _goal,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Mục tiêu học tập',
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _area,
                          decoration: const InputDecoration(
                            labelText: 'Khu vực',
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _schedule,
                          decoration: const InputDecoration(
                            labelText: 'Lịch mong muốn',
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _note,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Ghi chú thêm (không bắt buộc)',
                          ),
                        ),
                      ],
                    ),
                    const StatusBanner(
                      message: 'Nhân viên tư vấn sẽ tham gia nhóm sau khi tiếp nhận yêu cầu. Gửi yêu cầu chưa có nghĩa là lịch học đã được xác nhận.',
                    ),
                    if (state.hasError)
                      ErrorStateView(message: friendlyError(state.error!)),
                    const SizedBox(height: 12),
                    BeeWiseButton(
                      label: 'Gửi yêu cầu',
                      loading: state.isLoading,
                      onPressed: state.isLoading
                          ? null
                          : () {
                              if (_form.currentState!.validate()) {
                                ref
                                    .read(connectionControllerProvider.notifier)
                                    .submit(
                                      tutorId: widget.tutorId,
                                      goal: _goal.text,
                                      area: _area.text,
                                      schedule: _schedule.text,
                                      note: _note.text,
                                    );
                              }
                            },
                    ),
                  ]),
                ),
              ),
            ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Vui lòng điền thông tin này.'
      : null;
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chatId});
  final String chatId;
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _composer = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(analyticsServiceProvider).detailViewed('group_chat');
      }
    });
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.chatId));
    final sending = ref.watch(chatComposerControllerProvider);
    return BeeWiseScaffold(
      title: 'Trao đổi cùng BeeWise',
      showBack: true,
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const LoadingStateView(),
              error: (e, _) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!ref.watch(firebaseReadyProvider))
                    const FirebaseSetupNotice()
                  else
                    ErrorStateView(
                      message: friendlyError(e),
                      onRetry: () =>
                          ref.invalidate(chatMessagesProvider(widget.chatId)),
                    ),
                ],
              ),
              data: (items) => items.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: EmptyStateView(
                          title: 'Chưa có tin nhắn',
                          message: 'Tin nhắn từ phụ huynh, gia sư và tư vấn viên sẽ xuất hiện ở đây.',
                          icon: Icons.chat_bubble_outline,
                        ),
                      ),
                    )
                  : ListView(
                      reverse: false,
                      padding: const EdgeInsets.all(16),
                      children: [
                        StatusBanner(
                          message: _onboardingLabel(
                            items.lastWhere(
                              (item) =>
                                  item.role == 'system' ||
                                  item.kind == 'trial_proposal' ||
                                  item.kind == 'class_revision',
                              orElse: () => items.first,
                            ),
                          ),
                        ),
                        const SizedBox(height: _chatGap),
                        for (final message in items)
                          _MessageTile(
                            message: message,
                            chatId: widget.chatId,
                            own: message.role == 'parent',
                          ),
                      ],
                    ),
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: BeeWiseColors.surface,
              border: Border(top: BorderSide(color: BeeWiseColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _composer,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Nhập tin nhắn…',
                          filled: true,
                          fillColor: BeeWiseColors.canvas,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(999),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(999),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(999),
                            ),
                            borderSide: BorderSide(
                              color: BeeWiseColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Gửi tin nhắn',
                      onPressed: sending.isLoading
                          ? null
                          : () async {
                              final text = _composer.text;
                              if (text.trim().isEmpty) return;
                              await ref
                                  .read(chatComposerControllerProvider.notifier)
                                  .send(widget.chatId, text);
                              if (!ref
                                  .read(chatComposerControllerProvider)
                                  .hasError) {
                                _composer.clear();
                              }
                            },
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _onboardingLabel(ChatMessage message) {
  if (message.kind == 'trial_proposal') return 'Có đề xuất buổi học thử';
  if (message.kind == 'class_revision') {
    return 'Có thông tin lớp cần xác nhận';
  }
  if (message.role == 'system' && message.body.trim().isNotEmpty) {
    return message.body;
  }
  return 'Đang trao đổi cùng tư vấn viên BeeWise';
}

/// Banner with a bold coloured title above the message (Figma "Chờ thanh toán",
/// "Buổi học thử đã hoàn tất").
class _TitledBanner extends StatelessWidget {
  const _TitledBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    required this.background,
  });
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(BeeWiseRadius.field),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  );
}

/// One "label … value" line of a fee summary; [emphasize] makes the value the
/// large blue total.
class _FeeLine extends StatelessWidget {
  const _FeeLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            label,
            style:
                (emphasize
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.bodyLarge)
                    ?.copyWith(
                      color: emphasize
                          ? BeeWiseColors.ink
                          : BeeWiseColors.muted,
                      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
                    ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style:
                (emphasize
                        ? theme.textTheme.headlineSmall
                        : theme.textTheme.titleSmall)
                    ?.copyWith(
                      color: emphasize
                          ? BeeWiseColors.primary
                          : BeeWiseColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
          ),
        ),
      ],
    );
  }
}

/// Filled blue pill that labels who initiated a workflow step.
class _ProposalTag extends StatelessWidget {
  const _ProposalTag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: BeeWiseColors.primary,
      borderRadius: BorderRadius.circular(BeeWiseRadius.full),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.groups_2_outlined, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

/// Avatar (initials) + name + caption, as at the top of the Figma detail cards.
class _PersonHeader extends StatelessWidget {
  const _PersonHeader({required this.name, required this.caption});
  final String name;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length < 2
        ? name.characters.take(1).toString().toUpperCase()
        : (parts.first[0] + parts.last[0]).toUpperCase();
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: BeeWiseColors.highlight,
          child: Text(
            initials,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: BeeWiseColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                caption,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: BeeWiseColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bordered info box with a bold blue title (e.g. "Sau buổi học thử").
class _NoteBox extends StatelessWidget {
  const _NoteBox({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF2FF),
      borderRadius: BorderRadius.circular(BeeWiseRadius.field),
      border: Border.all(color: BeeWiseColors.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.info_outline,
            size: 20,
            color: BeeWiseColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: BeeWiseColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Vertical gap between consecutive items in the conversation.
const double _chatGap = 16;

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.chatId,
    required this.own,
  });
  final ChatMessage message;
  final String chatId;
  final bool own;

  @override
  Widget build(BuildContext context) {
    final invoiceId = message.payload['invoiceId'];
    final classId = message.payload['classId'];
    if (message.kind == 'trial_proposal') {
      return _ChatActionCard(
        icon: Icons.event_available_outlined,
        title: 'Đề xuất buổi học thử',
        body: message.body,
        label: 'Xem và phản hồi',
        onPressed: () => context.push('/trial/$chatId/${message.id}'),
      );
    }
    if (message.kind == 'class_revision') {
      return _ChatActionCard(
        icon: Icons.description_outlined,
        title: 'Xác nhận thông tin lớp học',
        body: message.body,
        label: 'Xem thông tin',
        onPressed: () => context.push('/class/$chatId/${message.id}'),
      );
    }
    if (message.kind == 'payment_request' && invoiceId is String) {
      return _ChatActionCard(
        icon: Icons.receipt_long_outlined,
        title: 'Hóa đơn học phí',
        body: message.body,
        label: 'Xem hóa đơn và thanh toán',
        onPressed: () => context.push('/payment/$invoiceId'),
      );
    }
    if (message.role == 'system' && classId is String) {
      return _ChatActionCard(
        icon: Icons.calendar_month_outlined,
        title: 'Lịch học chính thức',
        body: message.body,
        label: 'Xem lịch học chính thức',
        onPressed: () => context.push('/schedule/$classId'),
      );
    }
    if (message.role == 'system') return _ChatSystemNotice(message.body);
    return _ChatBubble(message: message, own: own);
  }
}

/// Card for a step the parent must act on (proposal, class info, invoice,
/// schedule). One style for every kind so they read as a consistent family.
class _ChatActionCard extends StatelessWidget {
  const _ChatActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String title;
  final String body;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: _chatGap),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BeeWiseColors.surface,
          borderRadius: BorderRadius.circular(BeeWiseRadius.card),
          border: Border.all(color: BeeWiseColors.primary, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: BeeWiseColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: BeeWiseColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (body.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(body, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.arrow_forward, size: 20),
                label: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Automatic system message: a full-width, low-key notice instead of a bubble.
class _ChatSystemNotice extends StatelessWidget {
  const _ChatSystemNotice(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: _chatGap),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EDFF),
        borderRadius: BorderRadius.circular(BeeWiseRadius.field),
        border: Border.all(color: BeeWiseColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.verified_user_outlined,
              size: 18,
              color: BeeWiseColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: BeeWiseColors.muted),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.own});
  final ChatMessage message;
  final bool own;

  static String _initials(String name) {
    final list = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (list.isEmpty) return '?';
    if (list.length == 1) return list.first[0].toUpperCase();
    return (list.first[0] + list.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat('HH:mm').format(message.createdAt);
    final maxWidth = MediaQuery.sizeOf(context).width * 0.82;
    final roleLabel = switch (message.role) {
      'parent' => 'Phụ huynh',
      'tutor' => 'Gia sư',
      'consultant' => 'Tư vấn viên',
      _ => 'Thông báo hệ thống',
    };
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: own ? BeeWiseColors.primary : BeeWiseColors.surface,
        borderRadius: BorderRadius.circular(BeeWiseRadius.field),
        border: own ? null : Border.all(color: BeeWiseColors.border),
      ),
      child: Text(
        message.body,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: own ? Colors.white : BeeWiseColors.ink,
        ),
      ),
    );

    if (own) {
      return Padding(
        padding: const EdgeInsets.only(bottom: _chatGap),
        child: Semantics(
          label: 'Bạn, $time',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ExcludeSemantics(
                child: Text(
                  'Bạn  $time',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: BeeWiseColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              bubble,
            ],
          ),
        ),
      );
    }

    final name = message.senderName.isEmpty ? roleLabel : message.senderName;
    final (chipFg, chipBg, chipIcon) = switch (message.role) {
      'tutor' => (
        BeeWiseColors.success,
        BeeWiseColors.successSoft,
        Icons.verified_outlined,
      ),
      'consultant' => (
        Colors.white,
        BeeWiseColors.primary,
        Icons.groups_2_outlined,
      ),
      _ => (BeeWiseColors.muted, BeeWiseColors.canvas, Icons.person_outline),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: _chatGap),
      child: Semantics(
        label: '$name, $roleLabel, $time',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: BeeWiseColors.highlight,
                    child: Text(
                      _initials(name),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: BeeWiseColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: BorderRadius.circular(
                              BeeWiseRadius.full,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(chipIcon, size: 14, color: chipFg),
                              const SizedBox(width: 4),
                              Text(
                                roleLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: chipFg,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          time,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: BeeWiseColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            bubble,
          ],
        ),
      ),
    );
  }
}

/// Why a consultant proposal can no longer be answered, or null while it can.
/// `payload.status` is written only by the trusted backend; [responded] is the
/// local "my answer was saved" state shown until the backend processes it.
({String message, NoticeKind kind})? closedProposalNotice(
  Map<String, dynamic> payload, {
  bool responded = false,
  DateTime? now,
}) {
  final status = payload['status'];
  switch (status) {
    case 'accepted':
      return (
        message: 'Bạn đã đồng ý lịch học thử. Tư vấn viên sẽ gửi thông tin lớp chính thức.',
        kind: NoticeKind.success,
      );
    case 'alternate_requested':
      return (
        message: 'Bạn đã đề xuất thời gian khác. Tư vấn viên sẽ gửi lịch mới trong cuộc trò chuyện.',
        kind: NoticeKind.info,
      );
    case 'confirmed':
      return (
        message: 'Bạn đã xác nhận thông tin lớp. Hóa đơn học phí sẽ xuất hiện trong cuộc trò chuyện.',
        kind: NoticeKind.success,
      );
    case 'adjustment_requested':
      return (
        message:
            'Bạn đã yêu cầu điều chỉnh. Tư vấn viên sẽ gửi thông tin lớp mới.',
        kind: NoticeKind.info,
      );
    case 'superseded':
      return (
        message: 'Đề xuất này đã được thay bằng đề xuất mới. Hãy mở đề xuất mới nhất trong cuộc trò chuyện.',
        kind: NoticeKind.info,
      );
  }
  if (responded) {
    return (
      message: 'Bạn đã phản hồi đề xuất này. Hệ thống đang xử lý.',
      kind: NoticeKind.success,
    );
  }
  if (status != 'pending') {
    return (
      message: 'Đề xuất này không còn chờ phản hồi.',
      kind: NoticeKind.info,
    );
  }
  final expiresAt = payload['expiresAt'];
  final expiry = expiresAt is Timestamp
      ? expiresAt.toDate()
      : expiresAt is DateTime
      ? expiresAt
      : null;
  if (expiry != null && !expiry.isAfter(now ?? DateTime.now())) {
    return (
      message: 'Đề xuất đã hết hạn. Tư vấn viên sẽ gửi đề xuất mới nếu cần.',
      kind: NoticeKind.warning,
    );
  }
  return null;
}

class TrialScreen extends ConsumerStatefulWidget {
  const TrialScreen({
    super.key,
    required this.chatId,
    required this.proposalId,
  });
  final String chatId, proposalId;
  @override
  ConsumerState<TrialScreen> createState() => _TrialScreenState();
}

class _TrialScreenState extends ConsumerState<TrialScreen> {
  final _alternate = TextEditingController();
  bool _responded = false;

  Future<void> _answer({required bool accepted}) async {
    await ref
        .read(workflowControllerProvider.notifier)
        .answerTrial(
          chatId: widget.chatId,
          proposalId: widget.proposalId,
          accepted: accepted,
          alternateTime: accepted ? null : _alternate.text,
        );
    if (mounted && !ref.read(workflowControllerProvider).hasError) {
      setState(() => _responded = true);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(analyticsServiceProvider).detailViewed('trial_proposal');
      }
    });
  }

  @override
  void dispose() {
    _alternate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(consultantMessagesProvider(widget.chatId));
    final state = ref.watch(workflowControllerProvider);
    return BeeWiseScaffold(
      title: 'Buổi học thử',
      showBack: true,
      body: messages.when(
        loading: () => const LoadingStateView(),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [ErrorStateView(message: friendlyError(e))],
        ),
        data: (items) {
          final msg = items
              .where(
                (e) => e.id == widget.proposalId && e.kind == 'trial_proposal',
              )
              .firstOrNull;
          if (msg == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: EmptyStateView(
                  title: 'Chưa có đề xuất',
                  message:
                      'Chỉ tư vấn viên mới có thể gửi đề xuất buổi học thử.',
                ),
              ),
            );
          }
          final p = msg.payload;
          final closed = closedProposalNotice(p, responded: _responded);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: withGaps([
              const OnboardingStepper(currentStep: 0),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: _ProposalTag('Tư vấn viên đề xuất'),
              ),
              Text(
                'Xác nhận buổi học thử',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: BeeWiseColors.primary),
              ),
              const SizedBox(height: 4),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: withGaps([
                      if (p['tutorName'] != null || p['subject'] != null)
                        _PersonHeader(
                          name: '${p['tutorName'] ?? 'Gia sư BeeWise'}',
                          caption: p['subject'] == null
                              ? 'Gia sư'
                              : 'Gia sư ${p['subject']}',
                        ),
                      InfoRow(
                        label: 'Thời gian',
                        value:
                            '${p['date'] ?? 'Chưa cập nhật'} · ${p['time'] ?? 'Chưa cập nhật'}',
                        icon: Icons.schedule,
                      ),
                      InfoRow(
                        label: 'Hình thức',
                        value: '${p['mode'] ?? 'Chưa cập nhật'}',
                        icon: Icons.cast_for_education_outlined,
                      ),
                      InfoRow(
                        label: 'Địa điểm / liên kết',
                        value:
                            '${p['location'] ?? p['meetingLink'] ?? 'Chưa cập nhật'}',
                        icon: Icons.place_outlined,
                      ),
                      InfoRow(
                        label: 'Nội dung',
                        value:
                            '${p['lessonContent'] ?? p['content'] ?? 'Chưa cập nhật'}',
                        icon: Icons.description_outlined,
                      ),
                      InfoRow(
                        label: 'Phí học thử',
                        value: _formatWorkflowAmount(p['fee']),
                        icon: Icons.payments_outlined,
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const _NoteBox(
                title: 'Sau buổi học thử',
                message: 'Tư vấn viên sẽ hỏi ý kiến hai bên. Bạn có thể tiếp tục, trao đổi thêm hoặc dừng lại.',
              ),
              if (closed != null)
                StatusBanner(message: closed.message, kind: closed.kind)
              else ...[
                if (state.hasError)
                  ErrorStateView(message: friendlyError(state.error!)),
                BeeWiseButton(
                  label: 'Đồng ý lịch học thử',
                  icon: Icons.check_circle_outline,
                  loading: state.isLoading,
                  onPressed: () => _answer(accepted: true),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _alternate,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Thời gian khác bạn mong muốn',
                  ),
                ),
                OutlinedButton(
                  onPressed: state.isLoading || _alternate.text.trim().isEmpty
                      ? null
                      : () => _answer(accepted: false),
                  child: const Text('Đề xuất thời gian khác'),
                ),
              ],
            ]),
          );
        },
      ),
    );
  }
}

class ClassRevisionScreen extends ConsumerStatefulWidget {
  const ClassRevisionScreen({
    super.key,
    required this.chatId,
    required this.revisionId,
  });
  final String chatId, revisionId;
  @override
  ConsumerState<ClassRevisionScreen> createState() =>
      _ClassRevisionScreenState();
}

class _ClassRevisionScreenState extends ConsumerState<ClassRevisionScreen> {
  final _reason = TextEditingController();
  bool _responded = false;

  Future<void> _respond(
    Future<void> Function(WorkflowController controller) action,
  ) async {
    await action(ref.read(workflowControllerProvider.notifier));
    if (mounted && !ref.read(workflowControllerProvider).hasError) {
      setState(() => _responded = true);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(analyticsServiceProvider).detailViewed('class_revision');
      }
    });
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(consultantMessagesProvider(widget.chatId));
    final state = ref.watch(workflowControllerProvider);
    return BeeWiseScaffold(
      title: 'Xác nhận lớp học',
      showBack: true,
      body: messages.when(
        loading: () => const LoadingStateView(),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [ErrorStateView(message: friendlyError(e))],
        ),
        data: (items) {
          final msg = items
              .where(
                (e) => e.id == widget.revisionId && e.kind == 'class_revision',
              )
              .firstOrNull;
          if (msg == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: EmptyStateView(
                  title: 'Chưa có thông tin lớp',
                  message: 'Thông tin cần được tư vấn viên gửi trong cuộc trò chuyện.',
                ),
              ),
            );
          }
          final p = msg.payload;
          final closed = closedProposalNotice(p, responded: _responded);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: withGaps([
              const OnboardingStepper(currentStep: 1, completedThrough: 0),
              const SizedBox(height: 8),
              const _TitledBanner(
                icon: Icons.check_circle_outline,
                title: 'Buổi học thử đã hoàn tất',
                message: 'Tư vấn viên đã gửi thông tin lớp chính thức. Kiểm tra trước khi thanh toán.',
                color: BeeWiseColors.success,
                background: BeeWiseColors.successSoft,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: withGaps([
                      Text(
                        '${p['subject'] ?? 'Lớp học'}${p['goal'] == null ? '' : ' – ${p['goal']}'}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      InfoRow(
                        label: 'Gia sư',
                        value: '${p['tutorName'] ?? 'Chưa cập nhật'}',
                        icon: Icons.person_outline,
                      ),
                      InfoRow(
                        label: 'Lịch dự kiến',
                        value:
                            '${p['schedule'] ?? 'Chưa cập nhật'}${p['time'] == null ? '' : ' · ${p['time']}'}',
                        icon: Icons.calendar_today_outlined,
                      ),
                      InfoRow(
                        label: 'Hình thức',
                        value:
                            '${p['mode'] ?? 'Chưa cập nhật'}${p['location'] == null ? '' : ' · ${p['location']}'}',
                        icon: Icons.place_outlined,
                      ),
                      InfoRow(
                        label: 'Bắt đầu',
                        value: '${p['startDate'] ?? 'Chưa cập nhật'}',
                        icon: Icons.schedule,
                      ),
                    ]),
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _FeeLine(
                        label: 'Học phí',
                        value: p['sessions'] == null
                            ? _formatWorkflowAmount(p['fee'])
                            : '${_formatWorkflowAmount(p['fee'])}/giờ',
                      ),
                      const SizedBox(height: 10),
                      _FeeLine(
                        label: 'Thời lượng',
                        value: p['sessions'] == null
                            ? '${p['lessonDuration'] ?? 'Chưa cập nhật'}'
                            : '${_formatHours(p['hoursPerSession'])} × ${p['sessions']} buổi',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: BeeWiseColors.border),
                      ),
                      _FeeLine(
                        label: p['sessions'] == null
                            ? 'Tổng phí'
                            : 'Tổng tháng đầu',
                        value: _formatWorkflowAmount(p['totalFee']),
                        emphasize: true,
                      ),
                    ],
                  ),
                ),
              ),
              const _NoteBox(
                title: 'Lưu ý',
                message: 'Chỉ xác nhận nội dung hiện tại. Yêu cầu thanh toán chỉ xuất hiện sau khi hệ thống nhận xác nhận này và tạo hóa đơn.',
              ),
              if (closed != null)
                StatusBanner(message: closed.message, kind: closed.kind)
              else ...[
                if (state.hasError)
                  ErrorStateView(message: friendlyError(state.error!)),
                BeeWiseButton(
                  label: 'Thông tin đã chính xác',
                  icon: Icons.check_circle_outline,
                  loading: state.isLoading,
                  onPressed: () => _respond(
                    (c) => c.confirmClass(
                      chatId: widget.chatId,
                      revisionId: widget.revisionId,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reason,
                  maxLines: 2,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Nội dung cần điều chỉnh',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: state.isLoading || _reason.text.trim().isEmpty
                      ? null
                      : () => _respond(
                          (c) => c.adjustClass(
                            chatId: widget.chatId,
                            revisionId: widget.revisionId,
                            reason: _reason.text,
                          ),
                        ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Yêu cầu tư vấn viên điều chỉnh'),
                ),
                const TextButton(
                  onPressed: null,
                  child: Text('Không tiếp tục'),
                ),
              ],
            ]),
          );
        },
      ),
    );
  }
}

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.invoiceId});
  final String invoiceId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(analyticsServiceProvider).detailViewed('invoice');
    });
  }

  @override
  Widget build(BuildContext context) {
    final invoiceId = widget.invoiceId;
    final invoices = ref.watch(invoiceQueryProvider(invoiceId));
    final state = ref.watch(workflowControllerProvider);
    return BeeWiseScaffold(
      title: 'Thanh toán học phí',
      showBack: true,
      body: invoices.when(
        loading: () => const LoadingStateView(),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!ref.watch(firebaseReadyProvider))
              const FirebaseSetupNotice()
            else
              ErrorStateView(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(invoiceQueryProvider(invoiceId)),
              ),
          ],
        ),
        data: (snapshot) {
          final doc = snapshot;
          if (!doc.exists || doc.data() == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: EmptyStateView(
                  title: 'Chưa có hóa đơn',
                  message: 'Hóa đơn sẽ chỉ xuất hiện sau khi hệ thống xác nhận các bước trước đó.',
                ),
              ),
            );
          }
          final data = doc.data()!;
          final status = data['status']?.toString() ?? 'pending';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: withGaps([
              status == 'verified'
                  ? const _TitledBanner(
                      icon: Icons.check_circle_outline,
                      title: 'Đã thanh toán',
                      message: 'Thanh toán đã được hệ thống xác minh.',
                      color: BeeWiseColors.success,
                      background: BeeWiseColors.successSoft,
                    )
                  : const _TitledBanner(
                      icon: Icons.warning_amber_rounded,
                      title: 'Chờ thanh toán',
                      message: 'Thanh toán qua payOS để giữ lịch học. Trạng thái tự cập nhật sau khi hệ thống xác minh.',
                      color: BeeWiseColors.warning,
                      background: BeeWiseColors.accentSoft,
                    ),
              const SizedBox(height: 4),
              OnboardingStepper(currentStep: status == 'verified' ? 3 : 2),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: withGaps([
                      Text(
                        'Số tiền cần thanh toán',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(color: BeeWiseColors.muted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatWorkflowAmount(data['amount']),
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(color: BeeWiseColors.primary),
                        textAlign: TextAlign.center,
                      ),
                      if (data['description'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${data['description']}',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thông tin hóa đơn',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: withGaps([
                      InfoRow(
                        label: 'Mã hóa đơn',
                        value: invoiceId,
                        icon: Icons.receipt_long_outlined,
                      ),
                      if (data['dueAt'] != null)
                        InfoRow(
                          label: 'Hạn thanh toán',
                          value: '${data['dueAt']}',
                          icon: Icons.event_outlined,
                        ),
                      InfoRow(
                        label: 'Trạng thái',
                        value: status == 'verified'
                            ? 'Đã xác nhận'
                            : 'Chờ xác nhận',
                        icon: status == 'verified'
                            ? Icons.check_circle_outline
                            : Icons.hourglass_top_rounded,
                      ),
                    ]),
                  ),
                ),
              ),
              if (state.hasError)
                ErrorStateView(message: friendlyError(state.error!)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.verified_user_outlined,
                      size: 20,
                      color: BeeWiseColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Trạng thái chuyển khoản phải được máy chủ hoặc đơn vị thanh toán xác thực. Ứng dụng không tự đánh dấu đã thanh toán.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: BeeWiseColors.muted),
                    ),
                  ),
                ],
              ),
              if (status == 'verified' && data['classId'] != null)
                BeeWiseButton(
                  label: 'Xem lịch học chính thức',
                  onPressed: () => context.push('/schedule/${data['classId']}'),
                ),
              if (status != 'verified') ...[
                BeeWiseButton(
                  label: 'Thanh toán qua payOS',
                  loading: state.isLoading,
                  onPressed: () => ref
                      .read(workflowControllerProvider.notifier)
                      .startPayOsCheckout(invoiceId),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () => ref
                            .read(workflowControllerProvider.notifier)
                            .refreshPaymentStatus(invoiceId),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tôi đã thanh toán · Kiểm tra lại'),
                ),
              ],
            ]),
          );
        },
      ),
    );
  }
}

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key, required this.classId});
  final String classId;

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(analyticsServiceProvider).detailViewed('official_schedule');
      }
    });
  }

  @override
  Widget build(BuildContext context) => BeeWiseScaffold(
    title: 'Lịch học chính thức',
    showBack: true,
    body: ref
        .watch(scheduleProvider(widget.classId))
        .when(
          loading: () => const LoadingStateView(),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [ErrorStateView(message: friendlyError(e))],
          ),
          data: (doc) {
            final d = doc.data();
            if (!doc.exists || d == null || d['paymentStatus'] != 'verified') {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: EmptyStateView(
                    title: 'Lịch chưa được xác nhận',
                    message: 'Lịch chính thức chỉ hiển thị sau khi hệ thống xác minh thanh toán.',
                    icon: Icons.lock_outline,
                  ),
                ),
              );
            }
            final date = d['date']?.toString() ?? 'Chưa cập nhật';
            return ListView(
              padding: const EdgeInsets.all(16),
              children: withGaps([
                const OnboardingStepper(currentStep: 3, completedThrough: 2),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BeeWiseColors.successSoft,
                    borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                  ),
                  child: Row(
                    children: [
                      const BeeSticker.cheer(size: 72),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lớp học đã sẵn sàng!',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Thanh toán đã được xác minh.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: BeeWiseColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: withGaps([
                        Text(
                          '${d['subject'] ?? 'Lớp học'}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        _PersonHeader(
                          name: '${d['tutorName'] ?? 'Chưa cập nhật'}',
                          caption: 'Gia sư',
                        ),
                      ]),
                    ),
                  ),
                ),
                const SectionTitle('Lịch học'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: withGaps([
                        InfoRow(
                          label: 'Thời gian',
                          value: '$date · ${d['time'] ?? ''}',
                          icon: Icons.calendar_today_outlined,
                        ),
                        InfoRow(
                          label: 'Địa điểm',
                          value: '${d['location'] ?? 'Chưa cập nhật'}',
                          icon: Icons.place_outlined,
                        ),
                      ]),
                    ),
                  ),
                ),
              ]),
            );
          },
        ),
  );
}

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => BeeWiseScaffold(
    title: 'Tin nhắn',
    showBack: true,
    bottomNavigationIndex: 3,
    body: ref
        .watch(authStateProvider)
        .when(
          loading: () => const LoadingStateView(),
          error: (_, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: const [FirebaseSetupNotice()],
          ),
          data: (user) {
            if (user == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: EmptyStateView(
                    title: 'Đăng nhập để xem tin nhắn',
                    message: 'Các cuộc trò chuyện với tư vấn viên và gia sư được lưu trong tài khoản của bạn.',
                    icon: Icons.lock_outline,
                    action: FilledButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('Đăng nhập'),
                    ),
                  ),
                ),
              );
            }
            return ref
                .watch(parentChatsProvider(user.uid))
                .when(
                  loading: () => const LoadingStateView(),
                  error: (error, stack) => ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ErrorStateView(
                        message: friendlyError(error),
                        onRetry: () =>
                            ref.invalidate(parentChatsProvider(user.uid)),
                      ),
                    ],
                  ),
                  data: (chats) {
                    if (chats.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: EmptyStateView(
                            title: 'Chưa có cuộc trò chuyện',
                            message: 'Sau khi gửi yêu cầu kết nối, nhóm trao đổi sẽ xuất hiện tại đây.',
                            icon: Icons.chat_bubble_outline,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: chats.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        return _ChatListCard(
                          chat: chat,
                          status: _chatStatus(chat.onboardingStatus),
                          needsAction: _chatNeedsAction(chat.onboardingStatus),
                          onTap: () => context.push('/chats/${chat.id}'),
                        );
                      },
                    );
                  },
                );
          },
        ),
  );

  /// Statuses where the parent is the one who has to act next.
  bool _chatNeedsAction(String status) => const {
    'trial_proposed',
    'class_revision_pending',
    'invoice_issued',
  }.contains(status);

  String _chatStatus(String status) => switch (status) {
    'connection_pending_consultant' => 'Đang chờ tư vấn viên tiếp nhận',
    'consultant_assigned' => 'Tư vấn viên đã tham gia',
    'trial_proposed' => 'Có đề xuất buổi học thử',
    'trial_accepted' => 'Đã đồng ý học thử · Chờ thông tin lớp',
    'trial_reschedule_requested' => 'Chờ tư vấn viên đề xuất giờ mới',
    'class_revision_pending' => 'Chờ điều chỉnh thông tin lớp',
    'class_adjustment_requested' => 'Đang điều chỉnh thông tin lớp',
    'invoice_issued' => 'Có hóa đơn học phí cần thanh toán',
    'schedule_confirmed' => 'Đã có lịch học chính thức',
    _ => 'Nhấn để xem cuộc trò chuyện',
  };
}

/// One conversation in the Messages list: tutor avatar + name, plus the
/// current onboarding step as a status pill.
class _ChatListCard extends ConsumerWidget {
  const _ChatListCard({
    required this.chat,
    required this.status,
    required this.needsAction,
    required this.onTap,
  });
  final ChatPreview chat;
  final String status;
  final bool needsAction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tutor = ref.watch(tutorProvider(chat.tutorId)).asData?.value;
    final (pillFg, pillBg, pillIcon) = needsAction
        ? (
            BeeWiseColors.warning,
            BeeWiseColors.accentSoft,
            Icons.schedule_rounded,
          )
        : (
            BeeWiseColors.primary,
            const Color(0xFFEEF2FF),
            Icons.info_outline_rounded,
          );
    return Material(
      color: BeeWiseColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BeeWiseRadius.card),
        side: const BorderSide(color: BeeWiseColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(BeeWiseRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (tutor != null)
                TutorAvatar(tutor: tutor, radius: 26)
              else
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: BeeWiseColors.highlight,
                  child: Icon(
                    Icons.groups_2_outlined,
                    color: BeeWiseColors.ink,
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tutor?.name ?? 'Nhóm trao đổi cùng BeeWise',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(BeeWiseRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(pillIcon, size: 14, color: pillFg),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              status,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: pillFg,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: BeeWiseColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final authAction = ref.watch(authControllerProvider);
    final notifications = ref.watch(notificationsProvider);
    final remoteConfig = ref.watch(remoteConfigProvider);
    final notificationError = ref
        .watch(notificationServiceProvider)
        .registrationError;
    final firebaseReady = ref.watch(firebaseReadyProvider);

    return BeeWiseScaffold(
      title: 'Tài khoản',
      bottomNavigationIndex: 4,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: withGaps([
          if (authAction.hasError)
            ErrorStateView(message: friendlyError(authAction.error!)),
          auth.when(
            loading: () => const LoadingStateView(),
            error: (error, stack) =>
                ErrorStateView(message: friendlyError(error)),
            data: (user) {
              if (user == null) {
                return SectionCard(
                  title: 'Chưa đăng nhập',
                  icon: Icons.person_outline_rounded,
                  subtitle: 'Đăng nhập để quản lý tài khoản.',
                  children: [
                    BeeWiseButton(
                      label: 'Đăng nhập',
                      onPressed: () => context.push('/login'),
                    ),
                  ],
                );
              }
              final display = user.displayName?.trim().isNotEmpty == true
                  ? user.displayName!.trim()
                  : user.email?.trim().isNotEmpty == true
                  ? user.email!.trim()
                  : 'BeeWise';
              return SectionCard(
                title: user.displayName?.trim().isNotEmpty == true
                    ? user.displayName!.trim()
                    : 'Phụ huynh',
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFEEF2FF),
                  foregroundColor: BeeWiseColors.primary,
                  child: Text(
                    display.characters.first.toUpperCase(),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: BeeWiseColors.primary),
                  ),
                ),
                trailing: IconButton(
                  tooltip: 'Đăng xuất',
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout_rounded),
                ),
                children: [
                  if ((user.email ?? '').isNotEmpty)
                    Text(
                      user.email!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              );
            },
          ),
          SectionCard(
            title: 'Thông báo',
            icon: Icons.notifications_none_rounded,
            children: [
              if (notificationError != null) ...[
                ErrorStateView(message: notificationError),
                TextButton(
                  onPressed: () =>
                      ref.read(notificationServiceProvider).retryRegistration(),
                  child: const Text('Thử lại đăng ký thông báo'),
                ),
              ],
              notifications.when(
                loading: () => const LoadingStateView(),
                error: (error, stack) =>
                    ErrorStateView(message: friendlyError(error)),
                data: (items) => items.isEmpty
                    ? const Text('Chưa có thông báo mới.')
                    : Column(
                        children: [
                          for (final item in items.take(8))
                            ListTile(
                              leading: const Icon(Icons.notifications_none),
                              title: Text(item.title),
                              subtitle: Text(item.body),
                              onTap: () async {
                                final route = await ref
                                    .read(notificationServiceProvider)
                                    .routeForNotification(item);
                                if (context.mounted && route != null) {
                                  context.go(route);
                                }
                              },
                            ),
                        ],
                      ),
              ),
            ],
          ),
          SectionCard(
            title: 'Dịch vụ ứng dụng',
            icon: Icons.tune_rounded,
            children: [
              InfoRow(
                label: 'Remote Config',
                value:
                    'Ghép AI: ${remoteConfig.matchingEnabled ? 'đang bật' : 'đang tắt'} · tối đa ${remoteConfig.aiResultLimit} kết quả',
                icon: Icons.cloud_done_outlined,
              ),
            ],
          ),
          SectionCard(
            title: 'Báo cáo PDF riêng',
            icon: Icons.picture_as_pdf_outlined,
            children: [const _ReportActions()],
          ),
          SectionCard(
            title: 'Chẩn đoán lỗi',
            icon: Icons.bug_report_outlined,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(crashReportingServiceProvider)
                          .recordHandled(
                            StateError('BeeWise non-fatal diagnostic sample'),
                            StackTrace.current,
                            'Profile diagnostic button',
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đã gửi lỗi mẫu không nghiêm trọng tới Crashlytics.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.bug_report_outlined),
                    label: const Text('Gửi lỗi mẫu'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ghi nhận một lỗi không nghiêm trọng',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: BeeWiseColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              // Deliberate fatal crash is a demo-only control: it is compiled out
              // of release builds so it cannot be triggered during normal use.
              if (kDebugMode)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => ref
                          .read(crashReportingServiceProvider)
                          .triggerTestCrash(),
                      icon: const Icon(Icons.warning_amber),
                      label: const Text('Kiểm tra Crashlytics'),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sẽ đóng ứng dụng (chỉ có ở bản debug)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: BeeWiseColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
            ],
          ),
          if (!firebaseReady) const FirebaseSetupNotice(),
        ], gap: BeeWiseSpace.x3),
      ),
    );
  }
}

class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => BeeWiseScaffold(
    title: 'Không mở được trang',
    showBack: true,
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: ErrorStateView(
        message: message,
        onRetry: () => context.go('/home'),
      ),
    ),
  );
}

// Minimum PDF integration shared by the tutor detail and existing Profile area.
// Layout/theme/router ownership remains with Nguyen.
class _ReportActions extends ConsumerWidget {
  const _ReportActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportControllerProvider);
    final controller = ref.read(reportControllerProvider.notifier);
    final label = switch (report.stage) {
      ReportStage.idle => 'Xuất PDF từ hồ sơ gia sư. Lưu riêng trong Firestore sau khi đăng nhập.',
      ReportStage.generating => 'Đang tạo PDF…',
      ReportStage.generated => 'PDF đã tạo trên máy. Chưa lưu cloud.',
      ReportStage.encoding => 'Đang kiểm tra và mã hóa PDF…',
      ReportStage.saving => 'Đang chờ Firestore server xác nhận…',
      ReportStage.saved => 'Đã lưu PDF và đọc lại từ server.',
      ReportStage.downloading => 'Đang tải PDF từ server…',
      ReportStage.downloaded => 'Đã tải PDF từ server về máy.',
      ReportStage.error => 'Thao tác chưa hoàn tất. Có thể thử lại.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        if (report.isBusy) ...[
          const LinearProgressIndicator(),
          TextButton(
            onPressed: controller.reset,
            child: const Text('Hủy thao tác'),
          ),
        ],
        if (report.error != null) ErrorStateView(message: report.error!),
        if (report.result != null)
          SelectableText('Firestore: ${report.result!.documentPath}'),
        if (!report.isBusy && report.localPath != null && report.result == null)
          TextButton.icon(
            onPressed: controller.save,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Lưu cloud riêng'),
          ),
        if (!report.isBusy && report.result != null)
          TextButton.icon(
            onPressed: controller.download,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Tải lại từ server'),
          ),
        if (!report.isBusy && report.localPath != null)
          TextButton.icon(
            onPressed: controller.share,
            icon: const Icon(Icons.share_outlined),
            label: const Text('Mở / chia sẻ PDF'),
          ),
      ],
    );
  }
}
