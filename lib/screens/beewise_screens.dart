import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../models/tutor.dart';
import '../services/tutor_repository.dart';
import '../theme/bee_wise_theme.dart';
import '../viewmodels/app_providers.dart';
import '../viewmodels/controllers.dart';
import '../widgets/bee_wise_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutors = ref.watch(activeTutorsProvider);
    return BeeWiseScaffold(
      title: 'BeeWise',
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
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: BeeWiseColors.accent,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tìm gia sư phù hợp với nhu cầu của con',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mô tả mục tiêu học tập để AI gợi ý từ hồ sơ gia sư thật.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push('/matching'),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Bắt đầu ghép AI'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle('Khám phá theo môn học'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final subject in [
                  'Toán',
                  'Tiếng Anh',
                  'Ngữ văn',
                  'Vật lý',
                ])
                  ActionChip(
                    label: Text(subject),
                    onPressed: () => context.push(
                      '/search?q=${Uri.encodeQueryComponent(subject)}',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SectionTitle(
              'Gia sư đang hoạt động',
              trailing: TextButton(
                onPressed: () => context.push('/search'),
                child: const Text('Xem tất cả'),
              ),
            ),
            const SizedBox(height: 10),
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
      teachingMode: _mode,
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
          const SizedBox(height: 12),
          const Text('Môn học'),
          Wrap(
            spacing: 8,
            children: [
              for (final v in ['Toán', 'Tiếng Anh', 'Ngữ văn', 'Vật lý'])
                FilterChip(
                  label: Text(v),
                  selected: _subject == v,
                  onSelected: (_) =>
                      setState(() => _subject = _subject == v ? null : v),
                ),
            ],
          ),
          const Text('Khu vực'),
          Wrap(
            spacing: 8,
            children: [
              for (final v in ['Quận 1', 'Quận 3', 'Thủ Đức'])
                FilterChip(
                  label: Text(v),
                  selected: _area == v,
                  onSelected: (_) =>
                      setState(() => _area = _area == v ? null : v),
                ),
            ],
          ),
          const Text('Hình thức dạy'),
          Wrap(
            spacing: 8,
            children: [
              for (final v in ['Online', 'Tại nhà'])
                FilterChip(
                  label: Text(v),
                  selected: _mode == v,
                  onSelected: (_) =>
                      setState(() => _mode = _mode == v ? null : v),
                ),
            ],
          ),
          Text(
            'Học phí tối đa: ${_fee == null ? 'Không giới hạn' : '${NumberFormat.decimalPattern('vi_VN').format(_fee)}đ/giờ'}',
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
          TextButton(
            onPressed: () => setState(() => _fee = null),
            child: const Text('Bỏ giới hạn học phí'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Xếp theo học phí thấp'),
            value: _sort,
            onChanged: (value) => setState(() => _sort = value),
          ),
          const SizedBox(height: 8),
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
              Row(
                children: [
                  TutorAvatar(tutor: tutor, radius: 42),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tutor.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(tutor.credential),
                        if (tutor.verified)
                          const Chip(
                            avatar: Icon(
                              Icons.verified,
                              color: BeeWiseColors.success,
                              size: 18,
                            ),
                            label: Text('Đã xác minh'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in [
                    '${tutor.experienceYears} năm kinh nghiệm',
                    '${tutor.subjects.length} môn học',
                    ...tutor.teachingModes,
                  ])
                    Chip(label: Text(item)),
                ],
              ),
              const SectionTitle('Giới thiệu'),
              Text(
                tutor.introduction.isEmpty
                    ? 'Gia sư chưa cập nhật phần giới thiệu.'
                    : tutor.introduction,
              ),
              const SectionTitle('Chuyên môn'),
              Wrap(
                spacing: 8,
                children: [
                  for (final value in tutor.subjects) Chip(label: Text(value)),
                ],
              ),
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
              if (tutor.rating != null && tutor.reviewCount > 0) ...[
                const SizedBox(height: 20),
                const SectionTitle('Đánh giá'),
                Text(
                  '${tutor.rating!.toStringAsFixed(1)} ★  ·  ${tutor.reviewCount} đánh giá',
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => ref
                    .read(reportControllerProvider.notifier)
                    .exportAndUpload(tutor),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Xuất hồ sơ PDF và tải lên Firebase'),
              ),
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
            const Icon(
              Icons.hive_rounded,
              size: 52,
              color: BeeWiseColors.primary,
            ),
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
              icon: const Icon(Icons.g_mobiledata_rounded),
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
            Text(
              'Bắt đầu cùng BeeWise',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const Text(
              'Tạo tài khoản phụ huynh để gửi yêu cầu kết nối và nhận cập nhật.',
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Nhập email hợp lệ.' : null,
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
            CheckboxListTile(
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Tôi đồng ý để BeeWise sử dụng thông tin này để hỗ trợ kết nối gia sư.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (state.hasError)
              ErrorStateView(message: friendlyError(state.error!)),
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
                  children: [
                    TutorCard(
                      tutor: item,
                      onOpen: () => context.push('/tutors/${item.id}'),
                    ),
                    const SectionTitle('Thông tin học tập'),
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
                      decoration: const InputDecoration(labelText: 'Khu vực'),
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
                    const SizedBox(height: 12),
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
                  ],
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
                      child: EmptyStateView(
                        title: 'Chưa có tin nhắn',
                        message: 'Tin nhắn từ phụ huynh, gia sư và tư vấn viên sẽ xuất hiện ở đây.',
                        icon: Icons.chat_bubble_outline,
                      ),
                    )
                  : ListView(
                      reverse: false,
                      padding: const EdgeInsets.all(16),
                      children: [
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
          SafeArea(
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
        ],
      ),
    );
  }
}

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
    if (message.kind == 'trial_proposal') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Đề xuất buổi học thử',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(message.body),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => context.push('/trial/$chatId/${message.id}'),
                child: const Text('Xem và phản hồi'),
              ),
            ],
          ),
        ),
      );
    }
    if (message.kind == 'class_revision') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Xác nhận thông tin lớp học',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(message.body),
              FilledButton(
                onPressed: () => context.push('/class/$chatId/${message.id}'),
                child: const Text('Xem thông tin'),
              ),
            ],
          ),
        ),
      );
    }
    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 310),
        decoration: BoxDecoration(
          color: own ? BeeWiseColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!own)
              Text(
                message.senderName,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: BeeWiseColors.primary),
              ),
            Text(
              message.body,
              style: TextStyle(color: own ? Colors.white : BeeWiseColors.ink),
            ),
            Text(
              DateFormat('HH:mm').format(message.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: own ? Colors.white70 : BeeWiseColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
              child: EmptyStateView(
                title: 'Chưa có đề xuất',
                message: 'Chỉ tư vấn viên mới có thể gửi đề xuất buổi học thử.',
              ),
            );
          }
          final p = msg.payload;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(msg.body, style: Theme.of(context).textTheme.headlineMedium),
              InfoRow(
                label: 'Thời gian',
                value: '${p['date'] ?? 'Chưa cập nhật'} · ${p['time'] ?? ''}',
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
              if (state.hasError)
                ErrorStateView(message: friendlyError(state.error!)),
              BeeWiseButton(
                label: 'Đồng ý lịch học thử',
                loading: state.isLoading,
                onPressed: () => ref
                    .read(workflowControllerProvider.notifier)
                    .answerTrial(
                      chatId: widget.chatId,
                      proposalId: widget.proposalId,
                      accepted: true,
                    ),
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
                    : () => ref
                          .read(workflowControllerProvider.notifier)
                          .answerTrial(
                            chatId: widget.chatId,
                            proposalId: widget.proposalId,
                            accepted: false,
                            alternateTime: _alternate.text,
                          ),
                child: const Text('Đề xuất thời gian khác'),
              ),
            ],
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
              child: EmptyStateView(
                title: 'Chưa có thông tin lớp',
                message:
                    'Thông tin cần được tư vấn viên gửi trong cuộc trò chuyện.',
              ),
            );
          }
          final p = msg.payload;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Vui lòng kiểm tra thông tin trước khi xác nhận.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              for (final item in {
                'Môn học': p['subject'],
                'Gia sư': p['tutorName'],
                'Lịch học': p['schedule'],
                'Học phí': p['fee'],
                'Địa điểm': p['location'],
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InfoRow(
                    label: item.key,
                    value: '${item.value ?? 'Chưa cập nhật'}',
                  ),
                ),
              const StatusBanner(
                message: 'Chỉ xác nhận nội dung hiện tại. Yêu cầu thanh toán chỉ xuất hiện sau khi hệ thống nhận xác nhận này và tạo hóa đơn.',
              ),
              if (state.hasError)
                ErrorStateView(message: friendlyError(state.error!)),
              BeeWiseButton(
                label: 'Thông tin đã chính xác',
                loading: state.isLoading,
                onPressed: () => ref
                    .read(workflowControllerProvider.notifier)
                    .confirmClass(
                      chatId: widget.chatId,
                      revisionId: widget.revisionId,
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
              OutlinedButton(
                onPressed: state.isLoading || _reason.text.trim().isEmpty
                    ? null
                    : () => ref
                          .read(workflowControllerProvider.notifier)
                          .adjustClass(
                            chatId: widget.chatId,
                            revisionId: widget.revisionId,
                            reason: _reason.text,
                          ),
                child: const Text('Yêu cầu tư vấn viên điều chỉnh'),
              ),
            ],
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
              child: EmptyStateView(
                title: 'Chưa có hóa đơn',
                message: 'Hóa đơn sẽ chỉ xuất hiện sau khi hệ thống xác nhận các bước trước đó.',
              ),
            );
          }
          final data = doc.data()!;
          final status = data['status']?.toString() ?? 'pending';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Thông tin hóa đơn',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              InfoRow(label: 'Mã hóa đơn', value: invoiceId),
              InfoRow(
                label: 'Số tiền',
                value: data['amount'] == null
                    ? 'Chưa cập nhật'
                    : '${NumberFormat.decimalPattern('vi_VN').format(data['amount'])}đ',
              ),
              InfoRow(
                label: 'Trạng thái',
                value: status == 'verified' ? 'Đã xác nhận' : 'Chờ xác nhận',
              ),
              const StatusBanner(
                message: 'Trạng thái chuyển khoản phải được máy chủ hoặc đơn vị thanh toán xác thực. Ứng dụng không tự đánh dấu đã thanh toán.',
                kind: NoticeKind.warning,
              ),
              if (status == 'verified' && data['classId'] != null)
                BeeWiseButton(
                  label: 'Xem lịch học chính thức',
                  onPressed: () => context.push('/schedule/${data['classId']}'),
                ),
              if (status != 'verified')
                BeeWiseButton(
                  label: 'Tôi đã chuyển khoản · Gửi yêu cầu kiểm tra',
                  loading: state.isLoading,
                  onPressed: () => ref
                      .read(workflowControllerProvider.notifier)
                      .requestPaymentVerification(invoiceId),
                ),
              if (state.hasError)
                ErrorStateView(message: friendlyError(state.error!)),
            ],
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
                child: EmptyStateView(
                  title: 'Lịch chưa được xác nhận',
                  message: 'Lịch chính thức chỉ hiển thị sau khi hệ thống xác minh thanh toán.',
                  icon: Icons.lock_outline,
                ),
              );
            }
            final date = d['date']?.toString() ?? 'Chưa cập nhật';
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const StatusBanner(
                  message: 'Thanh toán đã được xác minh.',
                  kind: NoticeKind.success,
                ),
                Text(
                  '${d['subject'] ?? 'Lớp học'}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                InfoRow(
                  label: 'Gia sư',
                  value: '${d['tutorName'] ?? 'Chưa cập nhật'}',
                ),
                InfoRow(
                  label: 'Thời gian',
                  value: '$date · ${d['time'] ?? ''}',
                ),
                InfoRow(
                  label: 'Địa điểm',
                  value: '${d['location'] ?? 'Chưa cập nhật'}',
                ),
              ],
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
          error: (_, _) => const FirebaseSetupNotice(),
          data: (user) {
            if (user == null) {
              return Center(
                child: EmptyStateView(
                  title: 'Đăng nhập để xem tin nhắn',
                  message: 'Các cuộc trò chuyện với tư vấn viên và gia sư được lưu trong tài khoản của bạn.',
                  icon: Icons.lock_outline,
                  action: FilledButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Đăng nhập'),
                  ),
                ),
              );
            }
            return ref
                .watch(parentChatsProvider(user.uid))
                .when(
                  loading: () => const LoadingStateView(),
                  error: (error, stack) => ErrorStateView(
                    message: friendlyError(error),
                    onRetry: () =>
                        ref.invalidate(parentChatsProvider(user.uid)),
                  ),
                  data: (chats) {
                    if (chats.isEmpty) {
                      return const Center(
                        child: EmptyStateView(
                          title: 'Chưa có cuộc trò chuyện',
                          message: 'Sau khi gửi yêu cầu kết nối, nhóm trao đổi sẽ xuất hiện tại đây.',
                          icon: Icons.chat_bubble_outline,
                        ),
                      );
                    }
                    return ListView(
                      children: [
                        for (final chat in chats)
                          ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.groups_2_outlined),
                            ),
                            title: Text('Gia sư ${chat.tutorId}'),
                            subtitle: Text(_chatStatus(chat.onboardingStatus)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/chats/${chat.id}'),
                          ),
                      ],
                    );
                  },
                );
          },
        ),
  );
  String _chatStatus(String status) => switch (status) {
    'connection_pending_consultant' => 'Đang chờ tư vấn viên tiếp nhận',
    'trial_proposed' => 'Có đề xuất buổi học thử',
    'class_revision_pending' => 'Chờ điều chỉnh thông tin lớp',
    _ => 'Nhấn để xem cuộc trò chuyện',
  };
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final authAction = ref.watch(authControllerProvider);
    final notifications = ref.watch(notificationsProvider);
    final report = ref.watch(reportControllerProvider);
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
        children: [
          if (authAction.hasError)
            ErrorStateView(message: friendlyError(authAction.error!)),
          auth.when(
            loading: () => const LoadingStateView(),
            error: (error, stack) =>
                ErrorStateView(message: friendlyError(error)),
            data: (user) {
              if (user == null) {
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: const Text('Chưa đăng nhập'),
                    subtitle: const Text(
                      'Đăng nhập để quản lý tài khoản và dữ liệu của bạn.',
                    ),
                    trailing: TextButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('Đăng nhập'),
                    ),
                  ),
                );
              }
              final display = user.displayName ?? user.email ?? 'BeeWise';
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(display.characters.first.toUpperCase()),
                  ),
                  title: Text(user.displayName ?? 'Phụ huynh'),
                  subtitle: Text(user.email ?? ''),
                  trailing: IconButton(
                    tooltip: 'Đăng xuất',
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                    icon: const Icon(Icons.logout),
                  ),
                ),
              );
            },
          ),
          const SectionTitle('Thông báo'),
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
          const SectionTitle('Dịch vụ ứng dụng'),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Remote Config'),
            subtitle: Text(
              'Ghép AI: ${remoteConfig.matchingEnabled ? 'đang bật' : 'đang tắt'} · tối đa ${remoteConfig.aiResultLimit} kết quả',
            ),
          ),
          const SectionTitle('Tải tệp lên Firebase'),
          const Text(
            'Mở hồ sơ gia sư để xuất PDF. Tệp được tải lên vùng riêng reports/{uid}.',
          ),
          if (report.progress > 0 && report.progress < 1)
            LinearProgressIndicator(value: report.progress),
          if (report.error != null) ErrorStateView(message: report.error!),
          if (report.result != null)
            SelectableText(
              'Đã tải lên ${report.result!.storagePath}\n${report.result!.downloadUrl}',
            ),
          const SectionTitle('Chẩn đoán lỗi'),
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
            label: const Text('Gửi lỗi mẫu không nghiêm trọng'),
          ),
          OutlinedButton.icon(
            onPressed: () =>
                ref.read(crashReportingServiceProvider).triggerTestCrash(),
            icon: const Icon(Icons.warning_amber),
            label: const Text('Kiểm tra Crashlytics (ứng dụng sẽ đóng)'),
          ),
          if (!firebaseReady) const FirebaseSetupNotice(),
        ],
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
