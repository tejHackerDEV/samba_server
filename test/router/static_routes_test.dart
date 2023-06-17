import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

void main() {
  group('Static Routes tests', () {
    final router = Router();
    final routesToRegister = [
      Route(HttpMethod.get, '/users', handler: (request) {
        return 'Get users data';
      }),
      Route(HttpMethod.get, '/users/id', handler: (request) {
        return 'Get user data who\'s id is id';
      }),
      Route(HttpMethod.get, '/profiles', handler: (request) {
        return 'Get profiles data';
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
