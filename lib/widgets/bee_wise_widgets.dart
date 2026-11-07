import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/tutor.dart';
import '../theme/bee_wise_theme.dart';

class BeeWiseScaffold extends StatelessWidget {
  const BeeWiseScaffold({
    super.key,
    required this.title,
    required this.body,
    this.titleWidget,
    this.showBack = false,
    this.bottomNavigationIndex,
    this.actions = const [],
    this.bottom,
    this.floatingActionButton,
  });

  final String title;

  /// Replaces the plain-text title (e.g. the BeeWise logo lockup on Home).
  /// [title] is still used as the accessible label.
  final Widget? titleWidget;
  final Widget body;
  final bool showBack;
  final int? bottomNavigationIndex;
  final List<Widget> actions;
  final Widget? bottom;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              tooltip: 'Quay lại',
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            )
          : null,
      title: titleWidget == null
          ? Text(title)
          : Semantics(label: title, header: true, child: titleWidget),
      toolbarHeight: titleWidget == null ? null : 64,
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: BeeWiseColors.border),
      ),
    ),
    body: SafeArea(top: false, child: body),
    bottomNavigationBar: bottomNavigationIndex == null
        ? bottom
        : BeeWiseBottomNavigation(selectedIndex: bottomNavigationIndex!),
    floatingActionButton: floatingActionButton,
  );
}

class BeeWiseBottomNavigation extends StatelessWidget {
  const BeeWiseBottomNavigation({super.key, required this.selectedIndex});
  final int selectedIndex;

  static const _routes = [
    '/home',
    '/search',
    '/matching',
    '/messages',
    '/profile',
  ];

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: (index) => context.go(_routes[index]),
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Trang chủ',
      ),
      NavigationDestination(
        icon: Icon(Icons.search_rounded),
        label: 'Tìm gia sư',
      ),
      NavigationDestination(
        icon: Icon(Icons.auto_awesome_outlined),
        selectedIcon: Icon(Icons.auto_awesome_rounded),
        label: 'Ghép AI',
      ),
      NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline_rounded),
        selectedIcon: Icon(Icons.chat_bubble_rounded),
        label: 'Tin nhắn',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Tài khoản',
      ),
    ],
  );
}

class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(16),
  });
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: padding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _withGaps(children),
    ),
  );

  List<Widget> _withGaps(List<Widget> items) {
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) result.add(const SizedBox(height: BeeWiseSpace.x4));
      result.add(items[i]);
    }
    return result;
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: BeeWiseSpace.x4,
      bottom: BeeWiseSpace.x2,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
        ?trailing,
      ],
    ),
  );
}

