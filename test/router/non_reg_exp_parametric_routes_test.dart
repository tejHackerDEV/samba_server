import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

void main() {
  group('NonRegExpParametric Routes tests', () {
    final router = Router();
    final routesToRegister = [
      Route(HttpMethod.get, '/users/{id}', handler: (request, response) {
        return response..body = 'Get user data';
      }),
      Route(HttpMethod.get, '/users/{id}/logout', handler: (request, response) {
        return response..body = 'Logout user';
      }),
      Route(HttpMethod.get, '/profiles/{id}', handler: (request, response) {
        return response..body = 'Get profile data';
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
