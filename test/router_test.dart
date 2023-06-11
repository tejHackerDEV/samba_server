import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

void main() {
  group('Route tests', () {
    final router = Router();

    test('Should able to register routes', () {
      final routesToRegister = [
        Route('/users', () {}),
        Route('/users/userId', () {}),
        Route('/profiles', () {}),
      ];
      for (final route in routesToRegister) {
        router.register(route);
      }
      expect(router.routes, routesToRegister);
    });
  });
}
