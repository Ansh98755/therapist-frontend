import 'package:flutter/material.dart';

import '../../../utils/color_constants/color_constants.dart';

class HighlightedPostCard extends StatefulWidget {
  final dynamic post;
  final bool isHighlighted;
  final Widget child;

  const HighlightedPostCard({
    super.key,
    required this.post,
    required this.isHighlighted,
    required this.child,
  });

  @override
  State<HighlightedPostCard> createState() => _HighlightedPostCardState();
}

class _HighlightedPostCardState extends State<HighlightedPostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _animation = Tween<double>(begin: 0.1, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isHighlighted) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant HighlightedPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isHighlighted) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final glowColor = Colors.orange.withOpacity(_animation.value);

          return Container(
            decoration: BoxDecoration(
              color: ColorConstants.whiteColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.isHighlighted ? glowColor : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                // Base shadow (always visible)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
                // Animated highlight shadow (only when highlighted)
                if (widget.isHighlighted)
                  BoxShadow(
                    color: glowColor,
                    blurRadius: 12,
                    spreadRadius: 4,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}