class BeeWiseButton extends StatelessWidget {
  const BeeWiseButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.secondary = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool secondary;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );
    final button = secondary
        ? OutlinedButton(onPressed: loading ? null : onPressed, child: child)
        : FilledButton(onPressed: loading ? null : onPressed, child: child);
    return Semantics(
      container: true,
      button: true,
      onTap: onPressed,
      enabled: !loading && onPressed != null,
      label: label,
      excludeSemantics: true,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.kind = NoticeKind.info,
    this.action,
  });
  final String message;
  final NoticeKind kind;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (color, background, icon) = switch (kind) {
      NoticeKind.success => (
        BeeWiseColors.success,
        BeeWiseColors.successSoft,
        Icons.check_circle_outline,
      ),
      NoticeKind.warning => (
        BeeWiseColors.warning,
        BeeWiseColors.accentSoft,
        Icons.warning_amber_rounded,
      ),
      NoticeKind.error => (
        BeeWiseColors.error,
        BeeWiseColors.errorSoft,
        Icons.error_outline,
      ),
      NoticeKind.info => (
        BeeWiseColors.primary,
        const Color(0xFFEEF2FF),
        Icons.info_outline,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(BeeWiseRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: BeeWiseColors.ink),
                ),
                if (action != null) ...[const SizedBox(height: 8), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum NoticeKind { info, success, warning, error }

class LoadingStateView extends StatelessWidget {
  const LoadingStateView({super.key, this.label = 'Đang tải thông tin…'});
  final String label;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}

class OnboardingStepper extends StatelessWidget {
  const OnboardingStepper({
    super.key,
    required this.currentStep,
    int? completedThrough,
  }) : assert(currentStep >= 0 && currentStep < 4),
       assert(
         completedThrough == null ||
             (completedThrough >= -1 && completedThrough < 4),
       ),
       // Unless told otherwise, every step before the current one is done.
       completedThrough = completedThrough ?? currentStep - 1;

  final int currentStep;
  final int completedThrough;

  static const _steps = ['Học thử', 'Xác nhận lớp', 'Thanh toán', 'Lịch học'];

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label:
        'Tiến trình tư vấn, bước ${currentStep + 1} trên ${_steps.length}: ${_steps[currentStep]}',
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 28,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: constraints.maxWidth / _steps.length / 2,
                    right: constraints.maxWidth / _steps.length / 2,
                    child: Row(
                      children: [
                        for (var index = 0; index < _steps.length - 1; index++)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: index <= completedThrough
                                  ? BeeWiseColors.success
                                  : BeeWiseColors.borderStrong,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      for (var index = 0; index < _steps.length; index++)
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: CircleAvatar(
                              radius: 13,
                              backgroundColor: index <= completedThrough
                                  ? BeeWiseColors.success
                                  : index == currentStep
                                  ? BeeWiseColors.primary
                                  : const Color(0xFFE2EAFF),
                              foregroundColor:
                                  index <= completedThrough ||
                                      index == currentStep
                                  ? Colors.white
                                  : BeeWiseColors.muted,
                              child: index <= completedThrough
                                  ? const Icon(Icons.check, size: 16)
                                  : Text('${index + 1}'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final step in _steps)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        step,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: step == _steps[currentStep]
                                  ? BeeWiseColors.primary
                                  : BeeWiseColors.muted,
                              fontWeight: step == _steps[currentStep]
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.search_off_rounded,
    this.action,
    this.sticker,
  });
  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  /// When set, replaces [icon] with a BeeWise mascot illustration.
  final BeeSticker? sticker;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: BeeWiseColors.surface,
      borderRadius: BorderRadius.circular(BeeWiseRadius.card),
      border: Border.all(color: BeeWiseColors.border),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        sticker ?? Icon(icon, size: 36, color: BeeWiseColors.muted),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => StatusBanner(
    message: message,
    kind: NoticeKind.error,
    action: onRetry == null
        ? null
        : TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
  );
}

class FirebaseSetupNotice extends StatelessWidget {
  const FirebaseSetupNotice({super.key});
  @override
  Widget build(BuildContext context) => const StatusBanner(
    kind: NoticeKind.warning,
    message: 'Ứng dụng chưa kết nối Firebase. Hãy tạo Firebase project, chạy flutterfire configure và bật các dịch vụ trong README để tải dữ liệu thật.',
  );
}

/// Human-readable label for the stored teaching-mode codes.
String teachingModeLabel(String value) => switch (value) {
  'in_person' => 'Trực tiếp',
  'online' => 'Online',
  _ => value,
};

class TutorAvatar extends StatelessWidget {
  const TutorAvatar({super.key, required this.tutor, this.radius = 28});
  final Tutor tutor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = tutor.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: BeeWiseColors.highlight,
      foregroundImage: image == null || image.isEmpty
          ? null
          : NetworkImage(image),
      onForegroundImageError: image == null || image.isEmpty
          ? null
          : (_, _) {},
      child: image == null || image.isEmpty
          ? Text(
              _initials(tutor.name),
              style: Theme.of(context).textTheme.titleLarge,
            )
          : null,
    );
  }

  String _initials(String name) {
    final cleaned = name.replaceAll(RegExp(r'\[[^\]]*\]'), ' ');
    final parts = cleaned
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => RegExp(r'^\p{L}', unicode: true).hasMatch(part))
        .toList();
    if (parts.isEmpty) return 'G';
    return parts.length == 1
        ? parts.first.characters.first.toUpperCase()
        : '${parts.first.characters.first}${parts.last.characters.first}'
              .toUpperCase();
  }
}

class TutorCard extends StatelessWidget {
  const TutorCard({
    super.key,
    required this.tutor,
    required this.onOpen,
    this.actionLabel = 'Xem hồ sơ',
    this.subtitle,
  });
  final Tutor tutor;
  final VoidCallback onOpen;
  final String actionLabel;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final fee = NumberFormat.decimalPattern('vi_VN').format(tutor.hourlyFee);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TutorAvatar(tutor: tutor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tutor.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (tutor.verified)
                            const Icon(
                              Icons.verified,
                              color: BeeWiseColors.success,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (tutor.isDemoProfile) const Text(Tutor.demoDisclosure),
                      if ((subtitle ?? tutor.credential).isNotEmpty)
                        Text(
                          subtitle ?? tutor.credential,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: BeeWiseColors.muted),
                        ),
                      if (tutor.rating != null) ...[
                        const SizedBox(height: 6),
                        _RatingChip(
                          rating: tutor.rating!,
                          count: tutor.reviewCount,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (tutor.subjects.isNotEmpty)
                  _MetaChip(
                    icon: Icons.school_outlined,
                    label: tutor.subjects.take(2).join(' · '),
                  ),
                if (tutor.areas.isNotEmpty)
                  _MetaChip(
                    icon: Icons.location_on_outlined,
                    label: tutor.areas.take(2).join(' · '),
                  ),
                if (tutor.teachingModes.isNotEmpty)
                  _MetaChip(
                    icon: Icons.cast_for_education_outlined,
                    label: teachingModeLabel(tutor.teachingModes.first),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Học phí',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '$feeđ/giờ',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(color: BeeWiseColors.primary),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: '$actionLabel: ${tutor.name}',
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 148),
                    child: FilledButton(
                      onPressed: onOpen,
                      child: Text(actionLabel),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating, required this.count});
  final double rating;
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: BeeWiseColors.accentSoft,
      borderRadius: BorderRadius.circular(BeeWiseRadius.full),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: BeeWiseColors.warning, size: 17),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Text(
          ' ($count)',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: BeeWiseColors.muted),
        ),
      ],
    ),
  );
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, color: BeeWiseColors.primary, size: 18),
    label: Text(label),
    backgroundColor: const Color(0xFFEEF2FF),
    side: BorderSide.none,
    visualDensity: VisualDensity.compact,
  );
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });
  final String label;
  final String value;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (icon != null) ...[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(BeeWiseRadius.md),
          ),
          child: Icon(icon, color: BeeWiseColors.ink, size: 22),
        ),
        const SizedBox(width: 14),
      ],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: BeeWiseColors.muted),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ],
  );
}

