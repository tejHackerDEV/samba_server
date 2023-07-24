import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

import 'helpers/http_client.dart' as http_client;
import 'helpers/route_builder.dart';

void main() {
  const address = '127.0.0.1';
  const port = 8080;

  final httpClient = http_client.HttpClient(address: address, port: port);

  final httpServer = HttpServer();
  final userHandledResponse = Response.internalServerError(
    body: 'I am handled by user',
  );

  setUp(() async {
    httpServer.registerErrorHandler((request, __, ___, ____) {
      if (request?.queryParameters.isNotEmpty == true) {
        throw AssertionError();
      }
      return userHandledResponse;
    });
    await httpServer.bind(address: address, port: port);
  });

  tearDown(() async => await httpServer.shutdown());

  group('Server error handling tests by user', () {
    test('Should able to handle error by user (synchronous)', () async {
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.get,
          httpServer.uri.path,
          routeHandler: (_) {
            throw AssertionError();
          },
        ),
      );
      final response = await httpClient.get(httpServer.uri.path);
      expect(response.statusCode, userHandledResponse.statusCode);
      expect(response.body, userHandledResponse.body);
    });

    test('Should able to handle error by user (non-synchronous)', () async {
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.get,
          httpServer.uri.path,
          routeHandler: (_) async {
            throw AssertionError();
          },
        ),
      );
      final response = await httpClient.get(httpServer.uri.path);
      expect(response.statusCode, userHandledResponse.statusCode);
      expect(response.body, userHandledResponse.body);
    });

    test('Should able to handle error thrown by userErrorHandler', () async {
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.get,
          httpServer.uri.path,
          routeHandler: (request) async {
            request.queryParameters['something'] = 1234;
            throw AssertionError();
          },
        ),
      );
      final response = await httpClient.get(httpServer.uri.path);
      expect(response.statusCode, 500);
      expect(response.body, 'Something went wrong, please try again later.');
    });
  });
}
