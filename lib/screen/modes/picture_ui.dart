import 'package:flutter/material.dart';

class PictureUI extends StatelessWidget {
  final Future<void> Function() onPickAndSendImage;

  const PictureUI({required this.onPickAndSendImage});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
            child: Center(
                child: Text("Picture Mode",
                    style: TextStyle(color: Colors.white)))),
        Padding(
          padding: EdgeInsets.all(16),
          child: FloatingActionButton(
            onPressed: onPickAndSendImage,
            backgroundColor: Colors.teal[400],
            child: Icon(Icons.image),
          ),
        ),
      ],
    );
  }
}
