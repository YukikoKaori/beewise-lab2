import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

const _kAvailableAreas = [
  'Cầu Giấy',
  'Đống Đa',
  'Ba Đình',
  'Thanh Xuân',
  'Hai Bà Trưng',
  'Hoàn Kiếm',
  'Nam Từ Liêm',
  'Bắc Từ Liêm',
];

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

/// T1: Đăng ký gia sư (Clean & Validation Error states matching Figma T1)
class TutorApplicationScreen extends ConsumerStatefulWidget {
  const TutorApplicationScreen({super.key});

  @override
  ConsumerState<TutorApplicationScreen> createState() =>
      _TutorApplicationScreenState();
}

class _TutorApplicationScreenState
    extends ConsumerState<TutorApplicationScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(text: 'Hoàng Thu Trang');
  final _phone = TextEditingController(text: '0912 345 678');
  final _email = TextEditingController(text: 'trang.hoang@gmail.com');
  final _password = TextEditingController();
  final _qualification = TextEditingController(
    text: 'Thạc sĩ Toán - 5 năm ôn thi vào 10',
  );
  final _introduction = TextEditingController(
    text:
        'Dạy Toán THCS và ôn thi vào 10 trường chuyên. Tập trung lấy lại gốc, '
        'phương pháp giải dễ hiểu; báo tiến độ hàng tuần cho phụ huynh.',
  );
  final _hourlyFee = TextEditingController(text: '250.000');

  final _selectedSubjects = <String>{'Toán', 'Hóa học'};
  final _selectedGrades = <String>{'Lớp 9', 'Ôn thi vào 10'};
  final _selectedAreas = <String>{'Cầu Giấy', 'Đống Đa'};
  final _selectedTimes = <String>{'T3 tối', 'T5 tối', 'T7 tối'};
  final _selectedModes = <String>{'Trực tiếp', 'Trực tuyến'};

  bool _consent = true;
  bool _showPassword = false;
  bool _hasAttemptedSubmit = false;

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

  int _countErrors() {
    int errors = 0;
    if (_name.text.trim().length < 2) errors++;
    final cleanPhone = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length < 10) errors++;
    if (!_email.text.contains('@')) errors++;
    if (_password.text.isNotEmpty && _password.text.length < 6) errors++;
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
    final state = ref.watch(tutorApplicationControllerProvider);
    ref.listen(tutorApplicationControllerProvider, (_, next) {
      if (next.hasValue && !next.isLoading && mounted) {
        context.go('/tutor/pending');
      }
    });

    final errorCount = _hasAttemptedSubmit ? _countErrors() : 0;
    final hasErrors = _hasAttemptedSubmit && errorCount > 0;

    return BeeWiseScaffold(
      title: 'Đăng ký gia sư',
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
            // Top Banner: Title & Description
            Text(
              'Trở thành gia sư BeeWise',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: BeeWiseColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: BeeWiseSpace.x1),
            Text(
              'Hồ sơ gồm 3 phần, mất khoảng 5 phút. Bạn chỉ cần làm 1 lần duy nhất.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: BeeWiseColors.muted),
            ),
            const SizedBox(height: BeeWiseSpace.x4),

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
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Email chưa hợp lệ'
                      : null,
                ),
                const SizedBox(height: BeeWiseSpace.x3),
                TextFormField(
                  controller: _password,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    hintText: 'Tối thiểu 6 ký tự',
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
                ),
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
                        color: _hasAttemptedSubmit && _selectedSubjects.isEmpty
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
                  Row(
                    children: const [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: BeeWiseColors.error,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Chưa chọn môn dạy',
                        style: TextStyle(
                          color: BeeWiseColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
                        color: _hasAttemptedSubmit && _selectedGrades.isEmpty
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
                    hintText: 'Dạy Toán THCS và ôn thi vào 10 trường chuyên...',
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
                  Row(
                    children: const [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: BeeWiseColors.error,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Giới thiệu cần ít nhất 20 ký tự',
                        style: TextStyle(
                          color: BeeWiseColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
                  children: _kAvailableAreas
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
                      onChanged: (v) => setState(() => _consent = v ?? false),
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
              ErrorStateView(message: state.error.toString()),
              const SizedBox(height: BeeWiseSpace.x3),
            ],

            // Submit Button
            BeeWiseButton(
              label: 'Gửi hồ sơ',
              loading: state.isLoading,
              onPressed: state.isLoading ? null : _submit,
            ),
            const SizedBox(height: BeeWiseSpace.x2),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Bạn là phụ huynh? Tạo tài khoản phụ huynh'),
            ),
            if (!ref.watch(firebaseReadyProvider)) const FirebaseSetupNotice(),
            const SizedBox(height: BeeWiseSpace.x6),
          ],
        ),
      ),
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
  }) => TextFormField(
    controller: controller,
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

  void _submit() {
    setState(() => _hasAttemptedSubmit = true);
    final valid = _form.currentState!.validate();
    if (!valid ||
        _selectedSubjects.isEmpty ||
        _selectedGrades.isEmpty ||
        _selectedAreas.isEmpty ||
        _selectedTimes.isEmpty ||
        _selectedModes.isEmpty ||
        !_consent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng hoàn thành các mục hợp lệ trước khi gửi.'),
        ),
      );
      return;
    }

    final fee =
        int.tryParse(_hourlyFee.text.replaceAll('.', '').trim()) ?? 250000;
    final modes = _selectedModes
        .map((m) => m == 'Trực tuyến' ? 'online' : 'in_person')
        .toList(growable: false);

    ref
        .read(tutorApplicationControllerProvider.notifier)
        .submit(
          name: _name.text,
          phone: _phone.text,
          email: _email.text,
          password: _password.text.isEmpty ? 'TemporaryPass1' : _password.text,
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
/// Supports 3 states: Pending, Approved, Needs Info / Correction
class TutorApplicationStatusScreen extends ConsumerWidget {
  const TutorApplicationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) {
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
      showBack: liveStatus == 'approved',
      body: appDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(BeeWiseSpace.x5),
          children: [
            ErrorStateView(
              message: error.toString(),
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
          final effectiveStatus = liveStatus ?? appData?.status ?? 'pending';
          final name = appData?.name.isNotEmpty == true
              ? appData!.name
              : (user.displayName ?? 'cô Trang');
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

          final feeText = appData != null && appData.hourlyFee > 0
              ? '${NumberFormat.decimalPattern('vi_VN').format(appData.hourlyFee)}đ/giờ'
              : '250.000đ/giờ';

          final dateText = appData?.createdAt != null
              ? DateFormat('dd/MM/yyyy').format(appData!.createdAt!)
              : '05/11/2026';

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
                      // Sticker
                      switch (effectiveStatus) {
                        'approved' => const BeeSticker.cheer(size: 100),
                        'needs_info' ||
                        'rejected' => const BeeSticker.wand(size: 100),
                        _ => const BeeSticker.robot(size: 100),
                      },
                      const SizedBox(height: BeeWiseSpace.x3),

                      // Status Badge Pill
                      _buildStatusPill(effectiveStatus),
                      const SizedBox(height: BeeWiseSpace.x3),

                      // Heading
                      Text(
                        switch (effectiveStatus) {
                          'approved' => 'Chào mừng $name!',
                          'needs_info' || 'rejected' => 'Hồ sơ cần bổ sung',
                          _ => 'Hồ sơ đang chờ duyệt',
                        },
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: BeeWiseSpace.x2),

                      // Subtitle
                      Text(
                        switch (effectiveStatus) {
                          'approved' => 'Hồ sơ đã hiển thị trong tìm kiếm. Khi phụ huynh gửi yêu cầu kết nối, nhóm chat với phụ huynh và tư vấn viên sẽ mở ngay.',
                          'needs_info' || 'rejected' => 'Hồ sơ chưa được duyệt và chưa hiển thị cho phụ huynh.',
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

              // 2. CORRECTION REASON BANNER (for needs_info / rejected)
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
                              appData?.rejectionReason ?? 'Phần giới thiệu chưa nêu rõ kinh nghiệm ôn thi vào 10. Vui lòng bổ sung số năm và kết quả học sinh từng đạt.',
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
                      switch (effectiveStatus) {
                        'approved' => Icons.chat_bubble_outline_rounded,
                        _ => Icons.info_outline_rounded,
                      },
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
                            switch (effectiveStatus) {
                              'approved' => 'Phụ huynh tìm và kết nối — bạn sẽ nhận thông báo khi có nhóm chat mới.',
                              'needs_info' || 'rejected' => 'Bạn cập nhật hồ sơ và gửi lại — hồ sơ sẽ quay về trạng thái chờ duyệt.',
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

              // 5. ACTIONS MATCHING FIGMA
              ...switch (effectiveStatus) {
                'approved' => [
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
                ],
                'needs_info' || 'rejected' => [
                  BeeWiseButton(
                    label: 'Cập nhật hồ sơ',
                    icon: Icons.edit_outlined,
                    onPressed: () => context.go('/tutor/apply'),
                  ),
                  const SizedBox(height: BeeWiseSpace.x2),
                  Center(
                    child: TextButton(
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Vui lòng liên hệ hotline BeeWise 1900-xxxx để được hỗ trợ trực tiếp.',
                              ),
                            ),
                          ),
                      child: const Text('Liên hệ hỗ trợ khác'),
                    ),
                  ),
                ],
                _ => [
                  BeeWiseButton(
                    label: 'Xem lại hồ sơ đã nộp',
                    icon: Icons.visibility_outlined,
                    secondary: true,
                    onPressed: () => context.go('/tutor/profile'),
                  ),
                  const SizedBox(height: BeeWiseSpace.x2),
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .signOut();
                        if (context.mounted) context.go('/home');
                      },
                      child: const Text('Đăng xuất'),
                    ),
                  ),
                ],
              },
              const SizedBox(height: BeeWiseSpace.x6),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    final (bg, fg, border, icon, label) = switch (status) {
      'approved' => (
        const Color(0xFFD1FAE5),
        const Color(0xFF065F46),
        const Color(0xFFA7F3D0),
        Icons.check_circle_rounded,
        'Đã được phê duyệt',
      ),
      'needs_info' || 'rejected' => (
        const Color(0xFFFEE2E2),
        const Color(0xFF991B1B),
        const Color(0xFFFECDD3),
        Icons.error_outline_rounded,
        'Cần bổ sung',
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
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w700,
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
  const AccountRoleCheckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => BeeWiseScaffold(
    title: 'Kiểm tra tài khoản',
    body: ListView(
      padding: const EdgeInsets.all(BeeWiseSpace.x5),
      children: [
        const ErrorStateView(
          message: 'Chưa xác định được loại tài khoản do kết nối Firebase bị gián đoạn. Kết nối lại rồi thử lại; BeeWise chưa mở các chức năng phụ huynh.',
        ),
        const SizedBox(height: BeeWiseSpace.x3),
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
