import 'package:flutter/material.dart';

class RotationAnimation extends StatefulWidget {
  const RotationAnimation({Key? key}) : super(key: key);

  @override
  _RotationAnimationState createState() => _RotationAnimationState();
}

class _RotationAnimationState extends State<RotationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  @override
  void initState() {
    super.initState();
    _animationController =
        new AnimationController(vsync: this, duration: Duration(seconds: 1));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.stop();
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _animationController,
        child: Container(
          child: Image.asset('assets/images/logo_rotate.png'),
        ),
        builder: (context, widget) => Transform.rotate(
          angle: _animationController.value * 6.3,
          child: widget,
        ),
      ),
    );
  }
}
