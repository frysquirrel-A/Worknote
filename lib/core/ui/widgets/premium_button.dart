import 'package:flutter/material.dart';

import 'package:worknote/core/ui/widgets/press_scale.dart';

class PremiumButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;

  const PremiumButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.95,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  @override
  Widget build(BuildContext context) {
    return PressScale(
      pressedScale: widget.scale,
      downDuration: const Duration(milliseconds: 100),
      upDuration: const Duration(milliseconds: 120),
      upCurve: Curves.easeOutCubic,
      onTap: widget.onTap,
      haptic: PressScaleHaptic.light,
      child: widget.child,
    );
  }
}
