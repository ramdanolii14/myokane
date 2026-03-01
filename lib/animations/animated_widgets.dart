import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

// ─── Animated tap / press button ───
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.95,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scale)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _ctrl.forward();
        context.read<SettingsProvider>().triggerHaptic();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ─── Slide + Fade entrance ───
class SlideIn extends StatelessWidget {
  final Widget child;
  final int delay;
  final Offset begin;

  const SlideIn({
    super.key,
    required this.child,
    this.delay = 0,
    this.begin = const Offset(0, 30),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: begin.dy / 100, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ─── Staggered list items ───
class StaggerItem extends StatelessWidget {
  final Widget child;
  final int index;

  const StaggerItem({super.key, required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: Duration(milliseconds: 80 * index))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.08, duration: 350.ms, curve: Curves.easeOut);
  }
}

// ─── Shimmer loading ───
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Color baseColor;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
    this.baseColor = const Color(0xFF1E2332),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white12);
  }
}

// ─── Bounce animation ───
class BounceIn extends StatelessWidget {
  final Widget child;
  final int delay;

  const BounceIn({super.key, required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: Duration(milliseconds: delay))
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 200.ms);
  }
}

// ─── Page transition builder ───
Route<T> slideRoute<T>(Widget page,
    {SlideDirection dir = SlideDirection.right}) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final begin = dir == SlideDirection.right
          ? const Offset(1, 0)
          : dir == SlideDirection.left
              ? const Offset(-1, 0)
              : const Offset(0, 1);
      return SlideTransition(
        position: Tween(begin: begin, end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

enum SlideDirection { right, left, up }

// ─── Number counter animation ───
class AnimatedNumber extends StatelessWidget {
  final double value;
  final String Function(double) formatter;
  final TextStyle? style;

  const AnimatedNumber({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (_, v, __) => Text(formatter(v), style: style),
    );
  }
}

// ─── Ripple button ───
class RippleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? splashColor;
  final BorderRadius? borderRadius;

  const RippleButton({
    super.key,
    required this.child,
    this.onTap,
    this.splashColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.read<SettingsProvider>().triggerHaptic();
          onTap?.call();
        },
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        splashColor: splashColor ??
            Theme.of(context).colorScheme.primary.withOpacity(0.2),
        highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        child: child,
      ),
    );
  }
}
