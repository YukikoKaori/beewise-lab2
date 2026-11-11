import 'dart:async';

import 'package:beewise_core/beewise_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/firebase_bootstrap.dart';
import '../services/matching_service.dart';
import '../services/need_normalizer.dart';
import '../viewmodels/app_providers.dart';
import '../widgets/bee_wise_widgets.dart';

final needNormalizerProvider = Provider<NeedNormalizer>(
  (ref) => NeedNormalizer(ref.watch(remoteConfigProvider)),
);

class ConfirmTutorNeedScreen extends ConsumerStatefulWidget {
  const ConfirmTutorNeedScreen({super.key});

  @override
  ConsumerState<ConfirmTutorNeedScreen> createState() =>
      _ConfirmTutorNeedState();
}

class _ConfirmTutorNeedState extends ConsumerState<ConfirmTutorNeedScreen> {
  final _description = TextEditingController();
  final _fee = TextEditingController();
  final _form = GlobalKey<FormState>();
  String? _subject, _location, _schedule, _mode, _error;
  int? _grade;
  bool _editing = false, _ai = false, _busy = false;
  List<Tutor>? _results;
  int _revision = 0;

  void _openForm([NormalizedTutorNeed? need]) {
    setState(() {
      _revision++;
      _busy = false;
      _error = null;
      _results = null;
      _editing = true;
      _ai = need != null;
      _subject = need?.subject;
      _grade = need?.grade;
      _location = need?.location;
      _schedule = need?.schedule;
      _mode = need?.teachingMode;
      _fee.text = need?.maxHourlyFee?.toString() ?? '';
    });
  }

  Future<void> _parse() async {
    final input = _description.text;
    if (providerSafeNeed(input).isEmpty) {
      setState(() => _error = 'Hãy mô tả môn/lớp hoặc tự điền bộ lọc.');
      return;
    }
    final current = ++_revision;
    setState(() {
      _busy = true;
      _error = null;
      _results = null;
      _editing = false;
    });
    final telemetry = ref.read(analyticsServiceProvider);
    unawaited(telemetry.event('ai_request', {'feature': 'tutor_need'}));
    try {
      final need = await ref.read(needNormalizerProvider).parse(input);
      if (mounted && current == _revision) _openForm(need);
    } catch (error) {
      final kind = switch (error) {
        TimeoutException() => 'timeout',
        FormatException() => 'invalid_response',
        MatchingException() => 'unavailable',
        _ => 'provider',
      };
      unawaited(
        telemetry.event('ai_error', {'feature': 'tutor_need', 'kind': kind}),
      );
      if (mounted && current == _revision) {
        setState(() {
          _busy = false;
          _error = 'Chưa lấy được gợi ý AI. Thử lại hoặc tự điền bộ lọc.';
        });
      }
    }
  }

