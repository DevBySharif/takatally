import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';

class TakaLogo extends StatelessWidget {
  const TakaLogo({
    super.key,
    this.size = 44,
    this.showWordmark = true,
    this.light = false,
  });

  final double size;
  final bool showWordmark;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: light ? p.surface : p.forest,
            borderRadius: BorderRadius.circular(size * 0.31),
            boxShadow: [
              BoxShadow(
                color: p.forestDeep.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size * 0.58,
                height: size * 0.58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: p.lime, width: size * 0.042),
                ),
              ),
              Text(
                '৳',
                style: TextStyle(
                  fontFamily: 'NotoSansBengali',
                  fontSize: size * 0.34,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: light ? p.forest : p.lime,
                ),
              ),
            ],
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Taka Counter',
                style: context.texts.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: light ? Colors.white : p.ink,
                ),
              ),
              Text(
                'CASH, MADE CLEAR',
                style: context.texts.labelSmall?.copyWith(
                  fontSize: 8.5,
                  letterSpacing: 1.7,
                  color: light
                      ? Colors.white.withValues(alpha: 0.58)
                      : p.inkSoft,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class PageBackground extends StatelessWidget {
  const PageBackground({
    super.key,
    required this.child,
    this.safeTop = true,
    this.safeBottom = true,
    this.maxWidth = 480,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final bool safeTop;
  final bool safeBottom;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.background,
            p.background,
            Color.lerp(p.background, p.limeSoft, p.isDark ? 0.12 : 0.28)!,
          ],
          stops: const [0, 0.62, 1],
        ),
      ),
      child: SafeArea(
        top: safeTop,
        bottom: safeBottom,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.975,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final BorderRadius? borderRadius;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderColor,
    this.radius = 24,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? p.line),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: p.shadow,
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap == null && onLongPress == null) return content;
    return PressableScale(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(radius),
      child: content,
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.background,
    this.color,
    this.size = 46,
    this.iconSize = 21,
    this.radius = 15,
    this.border,
  });

  final IconData icon;
  final Color? background;
  final Color? color;
  final double size;
  final double iconSize;
  final double radius;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? p.surfaceMuted,
        borderRadius: BorderRadius.circular(radius),
        border: border == null ? null : Border.all(color: border!),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: color ?? p.ink),
    );
  }
}

class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    this.icon,
    this.background,
    this.foreground,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.border,
    this.fontSize = 10.5,
  });

  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;
  final EdgeInsets padding;
  final Color? border;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    final fg = foreground ?? p.inkSoft;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? p.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: context.texts.labelMedium?.copyWith(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(2, 0, 2, 12),
  });

  final String title;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.background,
    this.color,
    this.size = 44,
    this.border = true,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? background;
  final Color? color;
  final double size;
  final bool border;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    final button = PressableScale(
      onTap: onTap,
      scale: 0.92,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? p.surface,
          shape: BoxShape.circle,
          border: border ? Border.all(color: p.line) : null,
          boxShadow: [
            BoxShadow(
              color: p.shadow,
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: size * 0.44, color: color ?? p.ink),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.background,
    this.foreground,
    this.expanded = true,
    this.height = 54,
    this.enabled = true,
    this.trailing,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? background;
  final Color? foreground;
  final bool expanded;
  final double height;
  final bool enabled;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    final child = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: enabled ? (background ?? p.forest) : p.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: (background ?? p.forest).withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 19,
              color: enabled
                  ? (foreground ?? (p.isDark ? p.ink : Colors.white))
                  : p.inkSoft,
            ),
            const SizedBox(width: 9),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.texts.labelLarge?.copyWith(
                color: enabled
                    ? (foreground ?? (p.isDark ? p.ink : Colors.white))
                    : p.inkSoft,
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
            ),
          ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );

    final button = PressableScale(
      onTap: enabled ? onTap : null,
      scale: 0.97,
      child: child,
    );

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.expanded = false,
    this.height = 48,
    this.foreground,
    this.background,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool expanded;
  final double height;
  final Color? foreground;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    final button = PressableScale(
      onTap: onTap,
      scale: 0.97,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: background ?? Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.line),
        ),
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: foreground ?? p.ink),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: context.texts.labelLarge?.copyWith(
                color: foreground ?? p.ink,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class MoneyText extends StatelessWidget {
  const MoneyText({
    super.key,
    required this.amount,
    this.style,
    this.symbolStyle,
    this.symbol = '৳',
    this.signed = false,
    this.maxLines = 1,
  });

  final int amount;
  final TextStyle? style;
  final TextStyle? symbolStyle;
  final String symbol;
  final bool signed;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final sign = signed
        ? amount > 0
              ? '+'
              : amount < 0
              ? '−'
              : ''
        : amount < 0
        ? '−'
        : '';
    final baseStyle =
        style ??
        context.texts.displaySmall!.copyWith(fontWeight: FontWeight.w800);
    final sStyle =
        (symbolStyle ??
                baseStyle.copyWith(
                  fontSize: (baseStyle.fontSize ?? 32) * 0.62,
                  fontWeight: FontWeight.w700,
                ))
            .copyWith(fontFamily: 'NotoSansBengali');
    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          if (sign.isNotEmpty) TextSpan(text: sign, style: baseStyle),
          TextSpan(text: symbol, style: sStyle),
          TextSpan(text: formatNumber(amount.abs()), style: baseStyle),
        ],
        style: baseStyle,
      ),
    );
  }
}

