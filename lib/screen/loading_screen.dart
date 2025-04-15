import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD3A97D), // Match your app’s primary color
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFD3A97D).withOpacity(1), // Start color
              Color(0xFFEBE1C8).withOpacity(1), // End color
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Center(
          child: LoadingAnimationWidget.discreteCircle(
              color: Color.fromRGBO(194, 173, 135, 1), // Color for the loading animation
              size: 80, // Size of the loading animation
              secondRingColor: Color.fromRGBO(206, 140, 17, 1),
          )
        ),
      ),
    );
  }
}
