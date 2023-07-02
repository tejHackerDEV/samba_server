import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

import '../helpers/route_builder.dart';

void main() {
  group('RegExpParametric Routes tests', () {
    final router = Router();
    final routesToRegister = [
      RouteBuilder(HttpMethod.get, '/users/{id:^[0-9]+\$}', routeHandler: (_) {
        return Response.ok(
          body: 'Get user data but his/her id should contain only numbers',
        );
      }),
      RouteBuilder(HttpMethod.get, '/users/{id:^[a-z]+\$}/logout',
          routeHandler: (_) {
        return Response.ok(
          body:
              'Logout a user but his/her id should contain only small letters',
        );
      }),
      RouteBuilder(HttpMethod.get, '/users/{id:^[A-Z]+\$}/logout',
          routeHandler: (_) {
        return Response.ok(
          body:
              'Logout a user but his/her id should contain only capital letters',
        );
      }),
      RouteBuilder(
        HttpMethod.get,
        '/users/{id:^[A-Z0-9a-z]+\$}/logout',
        routeHandler: (_) {
          return Response.ok(
            body:
                'Logout a user but his/her id may contains small, capital letters & numbers',
          );
        },
      ),
    ];

    setUp(() {
      for (final route in routesToRegister) {
        router.register(route);
      }
    });

    tearDown(() => router.reset());

    test('Should able to register routes', () {
      expect(router.routes, routesToRegister);
    });

    test('Should able to lookup routes by path', () {
      LookupResult lookupResult = router.lookup(HttpMethod.get, '/users/1234');
      expect(lookupResult.pathParameters, {'id': '1234'});
      expect(lookupResult.route, routesToRegister[0]);

      lookupResult = router.lookup(HttpMethod.get, '/users/someuserid/logout');
      expect(lookupResult.pathParameters, {'id': 'someuserid'});
      expect(lookupResult.route, routesToRegister[1]);

      lookupResult = router.lookup(HttpMethod.get, '/users/SOMEUSERID/logout');
      expect(lookupResult.pathParameters, {'id': 'SOMEUSERID'});
      expect(lookupResult.route, routesToRegister[2]);

      lookupResult = router.lookup(
        HttpMethod.get,
        '/users/someUserId1234/logout',
      );
      expect(lookupResult.pathParameters, {'id': 'someUserId1234'});
      expect(lookupResult.route, routesToRegister[3]);
    });

    test('Should not be able to lookup routes by path', () {
      expect(router.lookup(HttpMethod.get, 'random').route, isNull);
      expect(router.lookup(HttpMethod.get, '/random').route, isNull);
      expect(router.lookup(HttpMethod.get, '/random/random').route, isNull);
      expect(
          router.lookup(HttpMethod.get, '/users/someUserId1234').route, isNull);
    });
  });
}
