import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

import 'helpers/http_client.dart' as http_client;
import 'helpers/route_builder.dart';

void main() {
  const address = '127.0.0.1';
  const port = 8080;

  final httpClient = http_client.HttpClient(address: address, port: port);

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

    tearDownAll(() => httpServer.shutdown());

    test('Server should listen to incoming requests', () async {
      Response responseToGet = Response.ok(body: 'Hello from SAMBA_SERVER');
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.get,
          httpServer.uri.path,
          routeHandler: (_) => responseToGet,
        ),
      );
      http_client.HttpResponse response =
          await httpClient.get(httpServer.uri.path);
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, responseToGet.body);

      response = await httpClient.get('${httpServer.uri.path}/random');
      expect(response.statusCode, 404);

      responseToGet = Response.created(body: 'Created by SAMBA_SERVER');
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          httpServer.uri.path,
          routeHandler: (_) => responseToGet,
        ),
      );
      response = await httpClient.post(httpServer.uri.path);
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, responseToGet.body);

      responseToGet = Response.ok(body: 'Put by SAMBA_SERVER');
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.put,
          httpServer.uri.path,
          routeHandler: (_) => responseToGet,
        ),
      );
      response = await httpClient.put(httpServer.uri.path);
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, responseToGet.body);

      responseToGet = Response.ok(body: 'Patched by SAMBA_SERVER');
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.patch,
          httpServer.uri.path,
          routeHandler: (_) => responseToGet,
        ),
      );
      response = await httpClient.patch(httpServer.uri.path);
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, responseToGet.body);

      responseToGet = Response.ok(body: 'Deleted by SAMBA_SERVER');
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.delete,
          httpServer.uri.path,
          routeHandler: (_) => responseToGet,
        ),
      );
      response = await httpClient.delete(httpServer.uri.path);
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, responseToGet.body);

      responseToGet = Response.noContent();
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.get,
          '${httpServer.uri.path}/no-content',
          routeHandler: (_) => responseToGet,
        ),
      );
      response = await httpClient.get('${httpServer.uri.path}/no-content');
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, isNull);
    });

    test(
        'Should not contain any body as response has status code of No-Content (204) ',
        () async {
      final responseToGet = Response(
        statusCode: 204,
        body: 'I wont be included in the body',
      );
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.put,
          '${httpServer.uri.path}/no-content',
          routeHandler: (_) => responseToGet,
        ),
      );
      final response =
          await httpClient.put('${httpServer.uri.path}/no-content');
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, isNull);
    });
  });
}
