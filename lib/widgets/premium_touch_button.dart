import "package:flutter/material.dart";

class PremiumTouchButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enableRipple;
  final BorderRadius? borderRadius;
  final Color? splashColor;
  final Color? highlightColor;
  final Color? backgroundColor;
  const PremiumTouchButton({
    super.key, 
    required this.child, 
    this.onTap, 
    this.enableRipple = true, 
    this.borderRadius, 
    this.splashColor, 
    this.highlightColor,
    this.backgroundColor,
  });

  @override
  State<PremiumTouchButton> createState() => _PremiumTouchButtonState();
}

class _PremiumTouchButtonState extends State<PremiumTouchButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = widget.child;
    if (widget.enableRipple) {
      content = Material(
        color: widget.backgroundColor ?? Colors.transparent,
        borderRadius: widget.borderRadius,
        clipBehavior: widget.borderRadius != null ? Clip.antiAlias : Clip.none,
        child: InkWell(
          onTap: widget.onTap,
          splashColor: widget.splashColor,
          highlightColor: widget.highlightColor,
          customBorder: widget.borderRadius != null 
              ? RoundedRectangleBorder(borderRadius: widget.borderRadius!) 
              : const CircleBorder(),
          child: widget.child,
        ),
      );
    } else if (widget.onTap != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.child,
      );
    }

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _controller.forward(),
      onPointerUp: (_) => _controller.reverse(),
      onPointerCancel: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: RepaintBoundary(child: content),
      ),
    );
  }
}
