import 'dart:io';

import 'package:flutter/material.dart';

class PictureUI extends StatelessWidget {
  final Future<void> Function() onPickAndSendImage;
  final String? imagePath;

  const PictureUI({
    super.key,
    required this.onPickAndSendImage,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: imagePath != null
                ? GestureDetector(
                    onTap: () {
                      // Show the image in a full-screen dialog
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: InteractiveViewer(
                              child: Image.file(File(imagePath!)),
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius:
                            BorderRadius.circular(20), // Rounded border
                      ),
                      padding: EdgeInsets.all(4),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(20), // Round the image itself
                        child: Image.file(
                          File(imagePath!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )
                : Text(
                    "Drawing Mode",
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ),
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
