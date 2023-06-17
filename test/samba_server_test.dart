import 'package:http/http.dart' as http;
import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

void main() {
  const address = '127.0.0.1';
  const port = 8080;

  group('Server start & stop tests', () {
    final httpServer = HttpServer();

    setUpAll(() => httpServer.bind(address: address, port: port));

    test('Server should be up & running', () async {
      expect(httpServer.isRunning, isTrue);
    });

    test('Should return valid base uri of server', () async {
      expect(httpServer.uri, Uri.parse('http://$address:$port'));
    });

    test('Server should be up & running', () async {
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
      final responseToSend = 'Hello from SAMBA_SERVER';
      httpServer.registerRoute(
        Route(
          HttpMethod.get,
          httpServer.uri.path,
          handler: (_) => responseToSend,
        ),
      );
      http.Response response = await http.get(httpServer.uri);
      expect(response.statusCode, 200);
      expect(response.body, responseToSend);

      response = await http.get(Uri.parse('${httpServer.uri}/random'));
      expect(response.statusCode, 404);
    });

    tearDownAll(() => httpServer.shutdown());
  });
}