class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({
    super.key,
    required this.amount,
    this.style,
    this.symbolStyle,
    this.symbol = '৳',
    this.duration = const Duration(milliseconds: 650),
  });

  final int amount;
  final TextStyle? style;
  final TextStyle? symbolStyle;
  final String symbol;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amount.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => MoneyText(
        amount: value.round(),
        style: style,
        symbolStyle: symbolStyle,
        symbol: symbol,
      ),
    );
  }
}

class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.offset = const Offset(0, 18),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _slide = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(curve);
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: compact ? 28 : 44,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 66 : 80,
            height: compact ? 66 : 80,
            decoration: BoxDecoration(
              color: p.limeSoft,
              shape: BoxShape.circle,
              border: Border.all(color: p.lime.withValues(alpha: 0.5)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: compact ? 27 : 33, color: p.accent),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.texts.titleLarge,
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.texts.bodyMedium?.copyWith(
              color: p.inkSoft,
              height: 1.5,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 18),
            PrimaryButton(
              label: actionLabel!,
              onTap: onAction,
              expanded: false,
              height: 46,
              icon: Icons.add_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class TakaDivider extends StatelessWidget {
  const TakaDivider({super.key, this.height = 1, this.indent = 0});

  final double height;
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: 1,
      indent: indent,
      color: context.taka.line,
    );
  }
}

class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.taka.line,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onClose,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.taka;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.texts.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  style: context.texts.bodySmall?.copyWith(color: p.inkSoft),
                ),
              ],
            ],
          ),
        ),
        if (onClose != null)
          RoundIconButton(
            icon: Icons.close_rounded,
            onTap: onClose,
            size: 38,
            background: p.surfaceMuted,
            border: false,
          ),
      ],
    );
  }
}

class AppSnack {
  const AppSnack._();

  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_outline_rounded,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          action: actionLabel == null
              ? null
              : SnackBarAction(
                  label: actionLabel,
                  textColor: context.taka.lime,
                  onPressed: onAction ?? () {},
                ),
        ),
      );
  }
}

Future<T?> showTakaSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: context.taka.forestDeep.withValues(alpha: 0.5),
    builder: (sheetContext) {
      return AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.92,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: sheetContext.taka.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: SafeArea(top: false, child: builder(sheetContext)),
          ),
        ),
      );
    },
  );
}

Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Keep it',
  IconData icon = Icons.delete_outline_rounded,
  bool destructive = true,
}) async {
  final result = await showTakaSheet<bool>(
    context,
    builder: (sheetContext) {
      final p = sheetContext.taka;
      final accent = destructive ? p.coral : p.accent;
      final soft = destructive ? p.coralSoft : p.limeSoft;
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetGrabber(),
            const SizedBox(height: 26),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(19),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: accent, size: 27),
            ),
            const SizedBox(height: 20),
            Text(title, style: context.texts.headlineSmall),
            const SizedBox(height: 8),
            Text(
              message,
              style: context.texts.bodyMedium?.copyWith(
                color: p.inkSoft,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GhostButton(
                    label: cancelLabel,
                    expanded: true,
                    height: 52,
                    onTap: () => Navigator.of(sheetContext).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: confirmLabel,
                    height: 52,
                    background: destructive ? p.coral : p.forest,
                    foreground: Colors.white,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(sheetContext).pop(true);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  return result ?? false;
}

Future<String?> showRenameDialog(
  BuildContext context, {
  required String initial,
  String title = 'Rename this count',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'e.g. Friday shop collection',
            prefixIcon: Icon(Icons.edit_outlined, size: 20),
          ),
          onSubmitted: (value) {
            final clean = value.trim();
            if (clean.isNotEmpty) Navigator.of(dialogContext).pop(clean);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final clean = controller.text.trim();
              if (clean.isNotEmpty) Navigator.of(dialogContext).pop(clean);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  ).whenComplete(controller.dispose);
}

class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 70),
  });

  final int index;
  final Widget child;
  final Duration step;

  @override
  Widget build(BuildContext context) {
    return Entrance(
      delay: Duration(milliseconds: 80 + (index * step.inMilliseconds)),
      child: child,
    );
  }
}

class DottedPattern extends StatelessWidget {
  const DottedPattern({
    super.key,
    this.color = Colors.white,
    this.opacity = 0.12,
    this.spacing = 18,
    this.dotSize = 2,
  });

  final Color color;
  final double opacity;
  final double spacing;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _DotPainter(
          color: color.withValues(alpha: opacity),
          spacing: spacing,
          dotSize: dotSize,
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  _DotPainter({
    required this.color,
    required this.spacing,
    required this.dotSize,
  });

  final Color color;
  final double spacing;
  final double dotSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = spacing / 2; x < size.width; x += spacing) {
      for (var y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPainter oldDelegate) => false;
}

class RotatedTakaWatermark extends StatelessWidget {
  const RotatedTakaWatermark({
    super.key,
    this.size = 190,
    this.color = Colors.white,
    this.opacity = 0.07,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -math.pi / 18,
      child: Text(
        '৳',
        style: TextStyle(
          fontFamily: 'NotoSansBengali',
          fontSize: size,
          height: 1,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