class LoadingTutorList extends StatelessWidget {
  const LoadingTutorList({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < 3; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 112),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(BeeWiseRadius.card),
            ),
            child: const Center(child: LinearProgressIndicator()),
          ),
        ),
    ],
  );
}

/// Label + wrapped chips used by filter groups so rows keep even spacing.
class FilterGroup extends StatelessWidget {
  const FilterGroup({
    super.key,
    required this.label,
    required this.chips,
    this.columns = 3,
  });
  final String label;
  final List<Widget> chips;

  /// Chips share the row equally, so every pill has the same width/height
  /// and nothing is left alone on a second line.
  final int columns;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: BeeWiseSpace.x2),
      LayoutBuilder(
        builder: (context, constraints) {
          const gap = BeeWiseSpace.x2;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final chip in chips) SizedBox(width: width, child: chip),
            ],
          );
        },
      ),
    ],
  );
}

/// Inserts an even vertical gap between widgets that are not already
/// separated by an explicit [SizedBox].
List<Widget> withGaps(List<Widget> items, {double gap = BeeWiseSpace.x3}) {
  final result = <Widget>[];
  for (final item in items) {
    if (result.isNotEmpty && item is! SizedBox && result.last is! SizedBox) {
      result.add(SizedBox(height: gap));
    }
    result.add(item);
  }
  return result;
}

/// BeeWise horizontal logo lockup (mark + wordmark), transparent background.
class BeeWiseLogo extends StatelessWidget {
  const BeeWiseLogo({super.key, this.height = 32});
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'BeeWise',
    image: true,
    child: ExcludeSemantics(
      child: Image.asset(
        'assets/brand/logo-horizontal.png',
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    ),
  );
}

/// BeeWise mascot illustrations (assets/stickers/). Decorative only.
class BeeSticker extends StatelessWidget {
  const BeeSticker._(this._asset, this.size);

  /// Bee holding a heart wand — AI matching / highlights.
  const BeeSticker.wand({double size = 96}) : this._('bee-wand', size);

  /// Cheering bee — success and welcome states.
  const BeeSticker.cheer({double size = 96}) : this._('bee-cheer', size);

  /// Bee and robot bee fist-bumping — AI + tutor collaboration, empty states.
  const BeeSticker.robot({double size = 120}) : this._('bee-robot', size);

  final String _asset;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/stickers/$_asset.png',
      width: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    ),
  );
}

/// Google "G" mark used on the sign-in button (assets/brand/google-g.webp).
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: Image.asset(
        'assets/brand/google-g.webp',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    ),
  );
}

/// White rounded card with an icon + title header. Used to group related
/// content so sections read as separate blocks instead of loose text.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.subtitle,
    this.trailing,
    this.leading,
  });
  final Widget? trailing;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          fillColor: BeeWiseColors.canvas,
        ),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(BeeWiseSpace.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: BeeWiseSpace.x3),
                  ] else if (icon != null) ...[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 20, color: BeeWiseColors.primary),
                    ),
                    const SizedBox(width: BeeWiseSpace.x3),
                  ],
                  Expanded(
                    child: Text(title, style: theme.textTheme.headlineSmall),
                  ),
                  ?trailing,
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: BeeWiseSpace.x1),
                Text(subtitle!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: BeeWiseSpace.x3),
              ...withGaps(children, gap: BeeWiseSpace.x3),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width selectable pill used inside [FilterGroup]. Fixed height so every
/// option lines up; the selected state uses the brand yellow.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    excludeSemantics: true,
    child: Material(
      color: selected ? BeeWiseColors.highlight : BeeWiseColors.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? BeeWiseColors.accent : BeeWiseColors.borderStrong,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
      ),
    ),
  );
}
