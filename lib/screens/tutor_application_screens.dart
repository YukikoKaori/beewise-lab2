import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/bee_wise_theme.dart';
import '../viewmodels/app_providers.dart';
import '../viewmodels/controllers.dart';
import '../widgets/bee_wise_widgets.dart';

class TutorApplicationScreen extends ConsumerStatefulWidget {
  const TutorApplicationScreen({super.key});

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
  final _subjects = TextEditingController();
  final _grades = TextEditingController();
  final _hourlyFee = TextEditingController();
  final _areas = TextEditingController();
  final _availability = TextEditingController();
  final _modes = <String>{};
  bool _consent = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _qualification.dispose();
    _introduction.dispose();
    _subjects.dispose();
    _grades.dispose();
    _hourlyFee.dispose();
    _areas.dispose();
    _availability.dispose();
    super.dispose();
  }

  List<String> _commaSeparated(TextEditingController controller) => controller
      .text
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList(growable: false);

  String? _listRequired(String? value, {required int maximum}) {
    final count = (value ?? '')
        .split(',')
        .where((item) => item.trim().isNotEmpty)
        .length;
    if (count == 0) return 'Nhập ít nhất một mục, cách nhau bằng dấu phẩy.';
    if (count > maximum) return 'Chỉ nhập tối đa $maximum mục.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorApplicationControllerProvider);
    ref.listen(tutorApplicationControllerProvider, (_, next) {
      if (next.hasValue && !next.isLoading && mounted) {
        context.go('/tutor/pending');
      }
    });
    return BeeWiseScaffold(
      title: 'Đăng ký gia sư',
      showBack: true,
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(BeeWiseSpace.x5),
          children: [
            Text(
              'Gửi hồ sơ gia sư',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: BeeWiseSpace.x2),
            Text(
              'BeeWise sẽ xem xét hồ sơ trước khi giới thiệu bạn tới phụ huynh. '
              'Tài khoản mới chưa được hiển thị trong kết quả tìm kiếm.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: BeeWiseSpace.x5),
            _textField(
              controller: _name,
              label: 'Họ và tên',
              validator: (value) =>
                  value == null ||
                      value.trim().length < 2 ||
                      value.trim().length > 100
                  ? 'Tên cần có từ 2 đến 100 ký tự.'
                  : null,
              capitalization: TextCapitalization.words,
            ),
            _gap,
            _textField(
              controller: _phone,
              label: 'Số điện thoại',
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value == null ||
                      value.trim().length < 9 ||
                      value.trim().length > 20
                  ? 'Nhập số điện thoại hợp lệ.'
                  : null,
            ),
            _gap,
            _textField(
              controller: _email,
              label: 'Email đăng nhập',
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || !value.contains('@')
                  ? 'Nhập email hợp lệ.'
                  : null,
            ),
            _gap,
            TextFormField(
              controller: _password,
              obscureText: !_showPassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                helperText: 'Ít nhất 8 ký tự và có một chữ số.',
                suffixIcon: IconButton(
                  tooltip: _showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              validator: (value) =>
                  value == null ||
                      value.length < 8 ||
                      !RegExp(r'\d').hasMatch(value)
                  ? 'Mật khẩu cần ít nhất 8 ký tự và một chữ số.'
                  : null,
            ),
            _gap,
            _textField(
              controller: _qualification,
              label: 'Bằng cấp hoặc kinh nghiệm liên quan',
              validator: (value) =>
                  value == null ||
                      value.trim().length < 2 ||
                      value.trim().length > 300
                  ? 'Nhập bằng cấp/kinh nghiệm từ 2 đến 300 ký tự.'
                  : null,
            ),
            _gap,
            _textField(
              controller: _subjects,
              label: 'Môn có thể dạy',
              hint: 'Ví dụ: Toán, Vật lý, Tiếng Anh',
              validator: (value) => _listRequired(value, maximum: 10),
            ),
            _gap,
            _textField(
              controller: _grades,
              label: 'Khối lớp có thể dạy',
              hint: 'Ví dụ: Lớp 6, Lớp 7, Lớp 10',
              validator: (value) => _listRequired(value, maximum: 12),
            ),
            _gap,
            _textField(
              controller: _introduction,
              label: 'Giới thiệu kinh nghiệm giảng dạy',
              minLines: 3,
              maxLines: 5,
              validator: (value) =>
                  value == null ||
                      value.trim().length < 20 ||
                      value.trim().length > 1000
                  ? 'Giới thiệu cần từ 20 đến 1000 ký tự.'
                  : null,
            ),
            _gap,
            _textField(
              controller: _hourlyFee,
              label: 'Học phí dự kiến mỗi giờ (VNĐ)',
              keyboardType: TextInputType.number,
              validator: (value) {
                final fee = int.tryParse(
                  (value ?? '').replaceAll('.', '').trim(),
                );
                return fee == null || fee <= 0
                    ? 'Nhập học phí lớn hơn 0.'
                    : null;
              },
            ),
            _gap,
            _textField(
              controller: _areas,
              label: 'Khu vực có thể dạy',
              hint: 'Ví dụ: Quận 1, Quận 3, dạy trực tuyến',
              validator: (value) => _listRequired(value, maximum: 10),
            ),
            _gap,
            _textField(
              controller: _availability,
              label: 'Thời gian có thể dạy',
              hint: 'Ví dụ: Các tối trong tuần, cuối tuần',
              validator: (value) =>
                  value == null ||
                      value.trim().length < 2 ||
                      value.trim().length > 500
                  ? 'Nhập thời gian từ 2 đến 500 ký tự.'
                  : null,
            ),
            const SizedBox(height: BeeWiseSpace.x3),
            Text(
              'Hình thức dạy',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Wrap(
              spacing: BeeWiseSpace.x2,
              children: [
                _modeChip('Trực tuyến', 'online'),
                _modeChip('Trực tiếp', 'in_person'),
              ],
            ),
            if (_modes.isEmpty)
              Text(
                'Chọn ít nhất một hình thức dạy.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: BeeWiseSpace.x2),
            const Text(
              'Trong bản MVP này chưa nhận tệp giấy tờ. Không nhập số CCCD '
              'hoặc thông tin nhạy cảm vào phần giới thiệu.',
            ),
            CheckboxListTile(
              value: _consent,
              onChanged: (value) => setState(() => _consent = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Tôi đồng ý gửi thông tin trên để BeeWise xem xét hồ sơ gia sư.',
              ),
            ),
            if (state.hasError) ErrorStateView(message: state.error.toString()),
            BeeWiseButton(
              label: 'Gửi hồ sơ chờ duyệt',
              loading: state.isLoading,
              onPressed: state.isLoading ? null : _submit,
            ),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Bạn là phụ huynh? Tạo tài khoản phụ huynh'),
            ),
            if (!ref.watch(firebaseReadyProvider)) const FirebaseSetupNotice(),
          ],
        ),
      ),
    );
  }

  Widget _modeChip(String label, String value) => FilterChip(
    label: Text(label),
    selected: _modes.contains(value),
    onSelected: (selected) => setState(() {
      if (selected) {
        _modes.add(value);
      } else {
        _modes.remove(value);
      }
    }),
  );

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.sentences,
    int minLines = 1,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: BeeWiseSpace.x2),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
    ),
  );

  static const _gap = SizedBox(height: BeeWiseSpace.x2);

  void _submit() {
    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đồng ý trước khi gửi hồ sơ.')),
      );
      return;
    }
    if (_modes.isEmpty) {
      setState(() {});
      return;
    }
    if (!_form.currentState!.validate()) return;
    final fee = int.parse(_hourlyFee.text.replaceAll('.', '').trim());
    ref
        .read(tutorApplicationControllerProvider.notifier)
        .submit(
          name: _name.text,
          phone: _phone.text,
          email: _email.text,
          password: _password.text,
          qualification: _qualification.text,
          introduction: _introduction.text,
          subjects: _commaSeparated(_subjects),
          grades: _commaSeparated(_grades),
          hourlyFee: fee,
          areas: _commaSeparated(_areas),
          teachingModes: _modes.toList(growable: false),
          availability: _availability.text,
        );
  }
}

