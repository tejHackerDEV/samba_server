import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

void main() {
  group('Static Routes tests', () {
    final router = Router();
    final routesToRegister = [
      Route('/users', (request) {}),
      Route('/users/userId', (request) {}),
      Route('/profiles', (request) {}),
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
        expect(router.lookup(route.path), route);
      }
    });

    test('Should not be able to lookup routes by path', () {
      expect(router.lookup('random'), isNull);
      expect(router.lookup('/random'), isNull);
      expect(router.lookup('/random/random'), isNull);
    });
  });
}
