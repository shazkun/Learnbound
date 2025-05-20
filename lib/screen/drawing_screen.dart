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

  // Show tools in a bottom sheet
  void _showToolsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Color picker
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isErasing
                          ? Colors.grey.withOpacity(0.2)
                          : Colors.white.withOpacity(0.8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Color>(
                        value: selectedColor,
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.black87),
                        items: [
                          _buildColorMenuItem(Colors.black, 'Black'),
                          _buildColorMenuItem(Colors.red, 'Red'),
                          _buildColorMenuItem(Colors.green, 'Green'),
                          _buildColorMenuItem(Colors.blue, 'Blue'),
                          _buildColorMenuItem(Colors.yellow, 'Yellow'),
                          _buildColorMenuItem(Colors.pink, 'Pink'),
                          _buildColorMenuItem(Colors.purple, 'Purple'),
                        ],
                        onChanged: (Color? newValue) {
                          setModalState(() {
                            setState(() {
                              isErasing = false; // Disable eraser mode
                              selectedColor = newValue!;
                            });
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Stroke width slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Stroke Width:',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 150,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbColor: Colors.black87,
                            activeTrackColor: Colors.black87,
                            inactiveTrackColor: Colors.grey[300],
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16),
                          ),
                          child: Slider(
                            value: strokeWidth,
                            min: 1.0,
                            max: 10.0,
                            divisions: 9,
                            label: strokeWidth.round().toString(),
                            onChanged: (double value) {
                              setModalState(() {
                                setState(() {
                                  strokeWidth = value;
                                });
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Eraser toggle button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isErasing
                          ? Colors.black87.withOpacity(0.8)
                          : Colors.white.withOpacity(0.8),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isErasing
                            ? Icons.cleaning_services
                            : Icons.brush_outlined,
                        color: isErasing ? Colors.white : Colors.black87,
                      ),
                      tooltip: isErasing ? 'Switch to Pen' : 'Switch to Eraser',
                      onPressed: () {
                        setModalState(() {
                          setState(() {
                            isErasing = !isErasing; // Toggle eraser mode
                          });
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Draw Something',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Tooltip(
            message: 'Save Drawing',
            child: IconButton(
              icon: const Icon(Icons.save, color: Colors.black87),
              onPressed: _saveDrawing,
            ),
          ),
          Tooltip(
            message: 'Clear Canvas',
            child: IconButton(
              icon: const Icon(Icons.clear, color: Colors.black87),
              onPressed: _clear,
            ),
          ),
          Tooltip(
            message: 'Undo',
            child: IconButton(
              icon: const Icon(Icons.undo, color: Colors.black87),
              onPressed: _undo,
            ),
          ),
          Tooltip(
            message: 'Redo',
            child: IconButton(
              icon: const Icon(Icons.redo, color: Colors.black87),
              onPressed: _redo,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showToolsBottomSheet,
        backgroundColor: Colors.white,
        child: const Icon(Icons.brush, color: Colors.black87),
        tooltip: 'Drawing Tools',
      ),
      body: Column(
        children: [
          // Drawing area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: RepaintBoundary(
                key: _globalKey,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
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
                      child: Container(),
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

  DropdownMenuItem<Color> _buildColorMenuItem(Color color, String name) {
    return DropdownMenuItem(
      value: color,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.black12),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
