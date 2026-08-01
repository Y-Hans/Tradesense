import 'package:flutter/material.dart';

class TiltCardWrapper extends StatefulWidget {
  final Widget child;
  final double maxTiltAngle;

  const TiltCardWrapper({
    super.key,
    required this.child,
    this.maxTiltAngle = 0.1, // radians
  });

  @override
  State<TiltCardWrapper> createState() => _TiltCardWrapperState();
}

class _TiltCardWrapperState extends State<TiltCardWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _tiltOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerEvent event, Size size) {
    final localPosition = event.localPosition;
    
    // Normalize coordinates from -1 to 1 based on center
    final dx = (localPosition.dx - size.width / 2) / (size.width / 2);
    final dy = (localPosition.dy - size.height / 2) / (size.height / 2);

    setState(() {
      _tiltOffset = Offset(
        dy.clamp(-1.0, 1.0) * widget.maxTiltAngle,
        -dx.clamp(-1.0, 1.0) * widget.maxTiltAngle,
      );
    });
  }

  void _onPointerExit(PointerEvent event) {
    _resetTilt();
  }
  
  void _onPointerUp(PointerEvent event) {
    _resetTilt();
  }

  void _resetTilt() {
    final startOffset = _tiltOffset;
    final animation = Tween<Offset>(begin: startOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _tiltOffset = Offset.zero;
        });
      }
    });
    
    // We update during animation in build method
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _tiltOffset = animation.value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateX(_tiltOffset.dx)
          ..rotateY(_tiltOffset.dy);

        return MouseRegion(
          onHover: (event) => _onPointerMove(event, size),
          onExit: (event) => _onPointerExit(event),
          child: Listener(
            onPointerMove: (event) => _onPointerMove(event, size),
            onPointerUp: (event) => _onPointerUp(event),
            onPointerCancel: (event) => _onPointerUp(event),
            child: Transform(
              transform: transform,
              alignment: FractionalOffset.center,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
