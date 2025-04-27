import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class ServerList extends StatefulWidget {
  final Function(String) onSelectServer;

  const ServerList({super.key, required this.onSelectServer});

  @override
  _ServerListState createState() => _ServerListState();
}

class _ServerListState extends State<ServerList> {
  List<String> servers = [];
  RawDatagramSocket? socket;

  @override
  void initState() {
    super.initState();
    _startListeningForServers();
  }

  Future<void> _startListeningForServers() async {
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4040);
      socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket!.receive();
          if (datagram != null) {
            final message = utf8.decode(datagram.data);
            if (!servers.contains(message)) {
              setState(() => servers.add(message));
            }
          }
        }
      });
    } catch (e) {
      print('Error listening for servers: $e');
    }
  }

  @override
  void dispose() {
    socket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Available Servers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          servers.isEmpty
              ? Text('No servers found')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: servers.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(servers[index]),
                    onTap: () => widget.onSelectServer(servers[index]),
                  ),
                ),
        ],
      ),
    );
  }
}
