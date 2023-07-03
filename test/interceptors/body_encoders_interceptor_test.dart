import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

import '../helpers/http_client.dart' as http_client;
import '../helpers/route_builder.dart';

void main() {
  const address = '127.0.0.1';
  const port = 8080;

  final httpClient = http_client.HttpClient(address: address, port: port);

  final applicationJson = 'application/json';
  final plainText = 'text/plain';

  final httpServer = HttpServer(shouldEnableDefaultResponseEncoders: false);

  setUp(() async => await httpServer.bind(address: address, port: port));

  tearDown(() async => await httpServer.shutdown());

  group('StringResponseEncoder tests', () {
    test('Should able to encode `String` data-type', () async {
      final responseBody = 'I am plain body';
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [StringResponseEncoder()],
          routeHandler: (_) {
            return Response.created(body: responseBody);
          },
        ),
      );
      http_client.HttpResponse httpResponse = await httpClient.post(
        httpServer.uri.path,
      );
      expect(httpResponse.headers['content-type'], [plainText]);
      expect(httpResponse.body, responseBody);
    });

    test('Should not able to encode data-type other than `String`', () async {
      final responseBody = {'id': 1234};
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [StringResponseEncoder()],
          routeHandler: (_) {
            return Response.created(body: responseBody);
          },
        ),
      );
      http_client.HttpResponse httpResponse = await httpClient.post(
        httpServer.uri.path,
      );
      expect(httpResponse.body, isNot(responseBody));
    });
  });

  group('NumResponseEncoder tests', () {
    test('Should able to encode `num` data-type', () async {
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.get,
          '${httpServer.uri.path}/{id:^[0-9]+\$}',
          interceptorsBuilder: (_) => [NumResponseEncoder()],
          routeHandler: (request) {
            return Response.ok(
              body: num.parse(request.pathParameters['id'].toString()),
            );
          },
        ),
      );
      http_client.HttpResponse httpResponse = await httpClient.get(
        '${httpServer.uri.path}/1234',
      );
      expect(httpResponse.headers['content-type'], [plainText]);
      expect(httpResponse.body, '1234');
    });

    test('Should not able to encode non `num` data-type', () async {
      final responseBody = {'id': 1234};
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.get,
          '${httpServer.uri.path}/{id:^[0-9]+\$}',
          interceptorsBuilder: (_) => [NumResponseEncoder()],
          routeHandler: (request) {
            return Response.ok(body: responseBody);
          },
        ),
      );
      http_client.HttpResponse httpResponse = await httpClient.get(
        '${httpServer.uri.path}/1234',
      );
      expect(httpResponse.body, isNot(responseBody));
    });
  });

  group('BoolResponseEncoder tests', () {
    test('Should able to encode `bool` data-type', () async {
      final responseBody = true;
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.get,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [BoolResponseEncoder()],
          routeHandler: (request) {
            return Response.ok(body: responseBody);
          },
        ),
      );
      http_client.HttpResponse httpResponse = await httpClient.get(
        httpServer.uri.path,
      );
      expect(httpResponse.headers['content-type'], [plainText]);
      expect(httpResponse.body, responseBody.toString());
    });

    test('Should not able to encode non `bool` data-type', () async {
      final responseBody = {'id': 1234};
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.get,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [BoolResponseEncoder()],
          routeHandler: (request) {
            return Response.created(body: responseBody);
          },
        ),
      );
      http_client.HttpResponse httpResponse = await httpClient.get(
        httpServer.uri.path,
      );
      expect(httpResponse.body, isNot(responseBody));
    });
  });

  group('JsonListResponseEncoder tests', () {
    final responseBody = [1, 2, 3, 4, 5];
    test('Should able to encode `Iterable<dynamic>` data-type', () async {
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.get,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [JsonListResponseEncoder()],
          routeHandler: (_) {
            return Response.created(body: responseBody);
          },
        ),
      );
      http_client.HttpResponse httpResponse = await httpClient.get(
        httpServer.uri.path,
      );
      expect(httpResponse.headers['content-type'], [applicationJson]);
      expect(httpResponse.body, responseBody);
    });

    test('Should not able to encode non `Iterable<dynamic>` data-type',
        () async {
      final responseBody = [1, 2, 3, 4, 5];
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.get,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [JsonListResponseEncoder()],
          routeHandler: (_) {
            return Response.created(
              body: '$responseBody',
            );
          },
        ),
      );
      http_client.HttpResponse httpResponse = await httpClient.get(
        httpServer.uri.path,
      );
      expect(httpResponse.body, isNot(responseBody));
    });
  });

  group('JsonMapResponseEncoder tests', () {
    test('Should able to encode `Map<String, dynamic>` data-type', () async {
      final responseBody = {
        'data': [1, 2, 3, 4, 5]
      };
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.get,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [JsonMapResponseEncoder()],
          routeHandler: (_) {
            return Response.created(body: responseBody);
          },
        ),
      );
      http_client.HttpResponse httpResponse = await httpClient.get(
        httpServer.uri.path,
      );
      expect(httpResponse.headers['content-type'], [applicationJson]);
      expect(httpResponse.body, responseBody);
    });

    test('Should not able to encode non `Iterable<dynamic>` data-type',
        () async {
      final responseBody = [1, 2, 3, 4, 5];
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.get,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [JsonMapResponseEncoder()],
          routeHandler: (_) {
            return Response.created(
              body: responseBody,
            );
          },
        ),
      );
      http_client.HttpResponse httpResponse = await httpClient.get(
        httpServer.uri.path,
      );
      expect(httpResponse.body, isNot(responseBody));
    });
  });

  group('MultipleResponseEncoders tests', () {
    test('Should able to encode by only one encoder only', () async {
      final responseBody = {
        'data': [1, 2, 3, 4, 5]
      };
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [
            StringResponseEncoder(),
            JsonMapResponseEncoder(),
          ],
          routeHandler: (_) {
            return Response.created(body: responseBody);
          },
        ),
      );
      http_client.HttpResponse httpResponse = await httpClient.post(
        httpServer.uri.path,
      );
      expect(httpResponse.headers['content-type'], [applicationJson]);
      expect(httpResponse.body, responseBody);
    });
  });
}