class TutorApplicationStatusScreen extends ConsumerWidget {
  const TutorApplicationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) {
      return BeeWiseScaffold(
        title: 'Trạng thái hồ sơ',
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
    final status = ref.watch(tutorApplicationStatusProvider(user.uid));
    return BeeWiseScaffold(
      title: 'Hồ sơ gia sư',
      body: status.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(BeeWiseSpace.x5),
          children: [
            ErrorStateView(
              message: error.toString(),
              onRetry: () =>
                  ref.invalidate(tutorApplicationStatusProvider(user.uid)),
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
        data: (value) => ListView(
          padding: const EdgeInsets.all(BeeWiseSpace.x5),
          children: [
            Icon(
              value == 'pending' ? Icons.hourglass_top_rounded : Icons.info,
              size: 56,
              color: BeeWiseColors.primary,
            ),
            const SizedBox(height: BeeWiseSpace.x3),
            Text(
              value == 'pending'
                  ? 'Hồ sơ đang chờ duyệt'
                  : 'Hồ sơ đã được cập nhật',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BeeWiseSpace.x2),
            Text(
              value == 'pending'
                  ? 'BeeWise đã nhận hồ sơ. Hồ sơ chưa được xác minh và chưa hiển thị cho phụ huynh. Chỉ nhân viên hoặc backend được phép duyệt và kích hoạt hồ sơ.'
                  : 'Trạng thái hiện tại: $value. Liên hệ BeeWise để biết bước tiếp theo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BeeWiseSpace.x5),
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
      ),
    );
  }
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
