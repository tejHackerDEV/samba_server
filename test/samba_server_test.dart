import 'package:http/http.dart' as http;
import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

void main() {
  const address = '127.0.0.1';
  const port = 8080;

  group('Server start & stop tests', () {
    final httpServer = HttpServer();

    test('Server should be up & running', () async {
      await httpServer.bind(address: address, port: port);
      expect(httpServer.isRunning, isTrue);
    });

    test('Server should be shutdown', () async {
      await httpServer.shutdown();
      expect(httpServer.isRunning, isFalse);
    });
  });

  group('Incoming requests tests', () {
    final httpServer = HttpServer();

    setUpAll(() => httpServer.bind(address: address, port: port));

    test('Server should listen to incoming requests', () async {
      final response = await http.get(Uri.parse('http://$address:$port'));
      expect(response.statusCode, 200);
      expect(response.body, 'Hello from SAMBA_SERVER');
    });

    tearDownAll(() => httpServer.shutdown());
  });
}
