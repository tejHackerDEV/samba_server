import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

void main() {
  group('Router tests', () {
    final router = Router();
    final routesToRegister = [
      Route('/users', () {}),
      Route('/users/userId', () {}),
      Route('/profiles', () {}),
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
      expect(router.lookup(routesToRegister[2].path), routesToRegister[2]);
    });

    test('Should not be able to lookup routes by path', () {
      expect(router.lookup('random'), isNull);
      expect(router.lookup('/random'), isNull);
      expect(router.lookup('/random/random'), isNull);
    });
  });
}
