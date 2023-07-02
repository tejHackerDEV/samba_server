import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

import 'helpers/http_client.dart' as http_client;
import 'helpers/route_builder.dart';

void main() {
  const address = '127.0.0.1';
  const port = 8080;

  final httpClient = http_client.HttpClient(address: address, port: port);

  final httpServer = HttpServer();

  setUp(() async => await httpServer.bind(address: address, port: port));

  tearDown(() async => await httpServer.shutdown());

  group('Incoming requests tests', () {
    test('Server should listen to incoming requests', () async {
      Response responseToGet = Response.ok(body: 'Hello from SAMBA_SERVER');
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.get,
          httpServer.uri.path,
          routeHandler: (_) => responseToGet,
        ),
      );
      http_client.HttpResponse response = await httpClient.get(
        httpServer.uri.path,
      );
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

  group('PathParameters tests', () {
    test(
        'Server should able to decode dynamic pathParameters for incoming requests',
        () async {
      httpServer
        ..registerRoute(
          RouteBuilder(
            HttpMethod.get,
            '${httpServer.uri.path}/users/{id}',
            routeHandler: (request) {
              expect(request.pathParameters.length, 1);
              return Response.ok(body: request.pathParameters);
            },
          ),
        )
        ..registerRoute(
          RouteBuilder(
            HttpMethod.post,
            '${httpServer.uri.path}/users/{id}',
            routeHandler: (request) {
              expect(request.pathParameters.length, 1);
              return Response.created(body: request.pathParameters);
            },
          ),
        )
        ..registerRoute(
          RouteBuilder(
            HttpMethod.get,
            '${httpServer.uri.path}/india/{state:^[a-zA-z0-9]+\$}',
            routeHandler: (request) {
              expect(request.pathParameters.length, 1);
              return Response.ok(body: request.pathParameters);
            },
          ),
        )
        ..registerRoute(
          RouteBuilder(
            HttpMethod.get,
            '${httpServer.uri.path}/india/{state:^[a-zA-z0-9]+\$}/kadapa/*',
            routeHandler: (request) {
              expect(request.pathParameters.length, 2);
              return Response.ok(body: request.pathParameters);
            },
          ),
        )
        ..registerRoute(
          RouteBuilder(
            HttpMethod.get,
            '${httpServer.uri.path}/{route:^[a-zA-z0-9]+\$}/{id}/*',
            routeHandler: (request) {
              expect(request.pathParameters.length, 3);
              return Response.ok(body: request.pathParameters);
            },
          ),
        );
      http_client.HttpResponse response = await httpClient.get(
        '${httpServer.uri.path}/users/1234',
      );
      expect(response.statusCode, 200);
      expect(response.body, '{id: 1234}');

      response = await httpClient.post(
        '${httpServer.uri.path}/users/1234',
      );
      expect(response.statusCode, 201);
      expect(response.body, '{id: 1234}');

      response = await httpClient.get(
        '${httpServer.uri.path}/india/AndhraPradesh',
      );
      expect(response.statusCode, 200);
      expect(response.body, '{state: AndhraPradesh}');

      response = await httpClient.get(
        '${httpServer.uri.path}/india/AndhraPradesh/kadapa/bhagyanagarcolony',
      );
      expect(response.statusCode, 200);
      expect(response.body, '{state: AndhraPradesh, *: bhagyanagarcolony}');

      response = await httpClient.get(
        '${httpServer.uri.path}/users/1234/metaData/country',
      );
      expect(response.statusCode, 200);
      expect(response.body, '{route: users, id: 1234, *: metaData/country}');
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
