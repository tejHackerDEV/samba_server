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
      LookupResult? lookupResult = router.lookup(
        HttpMethod.get,
        routesToRegister[0].path,
      );
      expect(lookupResult?.pathParameters, isEmpty);
      expect(lookupResult?.route, routesToRegister[0]);

      lookupResult = router.lookup(HttpMethod.get, routesToRegister[1].path);
      expect(lookupResult?.pathParameters, isEmpty);
      expect(lookupResult?.route, routesToRegister[1]);

      lookupResult = router.lookup(HttpMethod.get, '/users/someUserId');
      expect(
        lookupResult?.pathParameters,
        {'id': 'someUserId'},
      );
      expect(lookupResult?.route, routesToRegister[2]);

      lookupResult = router.lookup(HttpMethod.get, '/users/1234/logout');
      expect(
        lookupResult?.pathParameters,
        {'id': '1234'},
      );
      expect(lookupResult?.route, routesToRegister[3]);

      lookupResult = router.lookup(HttpMethod.get, routesToRegister[4].path);
      expect(lookupResult?.pathParameters, isEmpty);
      expect(lookupResult?.route, routesToRegister[4]);

      lookupResult = router.lookup(HttpMethod.get, '/profiles/someProfileId');
      expect(
        lookupResult?.pathParameters,
        {'id': 'someProfileId'},
      );
      expect(lookupResult?.route, routesToRegister[5]);

      lookupResult = router.lookup(
        HttpMethod.get,
        '/profiles/random/anotherRandom',
      );
      expect(
        lookupResult?.pathParameters,
        {'id': 'random', '*': 'anotherRandom'},
      );
      expect(lookupResult?.route, routesToRegister[6]);

      lookupResult = router.lookup(
        HttpMethod.get,
        '/profiles/1234/anotherRandom',
      );
      expect(
        lookupResult?.pathParameters,
        {'id': '1234', '*': 'anotherRandom'},
      );
      expect(lookupResult?.route, routesToRegister[7]);
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

      LookupResult? lookupResult = router.lookup(
        HttpMethod.get,
        '/priority/id',
      );
      expect(lookupResult?.pathParameters, isEmpty);
      expect(lookupResult?.route, staticRoute);

      lookupResult = router.lookup(HttpMethod.get, '/priority/parametricId');
      expect(lookupResult?.pathParameters, {'id': 'parametricId'});
      expect(lookupResult?.route, nonRegExpParametricRoute);

      lookupResult = router.lookup(HttpMethod.get, '/priority/1234');
      expect(lookupResult?.pathParameters, {'id': '1234'});
      expect(lookupResult?.route, regExpParametricRoute);

      lookupResult = router.lookup(HttpMethod.get, '/priority/1234/random');
      expect(lookupResult?.pathParameters, {'*': '1234/random'});
      expect(lookupResult?.route, wildcardRoute);

      lookupResult = router.lookup(
        HttpMethod.get,
        '/priority/parametricId/random',
      );
      expect(lookupResult?.pathParameters, {'*': 'parametricId/random'});
      expect(lookupResult?.route, wildcardRoute);
    });

    test('Should not be able to lookup routes by path', () {
      expect(router.lookup(HttpMethod.get, 'random'), isNull);
      expect(router.lookup(HttpMethod.get, '/random'), isNull);
      expect(router.lookup(HttpMethod.get, '/random/random'), isNull);
      expect(router.lookup(HttpMethod.get, '/users/someUserId/logout'), isNull);
    });
  });
}
