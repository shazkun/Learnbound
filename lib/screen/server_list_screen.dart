import 'dart:io';
import 'package:flutter/material.dart';

class ServerList extends StatefulWidget {
  final Function(String serverInfo) onSelectServer;

  const ServerList({super.key, required this.onSelectServer});

  @override
  _ServerListState createState() => _ServerListState();
}

class _ServerListState extends State<ServerList>
    with SingleTickerProviderStateMixin {
  final Set<String> _serverList = {};
  RawDatagramSocket? _udpSocket;
  final int _udpPort = 4040;
  bool _isListening = false;
  static const int _debounceDuration = 300;
  DateTime? _lastUpdateTime;
  String? _localIp;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeLocalIp();
    _startListeningForServers();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  Future<void> _initializeLocalIp() async {
    _localIp = await _getLocalIp();
    print('Local IP: $_localIp');
  }

  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Error getting local IP: $e');
    }
    return null;
  }

  void _startListeningForServers() async {
    if (_isListening) return;
    _isListening = true;

    try {
      _udpSocket =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, _udpPort);
      print('Listening for UDP packets on port $_udpPort');

      _udpSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = _udpSocket!.receive();
          if (datagram != null) {
            String serverInfo = String.fromCharCodes(datagram.data).trim();
            if (serverInfo != _localIp) {
              if (_lastUpdateTime == null ||
                  DateTime.now().difference(_lastUpdateTime!).inMilliseconds >
                      _debounceDuration) {
                if (mounted) {
                  setState(() {
                    _serverList.add(serverInfo);
                    _lastUpdateTime = DateTime.now();
                  });
                }
              }
            }
          }
        }
      }, onError: (error) => print('Error listening for UDP packets: $error'));
    } catch (e) {
      print('Error binding to UDP socket: $e');
    }
  }

  @override
  void dispose() {
    _udpSocket?.close();
    _animationController.dispose();
    print('UDP socket closed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Available Servers',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _serverList.clear());
              _startListeningForServers();
              _animationController.forward(from: 0); // Restart animation
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey[900]!, Colors.blueGrey[700]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _serverList.isEmpty
              ? Center(
                  child: Text(
                    'No servers found',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _serverList.length,
                  itemBuilder: (context, index) {
                    final serverInfo = _serverList.elementAt(index);
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Card(
                        color: Colors.white.withOpacity(0.95),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal[400],
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            serverInfo,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey[800]),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios,
                              color: Colors.teal[400]),
                          onTap: () => widget.onSelectServer(serverInfo),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
