import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

import '../helpers/http_client.dart' as http_client;
import '../helpers/route_builder.dart';

void main() {
  const address = '127.0.0.1';
  const port = 8080;

  final httpClient = http_client.HttpClient(address: address, port: port);

  final httpServer = HttpServer();

  setUp(() async {
    await httpServer.bind(address: address, port: port);
    for (final httpMethod in HttpMethod.values) {
      httpServer.registerRoute(
        RouteBuilder(httpMethod, httpServer.uri.path, routeHandler: (_) {
          return Response.ok(body: httpMethod.name.toUpperCase());
        }),
      );
    }
  });

  tearDown(() async => await httpServer.shutdown());

  test('Should able to call all `GET`,`POST`,`PUT`,`PATCH`,`DELETE` methods',
      () async {
    httpServer.registerInterceptors((_) => [CrossOriginInterceptor()]);
    http_client.HttpResponse response = await httpClient.get(
      httpServer.uri.path,
    );
    expect(response.statusCode, 200);
    expect(response.body, 'GET');

    response = await httpClient.post(httpServer.uri.path);
    expect(response.statusCode, 200);
    expect(response.body, 'POST');

    response = await httpClient.put(httpServer.uri.path);
    expect(response.statusCode, 200);
    expect(response.body, 'PUT');

    response = await httpClient.patch(httpServer.uri.path);
    expect(response.statusCode, 200);
    expect(response.body, 'PATCH');

    response = await httpClient.delete(httpServer.uri.path);
    expect(response.statusCode, 200);
    expect(response.body, 'DELETE');
  });

  test('Should able to call only `GET`,`POST`,`PUT` methods', () async {
    httpServer.registerInterceptors(
      (_) => [
        CrossOriginInterceptor(
          httpMethodsToAllow: [
            HttpMethod.get,
            HttpMethod.put,
          ],
        ),
      ],
    );
    http_client.HttpResponse response = await httpClient.get(
      httpServer.uri.path,
    );
    expect(response.statusCode, 200);
    expect(response.body, 'GET');

    response = await httpClient.post(httpServer.uri.path);
    expect(response.statusCode, 405);
    expect(response.body, 'POST method is not allowed');

    response = await httpClient.put(httpServer.uri.path);
    expect(response.statusCode, 200);
    expect(response.body, 'PUT');

    response = await httpClient.patch(httpServer.uri.path);
    expect(response.statusCode, 405);
    expect(response.body, 'PATCH method is not allowed');

    response = await httpClient.delete(httpServer.uri.path);
    expect(response.statusCode, 405);
    expect(response.body, 'DELETE method is not allowed');
  });

  test('Should block pre-flights requests with `204` status code', () async {
    httpServer.registerInterceptors((_) => [CrossOriginInterceptor()]);
    http_client.HttpResponse response = await httpClient.options(
      httpServer.uri.path,
    );
    expect(response.statusCode, 204);
    expect(response.body, null);
  });

  test('Should send allow methods only for `OPTIONS` request', () async {
    httpServer.registerInterceptors((_) => [CrossOriginInterceptor()]);
    http_client.HttpResponse response = await httpClient.options(
      httpServer.uri.path,
    );
    expect(response.statusCode, 204);
    expect(
      response.headers['access-control-allow-methods'],
      ['GET,POST,PUT,PATCH,DELETE,OPTIONS'],
    );
    expect(response.body, null);

    response = await httpClient.post(
      httpServer.uri.path,
    );
    expect(response.statusCode, 200);
    expect(
      response.headers['access-control-allow-methods'],
      isNull,
    );
    expect(response.body, 'POST');
  });

  test('Should not block pre-flights requests', () async {
    httpServer.registerInterceptors(
      (_) => [
        CrossOriginInterceptor(shouldBlockPreflight: false),
      ],
    );

    http_client.HttpResponse response = await httpClient.options(
      httpServer.uri.path,
    );
    expect(response.statusCode, 200);
    expect(response.body, 'OPTIONS');
  });

  test('Should allow all origins', () async {
    httpServer.registerInterceptors((_) => [CrossOriginInterceptor()]);
    http_client.HttpResponse response = await httpClient.options(
      httpServer.uri.path,
    );
    expect(response.statusCode, 204);
    expect(response.headers['vary'], isNull);
    expect(response.headers['access-control-allow-origin'], ['*']);

    response = await httpClient.options(
      httpServer.uri.path,
      headers: {'origin': '*'},
    );
    expect(response.statusCode, 204);
    expect(response.headers['vary'], isNull);
    expect(response.headers['access-control-allow-origin'], ['*']);

    response = await httpClient.options(
      httpServer.uri.path,
      headers: {'origin': 'someRandom.org'},
    );
    expect(response.statusCode, 204);
    expect(response.headers['vary'], isNull);
    expect(response.headers['access-control-allow-origin'], ['*']);
  });

  test(
      'Should send origin specified in the request headers as a response header if we allow it (String)',
      () async {
    httpServer.registerInterceptors(
      (_) => [
        CrossOriginInterceptor(
          originsToAllow: ['someRandom.org', 'someOtherRandom.org'],
        ),
      ],
    );
    http_client.HttpResponse response = await httpClient.options(
      httpServer.uri.path,
      headers: {'origin': 'someRandom.org'},
    );
    expect(response.statusCode, 204);
    expect(response.headers['vary'], ['Origin']);
    expect(response.headers['access-control-allow-origin'], ['someRandom.org']);

    response = await httpClient.options(
      httpServer.uri.path,
      headers: {'origin': 'someOtherRandom.org'},
    );
    expect(response.statusCode, 204);
    expect(response.headers['vary'], ['Origin']);
    expect(
      response.headers['access-control-allow-origin'],
      ['someOtherRandom.org'],
    );

    response = await httpClient.options(
      httpServer.uri.path,
      headers: {'origin': '*'},
    );
    expect(response.statusCode, 204);
    expect(response.headers['vary'], isNull);
    expect(response.headers['access-control-allow-origin'], isNull);
  });

  test(
      'Should send origin specified in the request headers as a response header if we allow it (Regex)',
      () async {
    httpServer.registerInterceptors(
      (_) => [
        CrossOriginInterceptor(
          // allow any origin ends with `.in`
          originsToAllow: [RegExp(r'(.in)$')],
        ),
      ],
    );
    http_client.HttpResponse response = await httpClient.options(
      httpServer.uri.path,
      headers: {'origin': 'someRandom.in'},
    );
    expect(response.statusCode, 204);
    expect(response.headers['vary'], ['Origin']);
    expect(response.headers['access-control-allow-origin'], ['someRandom.in']);

    response = await httpClient.options(
      httpServer.uri.path,
      headers: {'origin': 'someOtherRandom.in'},
    );
    expect(response.statusCode, 204);
    expect(response.headers['vary'], ['Origin']);
    expect(
      response.headers['access-control-allow-origin'],
      ['someOtherRandom.in'],
    );

    response = await httpClient.options(
      httpServer.uri.path,
      headers: {'origin': 'someOtherRandom.org'},
    );
    expect(response.statusCode, 204);
    expect(response.headers['vary'], isNull);
    expect(response.headers['access-control-allow-origin'], isNull);
  });

  test(
      'Should send origin specified in the request headers as a response header if we allow it (String) & (Regex)',
      () async {
    httpServer.registerInterceptors(
      (_) => [
        CrossOriginInterceptor(
          originsToAllow: [
            'someRandom.org',
            // allow any origin ends with `.in`
            RegExp(r'(.in)$'),
          ],
        ),
      ],
    );
    http_client.HttpResponse response = await httpClient.options(
      httpServer.uri.path,
      headers: {'origin': 'someRandom.org'},
    );
    expect(response.statusCode, 204);
    expect(response.headers['vary'], ['Origin']);
    expect(
      response.headers['access-control-allow-origin'],
      ['someRandom.org'],
    );

    response = await httpClient.options(
      httpServer.uri.path,
      headers: {'origin': 'someOtherRandom.org'},
    );
    expect(response.statusCode, 204);
    expect(response.headers['vary'], isNull);
    expect(response.headers['access-control-allow-origin'], isNull);

    response = await httpClient.options(
      httpServer.uri.path,
      headers: {'origin': 'someRandom.in'},
    );
    expect(response.statusCode, 204);
    expect(response.headers['vary'], ['Origin']);
    expect(response.headers['access-control-allow-origin'], ['someRandom.in']);

    response = await httpClient.options(
      httpServer.uri.path,
      headers: {'origin': 'someOtherRandom.in'},
    );
    expect(response.statusCode, 204);
    expect(response.headers['vary'], ['Origin']);
    expect(
      response.headers['access-control-allow-origin'],
      ['someOtherRandom.in'],
    );
  });

  test('Should not contain `allow-credentials` header in response', () async {
    httpServer.registerInterceptors((_) => [CrossOriginInterceptor()]);
    http_client.HttpResponse response = await httpClient.options(
      httpServer.uri.path,
    );
    expect(response.statusCode, 204);
    expect(response.headers['access-control-allow-credentials'], isNull);
  });

  test('Should contain `allow-credentials` header in response', () async {
    httpServer.registerInterceptors(
      (_) => [
        CrossOriginInterceptor(
          shouldAllowCredentials: true,
        ),
      ],
    );
    http_client.HttpResponse response = await httpClient.options(
      httpServer.uri.path,
    );
    expect(response.statusCode, 204);
    expect(response.headers['access-control-allow-credentials'], ['true']);
  });

  test('Should not contain `max-age` header in response', () async {
    httpServer.registerInterceptors((_) => [CrossOriginInterceptor()]);
    http_client.HttpResponse response = await httpClient.options(
      httpServer.uri.path,
    );
    expect(response.statusCode, 204);
    expect(response.headers['access-control-max-age'], isNull);
  });

  test('Should contain `max-age` header in response only for `OPTIONS` request',
      () async {
    httpServer.registerInterceptors(
      (_) => [
        CrossOriginInterceptor(
          maxAge: const Duration(minutes: 10),
        ),
      ],
    );
    http_client.HttpResponse response = await httpClient.options(
      httpServer.uri.path,
    );
    expect(response.statusCode, 204);
    expect(response.headers['access-control-max-age'], ['600']);

    response = await httpClient.delete(
      httpServer.uri.path,
    );
    expect(response.statusCode, 200);
    expect(response.headers['access-control-max-age'], isNull);
  });
}
