import 'package:beewise_core/beewise_core.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../services/firebase_bootstrap.dart' show usesFinalFirestore;
import '../services/tutor_application_service.dart';
import '../theme/bee_wise_theme.dart';
import '../viewmodels/app_providers.dart';
import '../viewmodels/controllers.dart';
import '../widgets/bee_wise_widgets.dart';

/// Available options matching Figma T1
const _kAvailableSubjects = [
  'Toán',
  'Hóa học',
  'Vật lý',
  'Tiếng Anh',
  'Ngữ văn',
  'Sinh học',
  'Lịch sử',
  'Địa lý',
  'Tin học',
];

const _kAvailableGrades = [
  'Lớp 6',
  'Lớp 7',
  'Lớp 8',
  'Lớp 9',
  'Ôn thi vào 10',
  'Lớp 10',
  'Lớp 11',
  'Lớp 12',
];

// Canonical areas come from core.NormalizedTutorNeed.locations so T1,
// SearchScreen, and Gemini Level 2 share one normalized geographical vocabulary.

const _kAvailableTimes = [
  'T2 tối',
  'T3 tối',
  'T4 tối',
  'T5 tối',
  'T6 tối',
  'T7 tối',
  'CN sáng',
  'CN tối',
];

/// T1: Đăng ký gia sư & Cập nhật hồ sơ cần bổ sung (`needs_info`)
class TutorApplicationScreen extends ConsumerStatefulWidget {
  const TutorApplicationScreen({super.key, this.isResubmissionRoute = false});

  final bool isResubmissionRoute;

  @override
  ConsumerState<TutorApplicationScreen> createState() =>
      _TutorApplicationScreenState();
}

