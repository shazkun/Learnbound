import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServerSocket Integration Test', () {
    late Socket client1;
    late Socket client2;

    Future<Socket> connectClient() async {
      return await Socket.connect('localhost', 4040);
    }

    test('Clients connect and send nicknames and questions', () async {
      client1 = await connectClient();
      client2 = await connectClient();

      client1.write('Nickname:Alice\n');
      client2.write('Nickname:Bob\n');

      await Future.delayed(Duration(milliseconds: 100));

      client1.write('Question:What is 2 + 2?\n');
      client2.write('Chat:Hello Alice!\n');

      await Future.delayed(Duration(milliseconds: 300));

      client1.destroy();
      client2.destroy();
    });

    test('Send and process multiple choice answer', () async {
      final client = await connectClient();
      client.write('Nickname:Tester\n');
      await Future.delayed(Duration(milliseconds: 50));
      client.write('Answer:What is 2 + 2?|4\n');
      await Future.delayed(Duration(milliseconds: 100));
      client.destroy();
    });

    test('Send image data', () async {
      final client = await connectClient();
      client.write('Nickname:Drawer\n');
      await Future.delayed(Duration(milliseconds: 50));

      // Simulate image being sent as string ending with newline
      client.write('...base64ImageDataHere...\n');
      await Future.delayed(Duration(milliseconds: 200));

      client.destroy();
    });
  });
}
