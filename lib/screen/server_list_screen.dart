import 'dart:io';
import 'package:Learnbound/util/design/wave.dart';
import 'package:flutter/material.dart';

class ServerList extends StatefulWidget {
  final Function(String serverInfo) onSelectServer;

  const ServerList({super.key, required this.onSelectServer});

  @override
  _ServerListState createState() => _ServerListState();
}

class _ServerListState extends State<ServerList>
    with SingleTickerProviderStateMixin {
  final Set<String> _serverList = {"test1"};
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
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(120), // Increased height for wave design
        child: ClipPath(
          clipper: WaveClipper(), // Custom clipper for wave shape
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Color(0xFF4A4A4A)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Available Servers',
              style: TextStyle(
                color: Color(0xFF4A4A4A),
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Color(0xFFFFD3AC)),
                onPressed: () {
                  setState(() => _serverList.clear());
                  _startListeningForServers();
                  _animationController.forward(from: 0);
                },
              ),
            ],
            flexibleSpace: Container(
              decoration: BoxDecoration(
              color: Color(0xFFD7C19C)
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _serverList.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 64,
                      color:  const Color.fromRGBO(211, 172, 112, 1.0),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No servers found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A4A).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8),
                itemCount: _serverList.length,
                itemBuilder: (context, index) {
                  final serverInfo = _serverList.elementAt(index);
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:  const Color.fromRGBO(211, 172, 112, 1.0),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          serverInfo,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A4A4A),
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => widget.onSelectServer(serverInfo),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:  const Color.fromRGBO(211, 172, 112, 1.0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Connect',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
