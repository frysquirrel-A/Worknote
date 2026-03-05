import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PressScaleHaptic {
  none,
  selection,
  light,
  medium,
}

class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Duration downDuration;
  final Duration upDuration;
  final Curve downCurve;
  final Curve upCurve;
  final PressScaleHaptic haptic;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.975,
    this.downDuration = const Duration(milliseconds: 90),
    this.upDuration = const Duration(milliseconds: 140),
    this.downCurve = Curves.easeOutCubic,
    this.upCurve = Curves.easeOutBack,
    this.haptic = PressScaleHaptic.light,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted) return;
    setState(() => _pressed = value);
  }

  void _fireHaptic() {
    switch (widget.haptic) {
      case PressScaleHaptic.none:
        return;
      case PressScaleHaptic.selection:
        HapticFeedback.selectionClick();
        return;
      case PressScaleHaptic.light:
        HapticFeedback.lightImpact();
        return;
      case PressScaleHaptic.medium:
        HapticFeedback.mediumImpact();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTap: enabled
          ? () {
              _fireHaptic();
              widget.onTap?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: _pressed ? widget.downDuration : widget.upDuration,
        curve: _pressed ? widget.downCurve : widget.upCurve,
        child: widget.child,
      ),
    );
  }
}

