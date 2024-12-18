import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

// Custom class to represent a stroke
class Stroke {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;

  Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
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
  bool isErasing = false;

  List<Stroke> redoStrokes = [];

  void _undo() {
    if (strokes.isNotEmpty) {
      redoStrokes.add(strokes.removeLast());
      setState(() {});
    }
  }

  void _redo() {
    if (redoStrokes.isNotEmpty) {
      strokes.add(redoStrokes.removeLast());
      setState(() {});
    }
  }

  // Start a new stroke (when drawing starts)
  void _startNewStroke(Offset point) {
    if (isErasing) {
      // Remove strokes near the eraser point
      _eraseAtPoint(point);
    } else {
      currentStrokePoints = [point];
      setState(() {});
    }
  }

  // Add points to the current stroke
  void _addPoint(Offset point) {
    if (isErasing) {
      _eraseAtPoint(point);
    } else {
      currentStrokePoints.add(point);
      setState(() {});
    }
  }

  // End the current stroke (when the user lifts their finger or pointer)
  void _endStroke() {
    if (!isErasing && currentStrokePoints.isNotEmpty) {
      strokes.add(Stroke(
        points: List.from(currentStrokePoints),
        color: selectedColor,
        strokeWidth: strokeWidth,
      ));
      currentStrokePoints.clear();
      redoStrokes.clear(); // Clear redo stack when new stroke is added
      setState(() {});
    }
  }

  // Erase strokes near a given point
  void _eraseAtPoint(Offset point) {
    setState(() {
      strokes.removeWhere((stroke) {
        return stroke.points.any((strokePoint) =>
            strokePoint != null &&
            (strokePoint - point).distance < strokeWidth);
      });
    });
  }

  // Clear the entire canvas
  void _clear() {
    strokes.clear();
    setState(() {});
  }

  // Save the drawing as an image
  Future<void> _saveDrawing() async {
    final boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final imagePath =
        '${(await getApplicationDocumentsDirectory()).path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(imagePath).writeAsBytes(pngBytes);
    if (mounted) {
      Navigator.pop(context, imagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw Something'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDrawing,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clear,
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undo,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _redo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar for selecting tools
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200], // Light background color
              borderRadius: BorderRadius.circular(16), // Rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4), // Subtle shadow
                ),
              ],
            ),
            margin:
                const EdgeInsets.all(16), // Margin around the tools container
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8), // Padding inside
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Allow horizontal scrolling
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Color picker
                  DropdownButton<Color>(
                    value: selectedColor,
                    items: [
                      DropdownMenuItem(
                        value: Colors.black,
                        child: Row(
                          children: [
                            Icon(Icons.circle, color: Colors.black),
                            const SizedBox(width: 8),
                            const Text("Black"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: Colors.red,
                        child: Row(
                          children: [
                            Icon(Icons.circle, color: Colors.red),
                            const SizedBox(width: 8),
                            const Text("Red"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: Colors.green,
                        child: Row(
                          children: [
                            Icon(Icons.circle, color: Colors.green),
                            const SizedBox(width: 8),
                            const Text("Green"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: Colors.blue,
                        child: Row(
                          children: [
                            Icon(Icons.circle, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text("Blue"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: Colors.yellow,
                        child: Row(
                          children: [
                            Icon(Icons.circle, color: Colors.yellow),
                            const SizedBox(width: 8),
                            const Text("Yellow"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: Colors.pink,
                        child: Row(
                          children: [
                            Icon(Icons.circle, color: Colors.pink),
                            const SizedBox(width: 8),
                            const Text("Pink"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: Colors.purple,
                        child: Row(
                          children: [
                            Icon(Icons.circle, color: Colors.purple),
                            const SizedBox(width: 8),
                            const Text("Purple"),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (Color? newValue) {
                      setState(() {
                        isErasing = false; // Ensure eraser mode is disabled
                        selectedColor = newValue!;
                      });
                    },
                  ),

                  const SizedBox(width: 12), // Space between elements

                  // Stroke width slider
                  Slider(
                    value: strokeWidth,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    label: strokeWidth.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        strokeWidth = value;
                      });
                    },
                  ),

                  const SizedBox(width: 12), // Space between elements

                  // Eraser toggle button
                  IconButton(
                    icon: Icon(
                      isErasing ? Icons.create : Icons.create_outlined,
                      color: isErasing ? Colors.grey : Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        isErasing = !isErasing; // Toggle eraser mode
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: RepaintBoundary(
              key: _globalKey,
              child: ClipRect(
                // Ensure drawing is restricted to the visible area
                child: GestureDetector(
                  onPanStart: (details) {
                    if (_isWithinBounds(details.localPosition)) {
                      _startNewStroke(details.localPosition);
                    }
                  },
                  onPanUpdate: (details) {
                    if (_isWithinBounds(details.localPosition)) {
                      _addPoint(details.localPosition);
                    }
                  },
                  onPanEnd: (details) {
                    _endStroke();
                  },
                  child: CustomPaint(
                    painter: DrawingPainter(
                      strokes,
                      currentStrokePoints,
                      isErasing ? Colors.white : selectedColor,
                      strokeWidth,
                    ),
                    child: Container(
                        // Background color for the drawing area
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isWithinBounds(Offset position) {
    final boundary =
        _globalKey.currentContext?.findRenderObject() as RenderBox?;
    if (boundary == null) return false;

    final size = boundary.size;
    return position.dx >= 0 &&
        position.dy >= 0 &&
        position.dx <= size.width &&
        position.dy <= size.height;
  }
}

// Custom painter to draw each stroke with its own color and width
class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset?> currentStrokePoints;
  final Color color;
  final double strokeWidth;

  DrawingPainter(
      this.strokes, this.currentStrokePoints, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..strokeCap = StrokeCap.round;

    // Paint the finished strokes
    for (var stroke in strokes) {
      paint.color = stroke.color;
      paint.strokeWidth = stroke.strokeWidth;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        if (stroke.points[i] != null && stroke.points[i + 1] != null) {
          canvas.drawLine(stroke.points[i]!, stroke.points[i + 1]!, paint);
        }
      }
    }

    // Paint the current stroke
    paint.color = color;
    paint.strokeWidth = strokeWidth;
    for (int i = 0; i < currentStrokePoints.length - 1; i++) {
      if (currentStrokePoints[i] != null &&
          currentStrokePoints[i + 1] != null) {
        canvas.drawLine(
            currentStrokePoints[i]!, currentStrokePoints[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
