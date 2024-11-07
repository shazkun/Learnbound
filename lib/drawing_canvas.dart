import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Custom class to represent a stroke
class Stroke {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;

  Stroke({required this.points, required this.color, required this.strokeWidth});
}

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({super.key});

  @override
  _DrawingCanvasState createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<Stroke> strokes = [];
  List<Offset?> currentStrokePoints = [];
  final GlobalKey _globalKey = GlobalKey();
  Color selectedColor = Colors.black; // Default color
  double strokeWidth = 5.0;

  // Start a new stroke (when drawing starts)
  void _startNewStroke(Offset point) {
    setState(() {
      currentStrokePoints = [point]; // Start a new stroke
    });
  }

  // Add points to the current stroke
  void _addPoint(Offset point) {
    setState(() {
      currentStrokePoints.add(point);
    });
  }

  // End the current stroke (when the user lifts their finger or pointer)
  void _endStroke() {
    setState(() {
      strokes.add(Stroke(
        points: List.from(currentStrokePoints),
        color: selectedColor,
        strokeWidth: strokeWidth,
      ));
      currentStrokePoints.clear(); // Reset current stroke points
    });
  }

  // Clear the entire canvas
  void _clear() {
    setState(() {
      strokes.clear(); // Clear all strokes
    });
  }

  // Save the drawing as an image
  Future<void> _saveDrawing() async {
    RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png';
    File imgFile = File(imagePath);
    await imgFile.writeAsBytes(pngBytes);

    Navigator.pop(context, imgFile); // Return the saved image
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Draw Something'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveDrawing, // Save the drawing
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _clear, // Clear the canvas
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar for selecting color and stroke width
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Color picker
              DropdownButton<Color>(
                value: selectedColor,
                items: [
                  DropdownMenuItem(value: Colors.black, child: Text("Black")),
                  DropdownMenuItem(value: Colors.red, child: Text("Red")),
                  DropdownMenuItem(value: Colors.green, child: Text("Green")),
                  DropdownMenuItem(value: Colors.blue, child: Text("Blue")),
                  DropdownMenuItem(value: Colors.yellow, child: Text("Yellow")),
                ],
                onChanged: (Color? newValue) {
                  setState(() {
                    selectedColor = newValue!; // Update selected color
                  });
                },
              ),

              // Stroke width slider
              Slider(
                value: strokeWidth,
                min: 1.0,
                max: 10.0,
                divisions: 9,
                label: strokeWidth.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    strokeWidth = value; // Update stroke width
                  });
                },
              ),
            ],
          ),
          Expanded(
            child: RepaintBoundary(
              key: _globalKey,
              child: GestureDetector(
                onPanStart: (details) {
                  _startNewStroke(details.localPosition); // Start a new stroke
                },
                onPanUpdate: (details) {
                  _addPoint(details.localPosition); // Add points to current stroke
                },
                onPanEnd: (details) {
                  _endStroke(); // End the current stroke
                },
                child: CustomPaint(
                  painter: DrawingPainter(strokes, currentStrokePoints, selectedColor, strokeWidth),
                  child: Container(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter to draw each stroke with its own color and width
class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset?> currentStrokePoints;
  final Color color;
  final double strokeWidth;

  DrawingPainter(this.strokes, this.currentStrokePoints, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..strokeCap = StrokeCap.round;

    // Paint the finished strokes
    for (var stroke in strokes) {
      paint.color = stroke.color;
      paint.strokeWidth = stroke.strokeWidth;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        if (stroke.points[i] != null && stroke.points[i + 1] != null) {
          canvas.drawLine(stroke.points[i]!, stroke.points[i + 1]!, paint); // Draw between points
        }
      }
    }

    // Paint the current stroke with the selected color and width
    paint.color = color;
    paint.strokeWidth = strokeWidth;
    for (int i = 0; i < currentStrokePoints.length - 1; i++) {
      if (currentStrokePoints[i] != null && currentStrokePoints[i + 1] != null) {
        canvas.drawLine(currentStrokePoints[i]!, currentStrokePoints[i + 1]!, paint); // Draw current stroke
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
