import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

void main() {
  group('RegExpParametric Routes tests', () {
    final router = Router();
    final routesToRegister = [
      Route('/users/{id:^[0-9]+\$}', () {}),
      Route('/users/{id:^[a-z]+\$}/logout', () {}),
      Route('/users/{id:^[A-Z]+\$}/logout', () {}),
      Route('/users/{id:^[A-Z0-9a-z]+\$}/logout', () {}),
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
      expect(router.lookup('/users/1234'), routesToRegister[0]);
      expect(router.lookup('/users/someuserid/logout'), routesToRegister[1]);
      expect(router.lookup('/users/SOMEUSERID/logout'), routesToRegister[2]);
      expect(
        router.lookup('/users/someUserId1234/logout'),
        routesToRegister[3],
      );
    });

    test('Should not be able to lookup routes by path', () {
      expect(router.lookup('random'), isNull);
      expect(router.lookup('/random'), isNull);
      expect(router.lookup('/random/random'), isNull);
      expect(router.lookup('/users/someUserId1234'), isNull);
    });
  });
}