class _TutorApplicationScreenState
    extends ConsumerState<TutorApplicationScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _qualification = TextEditingController();
  final _introduction = TextEditingController();
  final _hourlyFee = TextEditingController();

  final _selectedSubjects = <String>{};
  final _selectedGrades = <String>{};
  final _selectedAreas = <String>{};
  final _selectedTimes = <String>{};
  final _selectedModes = <String>{};

  bool _consent = false;
  bool _showPassword = false;
  bool _hasAttemptedSubmit = false;
  String? _prefilledForUid;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _qualification.dispose();
    _introduction.dispose();
    _hourlyFee.dispose();
    super.dispose();
  }

  void _prefillFromExisting(TutorApplicationData data) {
    if (_prefilledForUid == data.uid) return;
    _prefilledForUid = data.uid;
    _name.text = data.name;
    _phone.text = data.phone;
    _email.text = data.email;
    _qualification.text = data.qualification;
    _introduction.text = data.introduction;
    _hourlyFee.text = data.hourlyFee > 0 ? '${data.hourlyFee}' : '';

    _selectedSubjects
      ..clear()
      ..addAll(data.subjects.where((s) => s.trim().isNotEmpty));
    _selectedGrades
      ..clear()
      ..addAll(data.grades.where((g) => g.trim().isNotEmpty));
    _selectedAreas
      ..clear()
      ..addAll(core.NormalizedTutorNeed.normalizeLocationList(data.areas));

    _selectedTimes.clear();
    for (final part in data.availability.split(',')) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty) {
        _selectedTimes.add(trimmed);
      }
    }

    _selectedModes.clear();
    for (final mode in data.teachingModes) {
      if (mode == 'online' || mode == 'Trực tuyến') {
        _selectedModes.add('Trực tuyến');
      } else if (mode == 'in_person' || mode == 'Trực tiếp') {
        _selectedModes.add('Trực tiếp');
      }
    }
    _consent = true;
  }

  bool _isValidPassword(String value) =>
      value.length >= 8 && RegExp(r'\d').hasMatch(value);

  int _countErrors({required bool isEditMode}) {
    int errors = 0;
    if (_name.text.trim().length < 2) errors++;
    final cleanPhone = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length < 10) errors++;
    if (!isEditMode) {
      if (!_email.text.contains('@')) errors++;
      if (!_isValidPassword(_password.text)) errors++;
    }
    if (_qualification.text.trim().isEmpty) errors++;
    if (_selectedSubjects.isEmpty) errors++;
    if (_selectedGrades.isEmpty) errors++;
    if (_introduction.text.trim().length < 20) errors++;
    final fee = int.tryParse(_hourlyFee.text.replaceAll('.', '').trim());
    if (fee == null || fee <= 0) errors++;
    if (_selectedAreas.isEmpty) errors++;
    if (_selectedTimes.isEmpty) errors++;
    if (_selectedModes.isEmpty) errors++;
    if (!_consent) errors++;
    return errors;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).asData?.value;
    final uid = user?.isAnonymous == false ? user!.uid : null;
    final existingAppAsync = uid != null
        ? ref.watch(tutorApplicationDataProvider(uid))
        : const AsyncData<TutorApplicationData?>(null);

    return existingAppAsync.when(
      skipLoadingOnReload: false,
      skipLoadingOnRefresh: false,
      skipError: false,
      loading: () => const BeeWiseScaffold(
        title: 'Đăng ký gia sư',
        showBack: true,
        body: LoadingStateView(),
      ),
      error: (err, _) => BeeWiseScaffold(
        title: 'Đăng ký gia sư',
        showBack: true,
        body: ListView(
          padding: const EdgeInsets.all(BeeWiseSpace.x4),
          children: [
            ErrorStateView(
              message: friendlyError(err),
              onRetry: () {
                if (uid != null) {
                  ref.invalidate(tutorApplicationDataProvider(uid));
                }
              },
            ),
          ],
        ),
      ),
      data: (existingApp) {
        if (existingApp != null && !existingApp.canEditApplication) {
          return BeeWiseScaffold(
            title: 'Hồ sơ gia sư',
            showBack: true,
            body: Padding(
              padding: const EdgeInsets.all(BeeWiseSpace.x5),
              child: EmptyStateView(
                title: existingApp.status == 'rejected'
                    ? 'Hồ sơ đã bị từ chối'
                    : 'Hồ sơ không ở trạng thái cần bổ sung',
                message: existingApp.status == 'rejected'
                    ? 'Hồ sơ đã bị từ chối không thể tự chỉnh sửa và gửi lại.'
                    : 'Chỉ hồ sơ được yêu cầu bổ sung mới có thể chỉnh sửa.',
                icon: Icons.lock_outline_rounded,
                action: BeeWiseButton(
                  label: 'Xem trạng thái hồ sơ',
                  onPressed: () => context.go('/tutor/pending'),
                ),
              ),
            ),
          );
        }

        final isEditMode =
            existingApp != null && existingApp.canEditApplication;
        if (isEditMode) {
          _prefillFromExisting(existingApp);
        }
        final canResubmitToBackend =
            ref
                .watch(tutorApplicationServiceProvider)
                ?.isResubmissionBackendAvailable ==
            true;

        final state = ref.watch(tutorApplicationControllerProvider);
        ref.listen(tutorApplicationControllerProvider, (previous, next) {
          if (previous?.isLoading == true &&
              next.hasValue &&
              !next.isLoading &&
              !next.hasError &&
              mounted) {
            context.go('/tutor/pending');
          }
        });

        final errorCount = _hasAttemptedSubmit
            ? _countErrors(isEditMode: isEditMode)
            : 0;
        final hasErrors = _hasAttemptedSubmit && errorCount > 0;

        return BeeWiseScaffold(
          title: isEditMode ? 'Cập nhật hồ sơ gia sư' : 'Đăng ký gia sư',
          showBack: true,
          body: Form(
            key: _form,
            autovalidateMode: _hasAttemptedSubmit
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: BeeWiseSpace.x4,
                vertical: BeeWiseSpace.x3,
              ),
              children: [
                Text(
                  isEditMode
                      ? 'Bổ sung hồ sơ gia sư BeeWise'
                      : 'Trở thành gia sư BeeWise',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: BeeWiseColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: BeeWiseSpace.x1),
                Text(
                  isEditMode
                      ? 'Cập nhật các mục được yêu cầu bên dưới rồi gửi lại để chuyển về trạng thái chờ duyệt.'
                      : 'Hồ sơ gồm 3 phần, mất khoảng 5 phút. Bạn chỉ cần làm 1 lần duy nhất.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: BeeWiseColors.muted),
                ),
                const SizedBox(height: BeeWiseSpace.x4),

                if (isEditMode &&
                    existingApp.rejectionReason != null &&
                    existingApp.rejectionReason!.trim().isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(BeeWiseSpace.x3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(BeeWiseRadius.md),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFE11D48),
                          size: 20,
                        ),
                        const SizedBox(width: BeeWiseSpace.x2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'YÊU CẦU BỔ SUNG TỪ BEEWISE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFBE123C),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                existingApp.rejectionReason!.trim(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF881337),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: BeeWiseSpace.x4),
                ],

                if (isEditMode && !canResubmitToBackend) ...[
                  Container(
                    padding: const EdgeInsets.all(BeeWiseSpace.x3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(BeeWiseRadius.md),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_clock_outlined,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                        SizedBox(width: BeeWiseSpace.x2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CẦN QUYỀN MÁY CHỦ ĐỂ GỬI LẠI HỒ SƠ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                TutorApplicationService
                                    .resubmissionServerBlockMessage,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF78350F),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: BeeWiseSpace.x4),
                ],

                // Figma Validation Error Banner
                if (hasErrors) ...[
                  Container(
                    padding: const EdgeInsets.all(BeeWiseSpace.x3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(BeeWiseRadius.md),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFDC2626),
                          size: 22,
                        ),
                        const SizedBox(width: BeeWiseSpace.x2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Còn $errorCount mục cần sửa',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: const Color(0xFFB91C1C),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Các ô viền đỏ bên dưới cần sửa trước khi gửi. Thông tin đúng giúp bạn dễ nhận lớp đúng ý.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: const Color(0xFF991B1B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: BeeWiseSpace.x4),
                ],

                // SECTION 1: Tài khoản
                _buildSectionCard(
                  number: 1,
                  title: 'Tài khoản',
                  children: [
                    _buildInput(
                      controller: _name,
                      label: 'Họ và tên',
                      icon: Icons.person_outline_rounded,
                      validator: (v) => v == null || v.trim().length < 2
                          ? 'Họ và tên cần từ 2 ký tự'
                          : null,
                    ),
                    const SizedBox(height: BeeWiseSpace.x3),
                    _buildInput(
                      controller: _phone,
                      label: 'Số điện thoại',
                      icon: Icons.chat_bubble_outline_rounded,
                      keyboardType: TextInputType.phone,
                      hasError:
                          _hasAttemptedSubmit &&
                          _phone.text.replaceAll(RegExp(r'\D'), '').length < 10,
                      validator: (v) {
                        final clean = (v ?? '').replaceAll(RegExp(r'\D'), '');
                        return clean.length < 10
                            ? 'Số điện thoại cần đủ 10 số'
                            : null;
                      },
                    ),
                    const SizedBox(height: BeeWiseSpace.x3),
                    _buildInput(
                      controller: _email,
                      label: 'Email',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isEditMode,
                      helperText: isEditMode
                          ? 'Giữ nguyên tài khoản đã đăng ký (UID: ${existingApp.uid})'
                          : null,
                      validator: isEditMode
                          ? null
                          : (v) => v == null || !v.contains('@')
                                ? 'Email chưa hợp lệ'
                                : null,
                    ),
                    if (!isEditMode) ...[
                      const SizedBox(height: BeeWiseSpace.x3),
                      TextFormField(
                        controller: _password,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          hintText: 'Tối thiểu 8 ký tự và có chữ số',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          helperText: 'Chỉ cho tài khoản mới',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        validator: (v) => v == null || !_isValidPassword(v)
                            ? 'Mật khẩu cần ít nhất 8 ký tự và có chữ số'
                            : null,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: BeeWiseSpace.x4),

                // SECTION 2: Chuyên môn
                _buildSectionCard(
                  number: 2,
                  title: 'Chuyên môn',
                  children: [
                    _buildInput(
                      controller: _qualification,
                      label: 'Bằng cấp / kinh nghiệm',
                      icon: Icons.school_outlined,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Vui lòng nhập bằng cấp hoặc kinh nghiệm'
                          : null,
                    ),
                    const SizedBox(height: BeeWiseSpace.x3),

                    // Subjects Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Môn dạy',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${_selectedSubjects.length}/10',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                _hasAttemptedSubmit && _selectedSubjects.isEmpty
                                ? BeeWiseColors.error
                                : BeeWiseColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: BeeWiseSpace.x1),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _kAvailableSubjects
                          .map(
                            (subj) => _buildChip(
                              label: subj,
                              selected: _selectedSubjects.contains(subj),
                              onSelected: (sel) {
                                setState(() {
                                  if (sel) {
                                    if (_selectedSubjects.length < 10) {
                                      _selectedSubjects.add(subj);
                                    }
                                  } else {
                                    _selectedSubjects.remove(subj);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                    if (_hasAttemptedSubmit && _selectedSubjects.isEmpty) ...[
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: BeeWiseColors.error,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Chưa chọn môn dạy',
                              style: TextStyle(
                                color: BeeWiseColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: BeeWiseSpace.x3),

                    // Grades Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Khối lớp',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${_selectedGrades.length}/12',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                _hasAttemptedSubmit && _selectedGrades.isEmpty
                                ? BeeWiseColors.error
                                : BeeWiseColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: BeeWiseSpace.x1),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _kAvailableGrades
                          .map(
                            (grade) => _buildChip(
                              label: grade,
                              selected: _selectedGrades.contains(grade),
                              onSelected: (sel) {
                                setState(() {
                                  if (sel) {
                                    if (_selectedGrades.length < 12) {
                                      _selectedGrades.add(grade);
                                    }
                                  } else {
                                    _selectedGrades.remove(grade);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                    if (_hasAttemptedSubmit && _selectedGrades.isEmpty) ...[
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: BeeWiseColors.error,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Chưa chọn khối lớp',
                              style: TextStyle(
                                color: BeeWiseColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: BeeWiseSpace.x3),

                    // Introduction / Bio
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Giới thiệu bản thân',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(width: BeeWiseSpace.x2),
                        Text(
                          '${_introduction.text.length}/1000${_introduction.text.length < 20 ? ' - Tối thiểu 20' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                _hasAttemptedSubmit &&
                                    _introduction.text.trim().length < 20
                                ? BeeWiseColors.error
                                : BeeWiseColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: BeeWiseSpace.x1),
                    TextFormField(
                      controller: _introduction,
                      minLines: 3,
                      maxLines: 5,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Nêu rõ kinh nghiệm giảng dạy, phương pháp và cam kết...',
                        focusedBorder:
                            _hasAttemptedSubmit &&
                                _introduction.text.trim().length < 20
                            ? OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  BeeWiseRadius.field,
                                ),
                                borderSide: const BorderSide(
                                  color: BeeWiseColors.error,
                                ),
                              )
                            : null,
                        enabledBorder:
                            _hasAttemptedSubmit &&
                                _introduction.text.trim().length < 20
                            ? OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  BeeWiseRadius.field,
                                ),
                                borderSide: const BorderSide(
                                  color: BeeWiseColors.error,
                                ),
                              )
                            : null,
                      ),
                    ),
                    if (_hasAttemptedSubmit &&
                        _introduction.text.trim().length < 20) ...[
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: BeeWiseColors.error,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Giới thiệu cần ít nhất 20 ký tự',
                              style: TextStyle(
                                color: BeeWiseColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: BeeWiseSpace.x4),

                // SECTION 3: Học phí và lịch
                _buildSectionCard(
                  number: 3,
                  title: 'Học phí và lịch',
                  children: [
                    _buildInput(
                      controller: _hourlyFee,
                      label: 'Học phí mỗi giờ (VNĐ)',
                      icon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      helperText:
                          'Phụ huynh thấy đúng số này; bạn nhận tiền theo giờ',
                      validator: (v) {
                        final fee = int.tryParse(
                          (v ?? '').replaceAll('.', '').trim(),
                        );
                        return fee == null || fee <= 0
                            ? 'Nhập học phí lớn hơn 0'
                            : null;
                      },
                    ),
                    const SizedBox(height: BeeWiseSpace.x3),

                    // Area Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Khu vực dạy',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${_selectedAreas.length}/10',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BeeWiseColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: BeeWiseSpace.x1),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children:
                          [
                                ...core.NormalizedTutorNeed.locations,
                                ..._selectedAreas.where(
                                  (a) => !core.NormalizedTutorNeed.locations
                                      .contains(a),
                                ),
                              ]
                              .map(
                                (area) => _buildChip(
                                  label: area,
                                  selected: _selectedAreas.contains(area),
                                  onSelected: (sel) {
                                    setState(() {
                                      if (sel) {
                                        if (_selectedAreas.length < 10) {
                                          _selectedAreas.add(area);
                                        }
                                      } else {
                                        _selectedAreas.remove(area);
                                      }
                                    });
                                  },
                                ),
                              )
                              .toList(growable: false),
                    ),
                    const SizedBox(height: BeeWiseSpace.x3),

                    // Availability Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thời gian rảnh',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const Text(
                          'Chọn tối đa',
                          style: TextStyle(
                            fontSize: 12,
                            color: BeeWiseColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: BeeWiseSpace.x1),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _kAvailableTimes
                          .map(
                            (t) => _buildChip(
                              label: t,
                              selected: _selectedTimes.contains(t),
                              onSelected: (sel) {
                                setState(() {
                                  if (sel) {
                                    _selectedTimes.add(t);
                                  } else {
                                    _selectedTimes.remove(t);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: BeeWiseSpace.x3),

                    // Teaching Modes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hình thức dạy',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const Text(
                          'Chọn 1 hoặc 2',
                          style: TextStyle(
                            fontSize: 12,
                            color: BeeWiseColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: BeeWiseSpace.x1),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildChip(
                          label: 'Trực tiếp',
                          selected: _selectedModes.contains('Trực tiếp'),
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                _selectedModes.add('Trực tiếp');
                              } else {
                                _selectedModes.remove('Trực tiếp');
                              }
                            });
                          },
                        ),
                        _buildChip(
                          label: 'Trực tuyến',
                          selected: _selectedModes.contains('Trực tuyến'),
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                _selectedModes.add('Trực tuyến');
                              } else {
                                _selectedModes.remove('Trực tuyến');
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: BeeWiseSpace.x4),

                // Consent Checkbox
                InkWell(
                  onTap: () => setState(() => _consent = !_consent),
                  borderRadius: BorderRadius.circular(BeeWiseRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _consent,
                          onChanged: (v) =>
                              setState(() => _consent = v ?? false),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tôi đồng ý để BeeWise xác minh thông tin này và chỉ chia sẻ thông tin khi đã được duyệt.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: BeeWiseSpace.x2),

                // Info note
                Container(
                  padding: const EdgeInsets.all(BeeWiseSpace.x3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(BeeWiseRadius.md),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
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
                          'Sau khi gửi, hồ sơ ở trạng thái chờ duyệt và chưa hiển thị trong tìm kiếm.',
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
                const SizedBox(height: BeeWiseSpace.x4),

                if (state.hasError) ...[
                  ErrorStateView(message: friendlyError(state.error!)),
                  const SizedBox(height: BeeWiseSpace.x3),
                ],

                // Submit Button
                if (isEditMode && !canResubmitToBackend) ...[
                  BeeWiseButton(
                    label: 'Gửi lại hồ sơ (Chờ mở quyền máy chủ)',
                    onPressed: null,
                  ),
                  const SizedBox(height: BeeWiseSpace.x2),
                  BeeWiseButton(
                    label: 'Kiểm tra hợp lệ thông tin đã sửa',
                    secondary: true,
                    onPressed: () {
                      setState(() => _hasAttemptedSubmit = true);
                      final valid = _form.currentState!.validate();
                      final errors = _countErrors(isEditMode: true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            (!valid || errors > 0)
                                ? 'Vui lòng hoàn thành các mục hợp lệ trước khi gửi.'
                                : 'Thông tin chỉnh sửa hợp lệ. Cần xác thực từ máy chủ BeeWise để cập nhật hồ sơ gốc.',
                          ),
                        ),
                      );
                    },
                  ),
                ] else
                  BeeWiseButton(
                    label: isEditMode ? 'Gửi lại hồ sơ' : 'Gửi hồ sơ',
                    loading: state.isLoading,
                    onPressed: state.isLoading
                        ? null
                        : () => _submit(
                            isEditMode: isEditMode,
                            existingUid: existingApp?.uid,
                          ),
                  ),
                const SizedBox(height: BeeWiseSpace.x2),
                if (!isEditMode)
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text(
                      'Bạn là phụ huynh? Tạo tài khoản phụ huynh',
                    ),
                  )
                else
                  TextButton(
                    onPressed: () => context.go('/tutor/pending'),
                    child: const Text('Quay lại trạng thái hồ sơ'),
                  ),
                if (!ref.watch(firebaseReadyProvider))
                  const FirebaseSetupNotice(),
                const SizedBox(height: BeeWiseSpace.x6),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required int number,
    required String title,
    required List<Widget> children,
  }) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(BeeWiseRadius.card),
      side: const BorderSide(color: BeeWiseColors.border),
    ),
    color: BeeWiseColors.surface,
    child: Padding(
      padding: const EdgeInsets.all(BeeWiseSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: BeeWiseColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: BeeWiseSpace.x2),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: BeeWiseSpace.x3),
          ...children,
        ],
      ),
    ),
  );

  Widget _buildChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) => FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
    selectedColor: BeeWiseColors.primary,
    checkmarkColor: Colors.white,
    labelStyle: TextStyle(
      color: selected ? Colors.white : BeeWiseColors.ink,
      fontSize: 13,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
    ),
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(BeeWiseRadius.full),
      side: BorderSide(
        color: selected ? BeeWiseColors.primary : const Color(0xFFCBD5E1),
      ),
    ),
  );

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? helperText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool hasError = false,
    bool enabled = true,
  }) => TextFormField(
    controller: controller,
    enabled: enabled,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      helperText: helperText,
      enabledBorder: hasError
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(BeeWiseRadius.field),
              borderSide: const BorderSide(color: BeeWiseColors.error),
            )
          : null,
      focusedBorder: hasError
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(BeeWiseRadius.field),
              borderSide: const BorderSide(
                color: BeeWiseColors.error,
                width: 1.5,
              ),
            )
          : null,
    ),
    keyboardType: keyboardType,
    validator: validator,
  );

  void _submit({required bool isEditMode, required String? existingUid}) {
    setState(() => _hasAttemptedSubmit = true);
    final valid = _form.currentState!.validate();
    final errors = _countErrors(isEditMode: isEditMode);
    if (!valid || errors > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng hoàn thành các mục hợp lệ trước khi gửi.'),
        ),
      );
      return;
    }

    final fee = int.parse(_hourlyFee.text.replaceAll('.', '').trim());
    final modes = _selectedModes
        .map((m) => m == 'Trực tuyến' ? 'online' : 'in_person')
        .toList(growable: false);

    if (isEditMode && existingUid != null) {
      ref
          .read(tutorApplicationControllerProvider.notifier)
          .resubmit(
            uid: existingUid,
            name: _name.text,
            phone: _phone.text,
            qualification: _qualification.text,
            introduction: _introduction.text,
            subjects: _selectedSubjects.toList(growable: false),
            grades: _selectedGrades.toList(growable: false),
            hourlyFee: fee,
            areas: _selectedAreas.toList(growable: false),
            teachingModes: modes,
            availability: _selectedTimes.join(', '),
          );
      return;
    }

    ref
        .read(tutorApplicationControllerProvider.notifier)
        .submit(
          name: _name.text,
          phone: _phone.text,
          email: _email.text,
          password: _password.text,
          qualification: _qualification.text,
          introduction: _introduction.text,
          subjects: _selectedSubjects.toList(growable: false),
          grades: _selectedGrades.toList(growable: false),
          hourlyFee: fee,
          areas: _selectedAreas.toList(growable: false),
          teachingModes: modes,
          availability: _selectedTimes.join(', '),
        );
  }
}

/// T2: Hồ sơ gia sư (Application Status screen matching Figma T2)
/// Supports Pending, Needs Info, Rejected, Approved Pending Activation, and Authorized Tutor.
class TutorApplicationStatusScreen extends ConsumerWidget {
  const TutorApplicationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null || user.isAnonymous) {
      return BeeWiseScaffold(
        title: 'Trạng thái hồ sơ',
        showBack: true,
        body: Padding(
          padding: const EdgeInsets.all(BeeWiseSpace.x5),
          child: EmptyStateView(
            title: 'Cần đăng nhập',
            message: 'Đăng nhập để xem trạng thái hồ sơ gia sư.',
            action: BeeWiseButton(
              label: 'Đăng nhập',
              onPressed: () => context.go('/login'),
            ),
          ),
        ),
      );
    }

    final appDataAsync = ref.watch(tutorApplicationDataProvider(user.uid));
    final liveStatus = ref
        .watch(tutorApplicationStatusProvider(user.uid))
        .asData
        ?.value;

    return BeeWiseScaffold(
      title: 'Hồ sơ gia sư',
      showBack: appDataAsync.asData?.value?.isAuthorizedTutor == true,
      body: appDataAsync.when(
        skipLoadingOnReload: false,
        skipLoadingOnRefresh: false,
        skipError: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(BeeWiseSpace.x5),
          children: [
            ErrorStateView(
              message: friendlyError(error),
              onRetry: () =>
                  ref.invalidate(tutorApplicationDataProvider(user.uid)),
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
        data: (appData) {
          if (appData == null) {
            return ListView(
              padding: const EdgeInsets.all(BeeWiseSpace.x5),
              children: [
                const EmptyStateView(
                  title: 'Chưa tìm thấy hồ sơ gia sư',
                  message: 'Tài khoản này chưa có hồ sơ đăng ký gia sư trên hệ thống.',
                  icon: Icons.assignment_outlined,
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
            );
          }

          final effectiveStatus = liveStatus ?? appData.status;
          final isFullyAuthorized =
              effectiveStatus == 'approved' &&
              appData.verified &&
              appData.active;
          final isApprovedPendingActivation =
              effectiveStatus == 'approved' && !isFullyAuthorized;

          final name = appData.name.trim().isNotEmpty
              ? appData.name.trim()
              : (user.displayName?.trim().isNotEmpty == true
                    ? user.displayName!.trim()
                    : 'bạn');

          final subjectsParts = <String>[
            if (appData.subjects.isNotEmpty) appData.subjects.join(', '),
            if (appData.grades.isNotEmpty) appData.grades.join(', '),
          ];
          final subjectsAndGrades = subjectsParts.isEmpty
              ? 'Chưa cập nhật'
              : subjectsParts.join(' · ');

          final feeText = appData.hourlyFee > 0
              ? '${NumberFormat.decimalPattern('vi_VN').format(appData.hourlyFee)}đ/giờ'
              : 'Chưa cập nhật';

          final dateText = appData.createdAt != null
              ? DateFormat('dd/MM/yyyy').format(appData.createdAt!)
              : 'Chưa cập nhật';

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: BeeWiseSpace.x4,
              vertical: BeeWiseSpace.x4,
            ),
            children: [
              // 1. HERO CARD with Sticker & Status
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
                      if (isFullyAuthorized)
                        const BeeSticker.cheer(size: 100)
                      else if (effectiveStatus == 'needs_info' ||
                          effectiveStatus == 'rejected')
                        const BeeSticker.wand(size: 100)
                      else
                        const BeeSticker.robot(size: 100),
                      const SizedBox(height: BeeWiseSpace.x3),

                      _buildStatusPill(
                        effectiveStatus,
                        isFullyAuthorized: isFullyAuthorized,
                        isApprovedPendingActivation:
                            isApprovedPendingActivation,
                      ),
                      const SizedBox(height: BeeWiseSpace.x3),

                      Text(
                        isFullyAuthorized
                            ? 'Chào mừng $name!'
                            : isApprovedPendingActivation
                            ? 'Hồ sơ đã duyệt, chờ kích hoạt'
                            : switch (effectiveStatus) {
                                'needs_info' => 'Hồ sơ cần bổ sung',
                                'rejected' => 'Hồ sơ chưa được phê duyệt',
                                _ => 'Hồ sơ đang chờ duyệt',
                              },
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: BeeWiseSpace.x2),

                      Text(
                        isFullyAuthorized
                            ? (usesFinalFirestore
                                  ? 'Bạn đã có quyền vào khu vực gia sư. Việc đăng hồ sơ để phụ huynh tìm thấy là bước riêng.'
                                  : 'Hồ sơ đã được xác minh và kích hoạt. Khi phụ huynh gửi yêu cầu kết nối, nhóm chat với phụ huynh và tư vấn viên sẽ mở ngay.')
                            : isApprovedPendingActivation
                            ? 'Hồ sơ chuyên môn đã được duyệt nhưng đang chờ quản trị viên xác minh (verified) và kích hoạt (active) trước khi mở khu vực gia sư.'
                            : switch (effectiveStatus) {
                                'needs_info' => 'Hồ sơ chưa được duyệt và chưa hiển thị cho phụ huynh. Vui lòng bổ sung theo hướng dẫn bên dưới.',
                                'rejected' => 'Hồ sơ không đáp ứng tiêu chí kiểm duyệt hiện tại và chưa hiển thị cho phụ huynh.',
                                _ => 'BeeWise kiểm tra hồ sơ trong 1-2 ngày làm việc. Trong thời gian này, hồ sơ chưa hiển thị cho phụ huynh.',
                              },
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: BeeWiseColors.muted,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: BeeWiseSpace.x4),

              // 2. CORRECTION / REJECTION REASON BANNER
              if (effectiveStatus == 'needs_info' ||
                  effectiveStatus == 'rejected') ...[
                Container(
                  padding: const EdgeInsets.all(BeeWiseSpace.x4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFE11D48),
                        size: 22,
                      ),
                      const SizedBox(width: BeeWiseSpace.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LÝ DO TỪ BEEWISE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFBE123C),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (appData.rejectionReason != null &&
                                      appData.rejectionReason!
                                          .trim()
                                          .isNotEmpty)
                                  ? appData.rejectionReason!.trim()
                                  : 'Vui lòng kiểm tra và đối chiếu lại thông tin hồ sơ đã gửi.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF881337),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BeeWiseSpace.x4),
              ],

              // 3. NOTICE BANNER: BƯỚC TIẾP THEO
              Container(
                padding: const EdgeInsets.all(BeeWiseSpace.x4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(BeeWiseRadius.card),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isFullyAuthorized
                          ? Icons.chat_bubble_outline_rounded
                          : Icons.info_outline_rounded,
                      size: 20,
                      color: BeeWiseColors.primary,
                    ),
                    const SizedBox(width: BeeWiseSpace.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BƯỚC TIẾP THEO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: BeeWiseColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isFullyAuthorized
                                ? (usesFinalFirestore
                                      ? 'Nhân viên BeeWise sẽ đăng hồ sơ công khai để phụ huynh có thể tìm và kết nối.'
                                      : 'Phụ huynh tìm và kết nối — bạn sẽ nhận thông báo khi có nhóm chat mới.')
                                : isApprovedPendingActivation
                                ? 'Quản trị viên BeeWise hoàn tất kích hoạt verified và active cho tài khoản của bạn.'
                                : switch (effectiveStatus) {
                                    'needs_info' => 'Bạn cập nhật hồ sơ và gửi lại — hồ sơ sẽ quay về trạng thái chờ duyệt.',
                                    'rejected' => 'Liên hệ bộ phận hỗ trợ BeeWise nếu bạn cần giải đáp thêm về kết quả duyệt.',
                                    _ => 'Nhân viên BeeWise duyệt hồ sơ — bạn chưa cần làm gì.',
                                  },
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
              ),
              const SizedBox(height: BeeWiseSpace.x4),

              // 4. SUMMARY CARD: "Hồ sơ đã nộp"
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
                        'Hồ sơ đã nộp',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: BeeWiseSpace.x3),
                      _buildSummaryRow(
                        icon: Icons.calendar_today_outlined,
                        title: 'Ngày nộp',
                        value: dateText,
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      _buildSummaryRow(
                        icon: Icons.school_outlined,
                        title: 'Môn dạy · Khối lớp',
                        value: subjectsAndGrades,
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      _buildSummaryRow(
                        icon: Icons.payments_outlined,
                        title: 'Học phí',
                        value: feeText,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: BeeWiseSpace.x5),

              // 5. ACTIONS MATCHING ROLE AUTHORITY
              if (isFullyAuthorized) ...[
                BeeWiseButton(
                  label: 'Vào trang gia sư',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => context.go('/tutor/home'),
                ),
                const SizedBox(height: BeeWiseSpace.x3),
                BeeWiseButton(
                  label: 'Xem hồ sơ công khai',
                  icon: Icons.person_outline_rounded,
                  secondary: true,
                  onPressed: () => context.go('/tutor/profile'),
                ),
              ] else if (effectiveStatus == 'needs_info') ...[
                BeeWiseButton(
                  label: 'Cập nhật hồ sơ',
                  icon: Icons.edit_outlined,
                  onPressed: () => context.go('/tutor/apply'),
                ),
                const SizedBox(height: BeeWiseSpace.x2),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) context.go('/home');
                    },
                    child: const Text('Đăng xuất'),
                  ),
                ),
              ] else ...[
                BeeWiseButton(
                  label: 'Đăng xuất',
                  secondary: true,
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) context.go('/home');
                  },
                ),
              ],
              const SizedBox(height: BeeWiseSpace.x6),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusPill(
    String status, {
    required bool isFullyAuthorized,
    required bool isApprovedPendingActivation,
  }) {
    final (bg, fg, border, icon, label) = isFullyAuthorized
        ? (
            const Color(0xFFD1FAE5),
            const Color(0xFF065F46),
            const Color(0xFFA7F3D0),
            Icons.check_circle_rounded,
            'Đã được phê duyệt',
          )
        : isApprovedPendingActivation
        ? (
            const Color(0xFFFEF3C7),
            const Color(0xFF92400E),
            const Color(0xFFFDE68A),
            Icons.verified_user_outlined,
            'Đã duyệt — Chờ kích hoạt',
          )
        : switch (status) {
            'needs_info' => (
              const Color(0xFFFEE2E2),
              const Color(0xFF991B1B),
              const Color(0xFFFECDD3),
              Icons.error_outline_rounded,
              'Cần bổ sung',
            ),
            'rejected' => (
              const Color(0xFFFEE2E2),
              const Color(0xFF991B1B),
              const Color(0xFFFECDD3),
              Icons.cancel_outlined,
              'Từ chối duyệt',
            ),
            _ => (
              const Color(0xFFFEF3C7),
              const Color(0xFF92400E),
              const Color(0xFFFDE68A),
              Icons.access_time_rounded,
              'Chờ duyệt',
            ),
          };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(BeeWiseRadius.full),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
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
                fontSize: 14,
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

class AccountRoleCheckScreen extends ConsumerWidget {
  const AccountRoleCheckScreen({super.key, this.webStaff = false});

  final bool webStaff;

  @override
  Widget build(BuildContext context, WidgetRef ref) => BeeWiseScaffold(
    title: 'Kiểm tra tài khoản',
    body: ListView(
      padding: const EdgeInsets.all(BeeWiseSpace.x5),
      children: [
        ErrorStateView(
          message: webStaff
              ? 'Tài khoản nhân viên quản lý BeeWise trên Web Admin. Hãy đăng xuất để dùng tài khoản phụ huynh hoặc gia sư.'
              : 'Chưa xác định được loại tài khoản do kết nối Firebase bị gián đoạn. Kết nối lại rồi thử lại; BeeWise chưa mở các chức năng phụ huynh.',
        ),
        const SizedBox(height: BeeWiseSpace.x3),
        if (!webStaff)
          BeeWiseButton(
            label: 'Thử kiểm tra lại',
            onPressed: () => context.go('/home'),
          ),
        const SizedBox(height: BeeWiseSpace.x2),
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
  );
}
