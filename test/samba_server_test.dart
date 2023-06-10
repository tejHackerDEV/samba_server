import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

void main() {
  group('Server start & stop tests', () {
    final httpServer = HttpServer();

    test('Server should be up & running', () async {
      await httpServer.bind(address: '127.0.0.1', port: 8080);
      expect(httpServer.isRunning, isTrue);
    });

    test('Server should be shutdown', () async {
      await httpServer.shutdown();
      expect(httpServer.isRunning, isFalse);
    });
  });
}
