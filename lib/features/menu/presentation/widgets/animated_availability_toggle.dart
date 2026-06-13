import 'package:flutter/material.dart';

class AnimatedAvailabilityToggle extends StatelessWidget {
  final bool isAvailable;
  final VoidCallback onTap;

  const AnimatedAvailabilityToggle({
    super.key,
    required this.isAvailable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final rotate = Tween<double>(begin: 0.5, end: 1.0).animate(animation);
          final scale = Tween<double>(begin: 0.3, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          );

          return ScaleTransition(
            scale: scale,
            child: RotationTransition(
              turns: rotate,
              child: child,
            ),
          );
        },
        child: isAvailable
            ? const Icon(
                Icons.check_circle,
                key: ValueKey('available_check'),
                color: Colors.green,
                size: 32,
              )
            : const Icon(
                Icons.cancel,
                key: ValueKey('unavailable_cross'),
                color: Colors.red,
                size: 32,
              ),
      ),
    );
  }
}
