import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

import '../helpers/http_client.dart' as http_client;
import '../helpers/interceptor_builder.dart';
import '../helpers/route_builder.dart';

void main() {
  const address = '127.0.0.1';
  const port = 8080;

  final httpClient = http_client.HttpClient(address: address, port: port);

  final httpServer = HttpServer();

  setUpAll(() => httpServer.bind(address: address, port: port));

  tearDownAll(() => httpServer.shutdown());

  group('Interceptor `onInit` group tests', () {
    test('Should call single interceptor `onInit` before handling route',
        () async {
      final responseToGet = Response.ok(body: 'Headers cleared successfully');
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          '${httpServer.uri.path}/on-init-interceptor',
          interceptorsBuilder: (_) => [
            // clear headers interceptor
            InterceptorBuilder(onInitHandler: (request) {
              expect(request.headers, isNotEmpty);
              request.headers.clear();
              return null;
            }),
          ],
          routeHandler: (request) {
            expect(request.headers, isEmpty);
            return responseToGet;
          },
        ),
      );
      final response = await httpClient.post(
        '${httpServer.uri.path}/on-init-interceptor',
      );
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, responseToGet.body);
    });

    test('Should call multiple interceptors `onInit` before handling route',
        () async {
      final responseToGet = Response.ok(body: 'Headers cleared successfully');
      final headers = <String, String>{};
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          '${httpServer.uri.path}/multi-on-init-interceptor',
          interceptorsBuilder: (_) => [
            // clear headers interceptor
            InterceptorBuilder(onInitHandler: (request) {
              expect(request.headers, isNotEmpty);
              headers.addAll(request.headers);
              request.headers.clear();
              return null;
            }),
            // re-insert headers interceptor
            InterceptorBuilder(onInitHandler: (request) {
              expect(request.headers, isEmpty);
              request.headers.addAll(headers);
              return null;
            }),
            // clear headers interceptor
            InterceptorBuilder(onInitHandler: (request) {
              expect(request.headers, isNotEmpty);
              headers.addAll(request.headers);
              request.headers.clear();
              return null;
            })
          ],
          routeHandler: (request) {
            expect(request.headers, isEmpty);
            return responseToGet;
          },
        ),
      );
      final response = await httpClient.post(
        '${httpServer.uri.path}/multi-on-init-interceptor',
      );
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, responseToGet.body);
    });

    test(
        'Should not handle route because response returned by interceptor via `onInit`',
        () async {
      final responseToGet = Response.ok(
        body: 'I am from onInit of interceptor',
      );
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          '${httpServer.uri.path}/should-not-handle-route-on-init',
          interceptorsBuilder: (_) => [
            InterceptorBuilder(onInitHandler: (_) {
              return responseToGet;
            }),
          ],
          routeHandler: (request) {
            expectLater(true, isFalse);
            return Response.ok(body: 'I am from route');
          },
        ),
      );
      final response = await httpClient.post(
        '${httpServer.uri.path}/should-not-handle-route-on-init',
      );
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, responseToGet.body);
    });
  });

  group('Interceptor `onDispose` group tests', () {
    test('Should call single interceptor `onDispose` after handling route',
        () async {
      final responseToGet = Response.notFound(
        body: 'I am from onDispose of interceptor',
      );
      final responseByRouteHandler = Response.created(
        body: 'I am from route handler',
      );
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          '${httpServer.uri.path}/on-dispose-interceptor',
          interceptorsBuilder: (_) => [
            InterceptorBuilder(onDisposeHandler: (_, response) {
              expect(response.statusCode, responseByRouteHandler.statusCode);
              expect(response.body, responseByRouteHandler.body);
              return responseToGet;
            }),
          ],
          routeHandler: (_) {
            return Response.created(body: 'I am from route handler');
          },
        ),
      );
      final response = await httpClient.post(
        '${httpServer.uri.path}/on-dispose-interceptor',
      );
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, responseToGet.body);
    });

    test('Should call multiple interceptor `onDispose` after handling route',
        () async {
      final responseByRouteHandler = Response.created(
        body: 'I am from route handler',
      );
      final responseFrom1stInterceptor = Response.created(
        body: 'Response from 1st interceptor',
      );
      final responseFrom2ndInterceptor = Response.created(
        body: 'Response from 2nd interceptor',
      );
      final responseFrom3rdInterceptor = Response.created(
        body: 'Response from 3rd interceptor',
      );
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          '${httpServer.uri.path}/multi-on-dispose-interceptor',
          interceptorsBuilder: (_) => [
            InterceptorBuilder(onDisposeHandler: (_, response) {
              expect(
                  response.statusCode, responseFrom2ndInterceptor.statusCode);
              expect(response.body, responseFrom2ndInterceptor.body);
              return responseFrom1stInterceptor;
            }),
            InterceptorBuilder(onDisposeHandler: (_, response) {
              expect(
                response.statusCode,
                responseFrom3rdInterceptor.statusCode,
              );
              expect(response.body, responseFrom3rdInterceptor.body);
              return responseFrom2ndInterceptor;
            }),
            InterceptorBuilder(onDisposeHandler: (_, response) {
              expect(
                response.statusCode,
                responseByRouteHandler.statusCode,
              );
              expect(response.body, responseByRouteHandler.body);
              return responseFrom3rdInterceptor;
            }),
          ],
          routeHandler: (_) {
            return responseByRouteHandler;
          },
        ),
      );
      final response = await httpClient.post(
        '${httpServer.uri.path}/multi-on-dispose-interceptor',
      );
      expect(response.statusCode, responseFrom1stInterceptor.statusCode);
      expect(response.body, responseFrom1stInterceptor.body);
    });

    test(
        'Should call `onDispose` of interceptor without handling route because response returned by interceptor via `onInit`',
        () async {
      final responseFromOnInitInterceptor = Response.ok(
        body: 'I am from onInit of interceptor',
      );
      final responseToGet = Response.ok(
        body: 'I am from onDispose of interceptor',
      );
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          '${httpServer.uri.path}/should-not-handle-route-on-dispose',
          interceptorsBuilder: (_) => [
            InterceptorBuilder(onInitHandler: (_) {
              return responseFromOnInitInterceptor;
            }, onDisposeHandler: (_, response) {
              expect(
                response.statusCode,
                responseFromOnInitInterceptor.statusCode,
              );
              expect(response.body, responseFromOnInitInterceptor.body);
              return responseToGet;
            }),
          ],
          routeHandler: (_) {
            expectLater(true, isFalse);
            return Response.ok(body: 'I am from route');
          },
        ),
      );
      final response = await httpClient.post(
        '${httpServer.uri.path}/should-not-handle-route-on-dispose',
      );
      expect(response.statusCode, responseToGet.statusCode);
      expect(response.body, responseToGet.body);
    });

    test(
        'Should call `onDispose` of multiple interceptors who\'s `onInit` has been invoked without handling route because response returned by interceptor via `onInit`',
        () async {
      final responseFrom1stInterceptor = Response.created(
        body: 'Response from 1st interceptor',
      );
      final responseFrom2ndInterceptor = Response.created(
        body: 'Response from 2nd interceptor',
      );
      final responseFrom3rdInterceptor = Response.created(
        body: 'Response from 3rd interceptor',
      );
      final responseFromOnInitInterceptor = Response.ok(
        body: 'I am from onInit of interceptor',
      );
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          '${httpServer.uri.path}/should-not-handle-route-multiple-on-dispose',
          interceptorsBuilder: (_) => [
            InterceptorBuilder(onDisposeHandler: (_, response) {
              expect(
                response.statusCode,
                responseFrom2ndInterceptor.statusCode,
              );
              expect(response.body, responseFrom2ndInterceptor.body);
              return responseFrom1stInterceptor;
            }),
            InterceptorBuilder(onInitHandler: (_) {
              return responseFromOnInitInterceptor;
            }, onDisposeHandler: (_, response) {
              expect(
                response.statusCode,
                responseFromOnInitInterceptor.statusCode,
              );
              expect(response.body, responseFromOnInitInterceptor.body);
              return responseFrom2ndInterceptor;
            }),
            InterceptorBuilder(onInitHandler: (_) {
              expectLater(true, isFalse);
              return null;
            }, onDisposeHandler: (_, response) {
              expectLater(true, isFalse);
              return responseFrom3rdInterceptor;
            }),
          ],
          routeHandler: (_) {
            expectLater(true, isFalse);
            return Response.ok(body: 'I am from route');
          },
        ),
      );
      final response = await httpClient.post(
        '${httpServer.uri.path}/should-not-handle-route-multiple-on-dispose',
      );
      expect(response.statusCode, responseFrom1stInterceptor.statusCode);
      expect(response.body, responseFrom1stInterceptor.body);
    });
  });
}
