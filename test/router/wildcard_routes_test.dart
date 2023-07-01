import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

import '../helpers/route_builder.dart';

void main() {
  group('Wildcard Routes tests', () {
    final router = Router();
    final routesToRegister = [
      RouteBuilder(
        HttpMethod.get,
        '/profiles/{id:^[0-9]+\$}/*',
        routeHandler: (_) {
          return Response.ok(
            body: 'Get a profile but his/her id should contain only numbers',
          );
        },
      ),
      RouteBuilder(HttpMethod.get, '/profiles/{id}/*', routeHandler: (_) {
        return Response.ok(
          body: 'Handle any get routes that goes after the profileId',
        );
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
      LookupResult? lookupResult = router.lookup(
        HttpMethod.get,
        '/profiles/1234/anotherRandom',
      );
      expect(lookupResult?.pathParameters, {
        'id': '1234',
        '*': 'anotherRandom',
      });
      expect(lookupResult?.route, routesToRegister[0]);

      lookupResult = router.lookup(
        HttpMethod.get,
        '/profiles/random/anotherRandom',
      );
      expect(lookupResult?.pathParameters, {
        'id': 'random',
        '*': 'anotherRandom',
      });
      expect(lookupResult?.route, routesToRegister[1]);
    });

    test('Should not be able to lookup routes by path', () {
      expect(router.lookup(HttpMethod.get, 'profiles'), isNull);
      expect(router.lookup(HttpMethod.get, '/profiles'), isNull);
      expect(router.lookup(HttpMethod.get, '/profiles/random'), isNull);
    });
  });
}
