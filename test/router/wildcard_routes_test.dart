import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

void main() {
  group('Wildcard Routes tests', () {
    final router = Router();
    final routesToRegister = [
      Route('/profiles/{id}/*', () {}),
      Route('/profiles/{id:^[0-9]+\$}/*', () {}),
    ];

    setUp(() {
      for (final route in routesToRegister) {
        router.register(route);
      }
    });

    test('Should able to lookup routes by path', () {
      expect(
        router.lookup('/profiles/random/anotherRandom'),
        routesToRegister[0],
      );
      expect(
        router.lookup('/profiles/1234/anotherRandom'),
        routesToRegister[1],
      );
    });

    test('Should not be able to lookup routes by path', () {
      expect(router.lookup('profiles'), isNull);
      expect(router.lookup('/profiles'), isNull);
      expect(router.lookup('/profiles/random'), isNull);
    });
  });
}
