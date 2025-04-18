import 'package:flutter/material.dart';

class LobbyUI extends StatelessWidget {
  final VoidCallback onShowServerList;

  const LobbyUI({super.key, required this.onShowServerList});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: onShowServerList,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(211, 172, 112, 1.0),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'Join Server',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
