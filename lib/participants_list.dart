import 'package:flutter/material.dart';

class ParticipantsList extends StatelessWidget {
  final Map<String, int> participants;
  final Function(String) onManagePoints; // Callback to manage points

  const ParticipantsList({
    super.key,
    required this.participants,
    required this.onManagePoints,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Participants List'),
      ),
      body: ListView.builder(
        itemCount: participants.length,
        itemBuilder: (context, index) {
          String participant = participants.keys.elementAt(index);
          int points = participants[participant] ?? 0;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50, // Background color
                border: Border.all(
                  color: Colors.blue, // Border color
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
              child: ListTile(
                title: Text(
                  participant,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  '$points pts',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
                onTap: () => onManagePoints(participant), // Manage points on tap
              ),
            ),
          );
        },
      ),
    );
  }
}
