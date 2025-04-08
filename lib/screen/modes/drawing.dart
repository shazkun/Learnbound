
import 'package:flutter/material.dart';

class DrawingUI extends StatelessWidget {
  final VoidCallback onOpenDrawingCanvas;

  const DrawingUI({super.key, required this.onOpenDrawingCanvas});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: Center(child: Text("Drawing Mode", style: TextStyle(color: Colors.white)))),
        Padding(
          padding: EdgeInsets.all(16),
          child: FloatingActionButton(
            onPressed: onOpenDrawingCanvas,
            backgroundColor: Colors.teal[400],
            child: Icon(Icons.brush),
          ),
        ),
      ],
    );
  }
}