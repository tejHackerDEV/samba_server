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
      Response responseToGet = Response.ok(body: 'Hello from SAMBA_SERVER');
      httpServer.registerRoute(
        Route(
          HttpMethod.get,
          httpServer.uri.path,
          handler: (_, __) => responseToGet,
        ),
      );
      http.Response response = await http.get(httpServer.uri);
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, responseToGet.body);

      response = await http.get(Uri.parse('${httpServer.uri}/random'));
      expect(response.statusCode, 404);

      responseToGet = Response.created(body: 'Created by SAMBA_SERVER');
      httpServer.registerRoute(
        Route(
          HttpMethod.post,
          httpServer.uri.path,
          handler: (_, __) => responseToGet,
        ),
      );
      response = await http.post(httpServer.uri);
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, responseToGet.body);

      responseToGet = Response.ok(body: 'Put by SAMBA_SERVER');
      httpServer.registerRoute(
        Route(
          HttpMethod.put,
          httpServer.uri.path,
          handler: (_, __) => responseToGet,
        ),
      );
      response = await http.put(httpServer.uri);
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, responseToGet.body);

      responseToGet = Response.ok(body: 'Patched by SAMBA_SERVER');
      httpServer.registerRoute(
        Route(
          HttpMethod.patch,
          httpServer.uri.path,
          handler: (_, __) => responseToGet,
        ),
      );
      response = await http.patch(httpServer.uri);
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, responseToGet.body);

      responseToGet = Response.ok(body: 'Deleted by SAMBA_SERVER');
      httpServer.registerRoute(
        Route(
          HttpMethod.delete,
          httpServer.uri.path,
          handler: (_, __) => responseToGet,
        ),
      );
      response = await http.delete(httpServer.uri);
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, responseToGet.body);

      responseToGet = Response.noContent();
      httpServer.registerRoute(
        Route(
          HttpMethod.get,
          '${httpServer.uri.path}/no-content',
          handler: (_, __) => responseToGet,
        ),
      );
      response = await http.get(Uri.parse('http://$address:$port/no-content'));
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, isEmpty);
    });

    test(
        'Should not contain any body as response has status code of No-Content (204) ',
        () async {
      final responseToGet = Response(
        statusCode: 204,
        body: 'I wont be included in the body',
      );
      httpServer.registerRoute(
        Route(
          HttpMethod.put,
          '${httpServer.uri.path}/no-content',
          handler: (_, __) => responseToGet,
        ),
      );
      final response = await http.put(
        Uri.parse('http://$address:$port/no-content'),
      );
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, isEmpty);
    });

    tearDownAll(() => httpServer.shutdown());
  });
}
