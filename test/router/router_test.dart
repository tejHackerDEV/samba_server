import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

void main() {
  group('Router tests', () {
    final router = Router();
    final routesToRegister = [
      Route('/users', () {}),
      Route('/users/userId', () {}),
      Route('/users/{id}', () {}),
      Route('/users/{id:^[0-9]+\$}/logout', () {}),
      Route('/profiles', () {}),
      Route('/profiles/{id}', () {}),
    ];

    setUp(() {
      for (final route in routesToRegister) {
        router.register(route);
      }
    });

    test('Should able to lookup routes by path', () {
      expect(router.lookup(routesToRegister[0].path), routesToRegister[0]);
      expect(router.lookup(routesToRegister[1].path), routesToRegister[1]);
      expect(router.lookup('/users/someUserId'), routesToRegister[2]);
      expect(router.lookup('/users/1234/logout'), routesToRegister[3]);
      expect(router.lookup(routesToRegister[4].path), routesToRegister[4]);
      expect(router.lookup('/profiles/someProfileId'), routesToRegister[5]);
    });

    test('Should able to lookup routes based on their priority order', () {
      final nonRegExpParametricRoute = Route('/priority/{id}', () {});
      final regExpParametricRoute = Route('/priority/{id:^[0-9]+\$}', () {});
      final staticRoute = Route('/priority/id', () {});
      router
        ..register(nonRegExpParametricRoute)
        ..register(regExpParametricRoute)
        ..register(staticRoute);
      expect(router.lookup('/priority/id'), staticRoute);
      expect(router.lookup('/priority/parametricId'), nonRegExpParametricRoute);
      expect(router.lookup('/priority/1234'), regExpParametricRoute);
    });

    test('Should not be able to lookup routes by path', () {
      expect(router.lookup('random'), isNull);
      expect(router.lookup('/random'), isNull);
      expect(router.lookup('/random/random'), isNull);
      expect(router.lookup('/users/someUserId/logout'), isNull);
    });
  });
}
