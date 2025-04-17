import 'package:flutter/material.dart';

class PictureUI extends StatelessWidget {
  final Future<void> Function() onPickAndSendImage;

  const PictureUI({super.key, required this.onPickAndSendImage});

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
            backgroundColor: const Color.fromRGBO(211, 172, 112, 1.0),
            child: Icon(Icons.image),
          ),
        ),
      ],
    );
  }
}
