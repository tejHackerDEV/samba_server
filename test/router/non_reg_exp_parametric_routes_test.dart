import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

void main() {
  group('NonRegExpParametric Routes tests', () {
    final router = Router();
    final routesToRegister = [
      Route('/users/{id}', () {}),
      Route('/users/{id}/logout', () {}),
      Route('/profiles/{id}', () {}),
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
      expect(router.lookup('/users/someUserId'), routesToRegister[0]);
      expect(router.lookup('/users/someUserId/logout'), routesToRegister[1]);
      expect(router.lookup('/profiles/someProfileId'), routesToRegister[2]);
    });

    test('Should not be able to lookup routes by path', () {
      expect(router.lookup('random'), isNull);
      expect(router.lookup('/random'), isNull);
      expect(router.lookup('/random/random'), isNull);
    });
  });
}
