import 'package:flutter/material.dart';

class ParticipantsList extends StatelessWidget {
  final Map<String, int> participants;

  const ParticipantsList({super.key, required this.participants});

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

          return ListTile(
            title: Text(participant),
            trailing: Text('$points pts'),
          );
        },
      ),
    );
  }
}
