import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

class ServerList extends StatefulWidget {
  final Function(String serverInfo) onSelectServer;

  const ServerList({super.key, required this.onSelectServer});

  @override
  _ServerListState createState() => _ServerListState();
}

class _ServerListState extends State<ServerList> {
  final Set<String> serverList = {}; // Use a Set for unique entries
  RawDatagramSocket? udpSocket;
  final int udpPort = 4040;
  bool isListening = false; // Flag to prevent multiple listeners
  static const int debounceDuration = 300; // Duration in milliseconds
  DateTime? lastUpdateTime; // Track the last update time
  String? localIp; // Store the local IP address

  @override
  void initState() {
    super.initState();
    _initializeLocalIp();
    _startListeningForServers();
  }

  Future<void> _initializeLocalIp() async {
    localIp = await getLocalIp();
    print('Local IP: $localIp');
  }

  Future<String?> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address; // Return the first non-loopback IPv4 address
          }
        }
      }
    } catch (e) {
      print('Error getting local IP: $e');
    }
    return null; // Return null if no valid address is found
  }

  void _startListeningForServers() async {
    if (isListening) return; // Prevent multiple calls to start listening
    isListening = true;

    try {
      udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, udpPort);
      print('Listening for UDP packets on port $udpPort');

      udpSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = udpSocket!.receive();
          if (datagram != null) {
            String serverInfo = String.fromCharCodes(datagram.data).trim();

            // Check if the received server info matches the local IP and filter it out
            if (serverInfo != localIp) {
              // Check the time since the last update
              if (lastUpdateTime == null ||
                  DateTime.now().difference(lastUpdateTime!).inMilliseconds > debounceDuration) {
                setState(() {
                  serverList.add(serverInfo); // Add new server info
                  lastUpdateTime = DateTime.now(); // Update the last update time
                });
              }
            }
          }
        }
      }, onError: (error) {
        print('Error listening for UDP packets: $error');
      });
    } catch (e) {
      print('Error binding to UDP socket: $e');
    }
  }

  @override
  void dispose() {
    udpSocket?.close();
    print('UDP socket closed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Servers'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                serverList.clear();
              });
              _startListeningForServers(); // Restart the listening process
            },
          ),
        ],
      ),
      body: serverList.isEmpty
          ? Center(child: Text('No servers found'))
          : ListView.builder(
              itemCount: serverList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(serverList.elementAt(index)), // Use elementAt for Set
                  onTap: () => widget.onSelectServer(serverList.elementAt(index)),
                );
              },
            ),
    );
  }
}
