import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({super.key});

 
  @override
  _DrawingCanvasState createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<Offset?> points = [];
  final GlobalKey _globalKey = GlobalKey();
  Color selectedColor = Colors.black; // Default color
  double strokeWidth = 5.0;


  
 

  void _addPoint(Offset point) {
    setState(() {
      points.add(point); // Only add valid points
    });
  }

  void _clear() {
    setState(() {
      points.clear(); // Clear all points
    });
  }

  Future<void> _saveDrawing() async {
    RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png';
    // Send image metadata to the host
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
                    selectedColor = newValue!;
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
                onPanUpdate: (details) {
                  _addPoint(details.localPosition); // Capture the current position
                },
                onPanEnd: (details) {
                  setState(() {
                    points.add(null); // Separate strokes by adding a null marker
                  });
                },
                child: CustomPaint(
                  painter: DrawingPainter(points, selectedColor, strokeWidth),
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

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;

  DrawingPainter(this.points, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint); // Draw between valid points
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
