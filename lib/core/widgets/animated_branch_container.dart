import 'package:flutter/material.dart';

class AnimatedBranchContainer extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;

  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  @override
  State<AnimatedBranchContainer> createState() => _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _previousIndex = 0;
  bool _isForward = true;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.value = 1.0; // Start fully transitioned
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {}); // Paksa rebuild agar widget lama masuk ke Offstage
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _isForward = widget.currentIndex > oldWidget.currentIndex;
      _previousIndex = oldWidget.currentIndex;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.children.length, (index) {
        final isActive = index == widget.currentIndex;
        final isPrevious = index == _previousIndex;
        final bool isVisible = isActive || (isPrevious && _controller.isAnimating);

        // Jika tidak aktif dan tidak sedang animasi, sembunyikan dengan Offstage
        // agar state tetap terjaga (memori tidak melonjak) tapi tidak di-render (hemat CPU).
        if (!isVisible) {
          return Offstage(
            offstage: true,
            child: widget.children[index],
          );
        }

        // Halaman yang baru masuk (Active)
        if (isActive && _controller.isAnimating) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(_isForward ? 0.3 : -0.3, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)),
            child: FadeTransition(
              opacity: _controller,
              child: widget.children[index],
            ),
          );
        }

        // Halaman yang akan keluar (Previous)
        if (isPrevious && _controller.isAnimating) {
          return IgnorePointer(
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: Offset(_isForward ? -0.3 : 0.3, 0),
              ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)),
              child: FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_controller),
                child: widget.children[index],
              ),
            ),
          );
        }

        // Halaman aktif saat diam
        return widget.children[index];
      }),
    );
  }
}
