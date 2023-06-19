import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

import '../helpers/route_builder.dart';

void main() {
  group('Router tests', () {
    final router = Router();
    final routesToRegister = [
      RouteBuilder(HttpMethod.get, '/users', routeHandler: (_) {
        return Response.ok(body: 'Get users data');
      }),
      RouteBuilder(HttpMethod.get, '/users/id', routeHandler: (_) {
        return Response.ok(body: 'Get user data who\'s id is id');
      }),
      RouteBuilder(HttpMethod.get, '/users/{id}', routeHandler: (_) {
        return Response.ok(body: 'Get a user data');
      }),
      RouteBuilder(
        HttpMethod.get,
        '/users/{id:^[0-9]+\$}/logout',
        routeHandler: (_) {
          return Response.ok(
            body: 'Logout a user but his/her id should contain only numbers',
          );
        },
      ),
      RouteBuilder(HttpMethod.get, '/profiles', routeHandler: (_) {
        return Response.ok(body: 'Get profiles data');
      }),
      RouteBuilder(HttpMethod.get, '/profiles/{id}', routeHandler: (_) {
        return Response.ok(body: 'Get a profile data');
      }),
      RouteBuilder(HttpMethod.get, '/profiles/{id}/*', routeHandler: (_) {
        return Response.ok(
          body: 'Handle any get routes that goes after the profileId',
        );
      }),
      RouteBuilder(
        HttpMethod.get,
        '/profiles/{id:^[0-9]+\$}/*',
        routeHandler: (_) {
          return Response.ok(
            body: 'Get a profile but his/her id should contain only numbers',
          );
        },
      ),
    ];

    setUp(() {
      for (final route in routesToRegister) {
        router.register(route);
      }
    });

    test('Should able to lookup routes by path', () {
      expect(
        router.lookup(HttpMethod.get, routesToRegister[0].path),
        routesToRegister[0],
      );
      expect(
        router.lookup(HttpMethod.get, routesToRegister[1].path),
        routesToRegister[1],
      );
      expect(
        router.lookup(HttpMethod.get, '/users/someUserId'),
        routesToRegister[2],
      );
      expect(
        router.lookup(HttpMethod.get, '/users/1234/logout'),
        routesToRegister[3],
      );
      expect(
        router.lookup(HttpMethod.get, routesToRegister[4].path),
        routesToRegister[4],
      );
      expect(
        router.lookup(HttpMethod.get, '/profiles/someProfileId'),
        routesToRegister[5],
      );
      expect(
        router.lookup(HttpMethod.get, '/profiles/random/anotherRandom'),
        routesToRegister[6],
      );
      expect(
        router.lookup(HttpMethod.get, '/profiles/1234/anotherRandom'),
        routesToRegister[7],
      );
    });

    test('Should able to lookup routes based on their priority order', () {
      final wildcardRoute = RouteBuilder(
        HttpMethod.get,
        '/priority/*',
        routeHandler: (_) {
          return Response.ok(
            body: 'Handle any get routes that goes after the priority',
          );
        },
      );
      final nonRegExpParametricRoute = RouteBuilder(
        HttpMethod.get,
        '/priority/{id}',
        routeHandler: (_) {
          return Response.ok(body: 'Get a priority data');
        },
      );
      final regExpParametricRoute = RouteBuilder(
        HttpMethod.get,
        '/priority/{id:^[0-9]+\$}',
        routeHandler: (_) {
          return Response.ok(
            body: 'Get a priority data but its id should contain only numbers',
          );
        },
      );
      final staticRoute = RouteBuilder(
        HttpMethod.get,
        '/priority/id',
        routeHandler: (_) {
          return Response.ok(body: 'Get priority data who\'s id is id');
        },
      );
      router
        ..register(wildcardRoute)
        ..register(nonRegExpParametricRoute)
        ..register(regExpParametricRoute)
        ..register(staticRoute);
      expect(router.lookup(HttpMethod.get, '/priority/id'), staticRoute);
      expect(
        router.lookup(HttpMethod.get, '/priority/parametricId'),
        nonRegExpParametricRoute,
      );
      expect(
        router.lookup(HttpMethod.get, '/priority/1234'),
        regExpParametricRoute,
      );
      expect(
        router.lookup(HttpMethod.get, '/priority/1234/random'),
        wildcardRoute,
      );
      expect(
        router.lookup(HttpMethod.get, '/priority/parametricId/random'),
        wildcardRoute,
      );
    });

    test('Should not be able to lookup routes by path', () {
      expect(router.lookup(HttpMethod.get, 'random'), isNull);
      expect(router.lookup(HttpMethod.get, '/random'), isNull);
      expect(router.lookup(HttpMethod.get, '/random/random'), isNull);
      expect(router.lookup(HttpMethod.get, '/users/someUserId/logout'), isNull);
    });
  });
}
