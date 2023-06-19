import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

import '../helpers/route_builder.dart';

void main() {
  group('NonRegExpParametric Routes tests', () {
    final router = Router();
    final routesToRegister = [
      RouteBuilder(HttpMethod.get, '/users/{id}', routeHandler: (_) {
        return Response.ok(body: 'Get user data');
      }),
      RouteBuilder(HttpMethod.get, '/users/{id}/logout', routeHandler: (_) {
        return Response.ok(body: 'Logout user');
      }),
      RouteBuilder(HttpMethod.get, '/profiles/{id}', routeHandler: (_) {
        return Response.ok(body: 'Get profile data');
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
      expect(
        router.lookup(HttpMethod.get, '/users/someUserId'),
        routesToRegister[0],
      );
      expect(
        router.lookup(HttpMethod.get, '/users/someUserId/logout'),
        routesToRegister[1],
      );
      expect(
        router.lookup(HttpMethod.get, '/profiles/someProfileId'),
        routesToRegister[2],
      );
    });

    test('Should not be able to lookup routes by path', () {
      expect(router.lookup(HttpMethod.get, 'random'), isNull);
      expect(router.lookup(HttpMethod.get, '/random'), isNull);
      expect(router.lookup(HttpMethod.get, '/random/random'), isNull);
    });
  });
}
