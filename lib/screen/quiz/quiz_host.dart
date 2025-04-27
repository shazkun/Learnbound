import 'dart:io';
import 'package:flutter/material.dart';

class BlankScreen extends StatefulWidget {
  final int number;
  final Socket socket; // Using Socket for client-side communication

  const BlankScreen({super.key, required this.number, required this.socket});

  @override
  _BlankScreenState createState() => _BlankScreenState();
}

class _BlankScreenState extends State<BlankScreen> {
  int receivedNumber = 0;

  @override
  void initState() {
    super.initState();
    _initializeSocketListener();
  }

  void _initializeSocketListener() {
    widget.socket.listen((data) {
      String message = String.fromCharCodes(data);
      if (message.startsWith("test: ")) {
        final numberString =
            message.substring(6); // Extract number after "test: "
        final number = int.tryParse(numberString);
        if (number != null) {
          setState(() {
            receivedNumber = number;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    widget.socket.close(); // Close socket when screen is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blank Screen'),
      ),
      body: Center(
        child: Text(
          'Received number: $receivedNumber\nInitial number: ${widget.number}',
          style: const TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
