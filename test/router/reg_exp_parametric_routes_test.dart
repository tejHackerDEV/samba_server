import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

void main() {
  group('RegExpParametric Routes tests', () {
    final router = Router();
    final routesToRegister = [
      Route(HttpMethod.get, '/users/{id:^[0-9]+\$}', handler: (
        request,
        response,
      ) {
        return response
          ..body = 'Get user data but his/her id should contain only numbers';
      }),
      Route(HttpMethod.get, '/users/{id:^[a-z]+\$}/logout', handler: (
        request,
        response,
      ) {
        return response
          ..body =
              'Logout a user but his/her id should contain only small letters';
      }),
      Route(HttpMethod.get, '/users/{id:^[A-Z]+\$}/logout', handler: (
        request,
        response,
      ) {
        return response
          ..body =
              'Logout a user but his/her id should contain only capital letters';
      }),
      Route(
        HttpMethod.get,
        '/users/{id:^[A-Z0-9a-z]+\$}/logout',
        handler: (request, response) {
          return response
            ..body =
                'Logout a user but his/her id may contains small, capital letters & numbers';
        },
      ),
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
      expect(router.lookup(HttpMethod.get, '/users/1234'), routesToRegister[0]);
      expect(
        router.lookup(HttpMethod.get, '/users/someuserid/logout'),
        routesToRegister[1],
      );
      expect(
        router.lookup(HttpMethod.get, '/users/SOMEUSERID/logout'),
        routesToRegister[2],
      );
      expect(
        router.lookup(HttpMethod.get, '/users/someUserId1234/logout'),
        routesToRegister[3],
      );
    });

    test('Should not be able to lookup routes by path', () {
      expect(router.lookup(HttpMethod.get, 'random'), isNull);
      expect(router.lookup(HttpMethod.get, '/random'), isNull);
      expect(router.lookup(HttpMethod.get, '/random/random'), isNull);
      expect(router.lookup(HttpMethod.get, '/users/someUserId1234'), isNull);
    });
  });
}
