import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

void main() {
  group('Router tests', () {
    final router = Router();
    final routesToRegister = [
      Route('/users', () {}),
      Route('/users/userId', () {}),
      Route('/users/{id}', () {}),
      Route('/users/{id}/logout', () {}),
      Route('/profiles', () {}),
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
      expect(router.lookup(routesToRegister[0].path), routesToRegister[0]);
      expect(router.lookup(routesToRegister[1].path), routesToRegister[1]);
      expect(router.lookup('/users/someUserId'), routesToRegister[2]);
      expect(router.lookup('/users/someUserId/logout'), routesToRegister[3]);
      expect(router.lookup(routesToRegister[4].path), routesToRegister[4]);
      expect(router.lookup('/profiles/someProfileId'), routesToRegister[5]);
    });

    test('Should not be able to lookup routes by path', () {
      expect(router.lookup('random'), isNull);
      expect(router.lookup('/random'), isNull);
      expect(router.lookup('/random/random'), isNull);
    });
  });
}
