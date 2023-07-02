import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

void main() {
  const address = '127.0.0.1';
  const port = 8080;

  final httpServer = HttpServer();

  group('Server start & stop tests', () {
    test('Server should be up & running', () async {
      await httpServer.bind(address: address, port: port);
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
}
