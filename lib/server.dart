import 'dart:async';
import 'dart:convert';
import 'dart:io';

class BroadcastServer {
  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;

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

  // Start broadcasting
  Future<void> startBroadcast() async {
    try {
      // Bind the RawDatagramSocket to any IPv4 address on port 4040
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4040);
      _socket!.broadcastEnabled = true;

      final localIp = await getLocalIp();

      // Create the broadcast message with the local IP address
      final message = utf8.encode('$localIp');

      // Set up a timer to send the broadcast message every 3 seconds
      _broadcastTimer = Timer.periodic(Duration(seconds: 3), (timer) {
        _socket!.send(
          message,
          InternetAddress('255.255.255.255'),
          4040,
        );
      });
    } catch (error) {
      print('Error occurred while running server: $error');
    }
  }

  // Stop broadcasting
  void stopBroadcast() {
    _broadcastTimer?.cancel(); // Cancel the Timer
    _socket?.close(); // Close the socket
    _broadcastTimer = null;
    _socket = null;
    print('Broadcasting stopped.');
  }

  
}
