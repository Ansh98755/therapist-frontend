
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../utils/text_style_constants/text_style_constants.dart';

class AnimatedGradientBanner extends StatefulWidget {
  final String text;

  const AnimatedGradientBanner({super.key, required this.text});

  @override
  State<AnimatedGradientBanner> createState() => _AnimatedGradientBannerState();
}

class _AnimatedGradientBannerState extends State<AnimatedGradientBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ///********** Therapist Banner ***********/////
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [
                Color(0xFFFDC7208),
                Color(0xFFF3B183),
                Color(0xFFFDCE67),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                (0.15 + 0.25 * (0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi))) % 1.0,
                (0.45 + 0.25 * (0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi + 1))) % 1.0,
                (0.75 + 0.2  * (0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi + 2))) % 1.0,
              ],

            ),
            borderRadius: BorderRadius.circular(30), // smooth cursive-like corners
          ),
          child: Text(
              widget.text,
              style:TextStyleConstants.inter12W500.copyWith(color: Color(0xFF3A2F00))
          ),
        );
      },
    );
  }
}