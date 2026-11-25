import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/aurora.dart';

/// The app's motion primitives.
///
/// Everything here is presentation only: it wraps existing widgets, never owns
/// data or navigation. `MediaQuery.disableAnimationsOf` short-circuits every
/// effect, matching the web app's `prefers-reduced-motion` rule.

/// Fade + rise on first build, with an optional stagger delay.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 14,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final Animation<double> _curved = CurvedAnimation(
    parent: _controller,
    curve: Aurora.easeAurora,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, widget.offset / 200),
          end: Offset.zero,
        ).animate(_curved),
        child: widget.child,
      ),
    );
  }
}

/// Shrinks its child a few percent while pressed. Uses a raw [Listener] so it
/// never competes for the gesture with the child's own InkWell/GestureDetector.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.97});

  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Listener(
      onPointerDown: disabled ? null : (_) => setState(() => _pressed = true),
      onPointerUp: disabled ? null : (_) => setState(() => _pressed = false),
      onPointerCancel: disabled ? null : (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Aurora.easeAurora,
        child: widget.child,
      ),
    );
  }
}

/// Counts from zero to [value] on first build. Reduced motion shows the target
/// immediately, so the accessible label never depends on the animation.
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    this.suffix = '',
    this.decimals = 0,
    this.style,
  });

  final double value;
  final String suffix;
  final int decimals;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (disabled) {
      return Text('${value.toStringAsFixed(decimals)}$suffix', style: style);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, current, _) =>
          Text('${current.toStringAsFixed(decimals)}$suffix', style: style),
    );
  }
}

/// A slow, seamless technology marquee. Decorative: hidden from assistive tech
/// by the caller, paused entirely when animations are disabled.
class TechMarquee extends StatefulWidget {
  const TechMarquee({super.key, required this.items, this.height = 30});

  final List<String> items;
  final double height;

  @override
  State<TechMarquee> createState() => _TechMarqueeState();
}

class _TechMarqueeState extends State<TechMarquee> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 34),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final chips = [
      for (final item in widget.items)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Aurora.panel,
              borderRadius: BorderRadius.circular(Aurora.radiusPill),
              border: Border.all(color: Aurora.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: Aurora.sweep),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  item,
                  style: Aurora.body(12, color: Aurora.muted),
                ),
              ],
            ),
          ),
        ),
    ];

    if (disabled) {
      return SizedBox(
        height: widget.height,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: chips,
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) => AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.translate(
              offset: Offset(-_controller.value * constraints.maxWidth, 0),
              child: child,
            ),
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: double.infinity,
              child: Row(children: [...chips, ...chips, ...chips]),
            ),
          ),
        ),
      ),
    );
  }
}
