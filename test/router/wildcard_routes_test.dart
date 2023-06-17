import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

void main() {
  group('Wildcard Routes tests', () {
    final router = Router();
    final routesToRegister = [
      Route(
        HttpMethod.get,
        '/profiles/{id:^[0-9]+\$}/*',
        handler: (request) {
          return 'Get a profile but his/her id should contain only numbers';
        },
      ),
      Route(HttpMethod.get, '/profiles/{id}/*', handler: (request) {
        return 'Handle any get routes that goes after the profileId';
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
        router.lookup(HttpMethod.get, '/profiles/1234/anotherRandom'),
        routesToRegister[0],
      );
      expect(
        router.lookup(HttpMethod.get, '/profiles/random/anotherRandom'),
        routesToRegister[1],
      );
    });

    test('Should not be able to lookup routes by path', () {
      expect(router.lookup(HttpMethod.get, 'profiles'), isNull);
      expect(router.lookup(HttpMethod.get, '/profiles'), isNull);
      expect(router.lookup(HttpMethod.get, '/profiles/random'), isNull);
    });
  });
}
