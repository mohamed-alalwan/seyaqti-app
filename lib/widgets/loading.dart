import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Loading extends StatelessWidget {
  final Color? color;
  const Loading({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color ?? Colors.white,
      child: const Center(
        child: SpinKitChasingDots(
          color: Colors.red,
          size: 50.0,
        ),
      ),
    );
  }
}
