import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

bool reduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
    View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;

/// Short, finite animations that also respect accessibility preferences.
class MotionEntrance extends StatelessWidget {
  const MotionEntrance({super.key, required this.child, this.order = 0});

  final Widget child;
  final int order;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    final delay = order.clamp(0, 7) * .045;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      child: child,
      builder: (context, value, child) {
        final progress = Interval(
          delay,
          1,
          curve: Curves.easeOutCubic,
        ).transform(value);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - progress)),
            child: child,
          ),
        );
      },
    );
  }
}

class MotionPage extends StatelessWidget {
  const MotionPage({
    super.key,
    required this.pageKey,
    required this.child,
    this.direction = 1,
  });

  final Object pageKey;
  final Widget child;
  final int direction;

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotion(context);
    return AnimatedSwitcher(
      duration: reduced ? Duration.zero : const Duration(milliseconds: 650),
      reverseDuration: reduced
          ? Duration.zero
          : const Duration(milliseconds: 300),
      layoutBuilder: (current, previous) => ClipRect(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            for (final outgoing in previous)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(child: ExcludeSemantics(child: outgoing)),
              ),
            ?current,
          ],
        ),
      ),
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(pageKey);
        final travelDirection =
            direction *
            (Directionality.of(context) == TextDirection.rtl ? -1 : 1);
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final value = animation.value.clamp(0.0, 1.0);
            final spring = Curves.easeOutBack.transform(value);
            final exit = Curves.easeInCubic.transform(1 - value);
            final opacity = incoming
                ? Curves.easeOut.transform((value / .55).clamp(0.0, 1.0))
                : 1 - exit;
            return Opacity(
              opacity: opacity,
              child: FractionalTranslation(
                translation: Offset(
                  reduced
                      ? 0
                      : travelDirection *
                            (incoming ? .28 * (1 - spring) : -.14 * exit),
                  0,
                ),
                child: Transform.translate(
                  offset: Offset(
                    0,
                    reduced || !incoming ? 0 : 20 * (1 - spring),
                  ),
                  child: Transform.scale(
                    alignment: Alignment.topCenter,
                    scale: reduced
                        ? 1
                        : (incoming ? .94 + .06 * spring : 1 - .045 * exit),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
      },
      child: KeyedSubtree(key: ValueKey(pageKey), child: child),
    );
  }
}

/// Adds tactile feedback without replacing the child's tap or semantics.
class MotionFeedback extends StatefulWidget {
  const MotionFeedback({super.key, required this.child});
  final Widget child;

  @override
  State<MotionFeedback> createState() => _MotionFeedbackState();
}

class _MotionFeedbackState extends State<MotionFeedback> {
  bool pressed = false;
  bool hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hovered = true),
    onExit: (_) => setState(() {
      hovered = false;
      pressed = false;
    }),
    child: Listener(
      onPointerDown: (_) => setState(() => pressed = true),
      onPointerUp: (_) => setState(() => pressed = false),
      onPointerCancel: (_) => setState(() => pressed = false),
      child: AnimatedScale(
        scale: reduceMotion(context)
            ? 1
            : (pressed ? .98 : (hovered ? 1.008 : 1)),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    ),
  );
}

class ClinicPageTransitions extends CupertinoPageTransitionsBuilder {
  const ClinicPageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => reduceMotion(context)
      ? child
      : super.buildTransitions(
          route,
          context,
          animation,
          secondaryAnimation,
          child,
        );
}