  Future<void> _confirm() async {
    if (_form.currentState?.validate() != true) return;
    final confirmed = NormalizedTutorNeed(
      subject: _subject,
      grade: _grade,
      location: _location,
      maxHourlyFee: int.tryParse(_fee.text.trim()),
      schedule: _schedule,
      teachingMode: _mode,
    );
    final current = ++_revision;
    setState(() {
      _busy = true;
      _error = null;
      _results = null;
    });
    if (_ai) {
      unawaited(
        ref.read(analyticsServiceProvider).event('ai_result_accepted', {
          'feature': 'tutor_need',
        }),
      );
    }
    try {
      final repo = ref.read(tutorRepositoryProvider);
      final tutors = await repo
          .activeTutors(limit: 100)
          .timeout(const Duration(seconds: 15));
      final limit = ref.read(remoteConfigProvider).aiResultLimit;
      final results = matchConfirmedNeed(
        tutors,
        confirmed,
      ).take(limit).toList();
      if (mounted && current == _revision) setState(() => _results = results);
    } catch (_) {
      if (mounted && current == _revision) {
        setState(
          () => _error =
              'Chưa tải được danh mục gia sư. Kiểm tra kết nối rồi tìm lại.',
        );
      }
    } finally {
      if (mounted && current == _revision) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _fee.dispose();
    super.dispose();
  }

  Widget _choice<T>({
    required String label,
    required T? current,
    required List<T> values,
    required ValueChanged<T?> select,
    String Function(T)? format,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<T?>(
      initialValue: current,
      decoration: InputDecoration(labelText: label),
      isExpanded: true,
      items: [
        const DropdownMenuItem(value: null, child: Text('Không yêu cầu')),
        for (final value in values)
          DropdownMenuItem(
            value: value,
            child: Text(format?.call(value) ?? value.toString()),
          ),
      ],
      onChanged: _busy
          ? null
          : (value) => setState(() {
              select(value);
              _results = null;
            }),
    ),
  );

  @override
  Widget build(BuildContext context) {
    ref.watch(remoteConfigInitializationProvider);
    ref.listen(currentAuthenticatedUidProvider, (previous, next) {
      if (previous == next) return;
      _description.clear();
      _openForm();
      setState(() => _editing = false);
    });
    final enabled =
        !usesFirebaseEmulators &&
        ref.watch(remoteConfigProvider).matchingEnabled;
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
            'Nhập nhu cầu học tập. BeeWise chỉ gửi các gợi ý học tập đã lọc. Không nhập thông tin cá nhân.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            readOnly: _busy,
            maxLength: 500,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Toán lớp 9 ở Thủ Đức, học phí dưới 200k, buổi tối',
            ),
          ),
          BeeWiseButton(
            label: 'Phân tích nhu cầu bằng AI',
            icon: Icons.auto_awesome,
            onPressed: enabled && !_busy ? _parse : null,
          ),
          if (!enabled)
            const Text(
              'AI hiện không khả dụng. Bạn vẫn có thể tự điền và tìm gia sư.',
            ),
          TextButton(onPressed: _openForm, child: const Text('Tự điền bộ lọc')),
          if (_editing)
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _ai
                        ? 'Gợi ý AI · Kiểm tra và chỉnh sửa'
                        : 'Yêu cầu học tập',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _choice(
                    label: 'Môn học',
                    current: _subject,
                    values: NormalizedTutorNeed.subjects,
                    select: (v) => _subject = v,
                  ),
                  _choice(
                    label: 'Khối lớp',
                    current: _grade,
                    values: List.generate(12, (i) => i + 1),
                    select: (v) => _grade = v,
                  ),
                  _choice(
                    label: 'Khu vực',
                    current: _location,
                    values: NormalizedTutorNeed.locations,
                    select: (v) => _location = v,
                  ),
                  _choice(
                    label: 'Lịch ưu tiên',
                    current: _schedule,
                    values: NormalizedTutorNeed.schedules,
                    select: (v) => _schedule = v,
                  ),
                  _choice(
                    label: 'Hình thức',
                    current: _mode,
                    values: NormalizedTutorNeed.modes,
                    select: (v) => _mode = v,
                    format: (v) => v == 'online' ? 'Trực tuyến' : 'Trực tiếp',
                  ),
                  TextFormField(
                    controller: _fee,
                    readOnly: _busy,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Phí tối đa mỗi giờ (VND)',
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) return null;
                      final amount = int.tryParse(text);
                      return amount == null ||
                              amount < 1 ||
                              amount > NormalizedTutorNeed.maxFee
                          ? 'Nhập mức phí bằng số VND hợp lệ.'
                          : null;
                    },
                    onChanged: (_) => setState(() => _results = null),
                  ),
                  const SizedBox(height: 12),
                  BeeWiseButton(
                    label: 'Xác nhận và tìm gia sư',
                    onPressed: _busy ? null : _confirm,
                  ),
                ],
              ),
            ),
          if (_busy) const LoadingStateView(),
          if (_error != null) ErrorStateView(message: _error!),
          if (_results != null && _results!.isEmpty)
            const Text('Chưa có hồ sơ phù hợp với bộ lọc đã xác nhận.'),
          if (_results?.isNotEmpty == true) ...[
            const SectionTitle('Gia sư phù hợp'),
            for (final tutor in _results!)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TutorCard(
                  tutor: tutor,
                  onOpen: () => context.push('/tutors/${tutor.id}'),
                ),
              ),
          ],
          TextButton(
            onPressed: () => context.go('/search'),
            child: const Text('Mở trang tìm kiếm gia sư'),
          ),
        ],
      ),
    );
  }
}

List<Tutor> matchConfirmedNeed(List<Tutor> tutors, NormalizedTutorNeed need) {
  bool contains(List<String> values, String? value) =>
      value == null ||
      values.any((item) => item.toLowerCase() == value.toLowerCase());
  return tutors.where((tutor) {
    final grade = need.grade;
    final schedule = need.schedule?.replaceFirst('buổi ', '');
    return tutor.active &&
        !tutor.isSyntheticTestFixture &&
        contains(tutor.subjects, need.subject) &&
        contains(tutor.areas, need.location) &&
        contains(tutor.teachingModes, need.teachingMode) &&
        (grade == null ||
            tutor.grades.any(
              (label) =>
                  label.toLowerCase().replaceFirst('lớp ', '').trim() ==
                  grade.toString(),
            )) &&
        (need.maxHourlyFee == null || tutor.hourlyFee <= need.maxHourlyFee!) &&
        (schedule == null ||
            tutor.availability.toLowerCase().contains(schedule));
  }).toList();
}
