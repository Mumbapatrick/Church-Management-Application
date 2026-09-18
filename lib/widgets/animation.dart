import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A modern, interactive card wrapper providing entrance animations,
/// springy touch feedback, and seamless screen transitions.
class ReusableEventCard extends StatefulWidget {
  final Widget child;
  final int index;
  final VoidCallback? onTap;
  final Widget? destinationPage;
  final String? heroTag;

  const ReusableEventCard({
    super.key,
    required this.child,
    required this.index,
    this.onTap,
    this.destinationPage,
    this.heroTag,
  });

  @override
  State<ReusableEventCard> createState() => _ReusableEventCardState();
}

class _ReusableEventCardState extends State<ReusableEventCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Dynamic staggered calculation with upper clamp protection
    final double start = (widget.index * 0.06).clamp(0.0, 0.5);
    final double end = (start + 0.45).clamp(0.0, 1.0);

    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curvedAnimation);

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(curvedAnimation);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();

    widget.onTap?.call();

    if (widget.destinationPage != null) {
      Navigator.of(context).push(
        SmoothPageRoute(page: widget.destinationPage!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget currentChild = widget.child;

    if (widget.heroTag != null) {
      currentChild = Hero(
        tag: widget.heroTag!,
        child: currentChild,
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Listener(
            onPointerDown: (_) => setState(() => _isPressed = true),
            onPointerUp: (_) => setState(() => _isPressed = false),
            onPointerCancel: (_) => setState(() => _isPressed = false),
            child: GestureDetector(
              onTap: _handleTap,
              behavior: HitTestBehavior.opaque,
              child: AnimatedScale(
                scale: _isPressed ? 0.96 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.fastOutSlowIn,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.fastOutSlowIn,
                  child: currentChild,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom page route builder for iOS-like smooth transitions, featuring
/// subtle spring physics, background dimming, and gesture compatibility.
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothPageRoute({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 380),
    barrierDismissible: false,
    opaque: true,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.0, 0.04),
        end: Offset.zero,
      ).animate(curvedAnimation);

      final scaleAnimation = Tween<double>(
        begin: 0.97,
        end: 1.0,
      ).animate(curvedAnimation);

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(curvedAnimation);

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        ),
      );
    },
  );
}