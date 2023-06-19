import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

import '../helpers/route_builder.dart';

void main() {
  group('Static Routes tests', () {
    final router = Router();
    final routesToRegister = [
      RouteBuilder(HttpMethod.get, '/users', routeHandler: (_) {
        return Response.ok(body: 'Get users data');
      }),
      RouteBuilder(HttpMethod.get, '/users/id', routeHandler: (_) {
        return Response.ok(body: 'Get user data who\'s id is id');
      }),
      RouteBuilder(HttpMethod.get, '/profiles', routeHandler: (_) {
        return Response.ok(body: 'Get profiles data');
      }),
    ];

    setUp(() {
      for (final route in routesToRegister) {
        router.register(route);
      }
    });

    test('Should able to register routes', () {
      expect(router.routes, routesToRegister);
    });

    test('Should able to lookup routes by path', () {
      for (final route in routesToRegister) {
        expect(router.lookup(HttpMethod.get, route.path), route);
      }
    });

    test('Should not be able to lookup routes by path', () {
      expect(router.lookup(HttpMethod.get, 'random'), isNull);
      expect(router.lookup(HttpMethod.get, '/random'), isNull);
      expect(router.lookup(HttpMethod.get, '/random/random'), isNull);
    });
  });
}
