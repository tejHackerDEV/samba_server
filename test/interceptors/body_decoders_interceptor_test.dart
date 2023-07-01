import 'dart:io' as io;

import 'package:samba_server/samba_server.dart';
import 'package:test/test.dart';

import '../helpers/http_client.dart' as http_client;
import '../helpers/route_builder.dart';

void main() {
  const address = '127.0.0.1';
  const port = 8080;

  final httpClient = http_client.HttpClient(address: address, port: port);

  final applicationJson = 'application/json';
  final formUrlencoded = 'application/x-www-form-urlencoded';
  final multipartFormData = 'multipart/form-data';
  final plainText = 'text/plain';

  final httpServer = HttpServer();

  setUp(() async => await httpServer.bind(address: address, port: port));

  tearDown(() async => await httpServer.shutdown());

  group('StringRequestDecoder tests', () {
    test('Should able to decode body of `text/*` requests', () async {
      String body = 'Hi I am request body';
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [StringRequestDecoder()],
          routeHandler: (request) {
            expect(request.body, body);
            return Response.created();
          },
        ),
      );
      await httpClient.post(
        httpServer.uri.path,
        headers: {'content-type': plainText},
        data: body,
      );

      body = 'class App {}';
      await httpClient.post(
        httpServer.uri.path,
        headers: {'content-type': 'text/dart'},
        data: body,
      );
    });

    test('Should not able to decode body of non `text/*` requests', () async {
      String body = 'Hi I am request body';
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [StringRequestDecoder()],
          routeHandler: (request) {
            expect(request.body, isNot(body));
            return Response.created();
          },
        ),
      );
      await httpClient.post(
        httpServer.uri.path,
        headers: {'content-type': applicationJson},
        data: body,
      );
    });
  });

  group('FormUrlencodedRequestDecoder tests', () {
    final body = {
      'country': 'India',
      'states': 'AndhraPradesh',
      'noOfStates': '29',
    };

    test('Should able to decode body of `$formUrlencoded` requests', () async {
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [FormUrlencodedRequestDecoder()],
          routeHandler: (request) {
            expect(request.body, body);
            return Response.created();
          },
        ),
      );
      await httpClient.post(
        httpServer.uri.path,
        headers: {'content-type': formUrlencoded},
        data: body,
      );
    });

    test('Should not able to decode body of non `$formUrlencoded` requests',
        () async {
      final body = 'Hi I am request body';
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [FormUrlencodedRequestDecoder()],
          routeHandler: (request) {
            expect(request.body, isNot(body));
            return Response.created();
          },
        ),
      );
      await httpClient.post(
        httpServer.uri.path,
        headers: {'content-type': plainText},
        data: body,
      );
    });
  });

  group('JsonRequestDecoder tests', () {
    final body = {
      'country': 'India',
      'state': 'AndhraPradesh',
      'noOfStates': 29,
      'cities': ['Kadapa', 'Anantapur'],
    };

    test('Should able to decode body of `$applicationJson` requests', () async {
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [JsonRequestDecoder()],
          routeHandler: (request) {
            expect(request.body, body);
            return Response.created();
          },
        ),
      );
      await httpClient.post(
        httpServer.uri.path,
        headers: {'content-type': applicationJson},
        data: body,
      );
    });

    test('Should not able to decode body of non `$applicationJson` requests',
        () async {
      final body = 'Hi I am request body';
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [JsonRequestDecoder()],
          routeHandler: (request) {
            expect(request.body, isNot(body));
            return Response.created();
          },
        ),
      );
      await httpClient.post(
        httpServer.uri.path,
        headers: {'content-type': formUrlencoded},
        data: body,
      );
    });
  });

  group('MultipartFormDataRequestDecoder tests', () {
    final body = {
      'country': 'India',
      'state': 'AndhraPradesh',
      'noOfStates': '29',
      'cities': ['Kadapa', 'Anantapur'],
    };
    final files = [
      io.File('test/images/vintage_pawan_kalyan.jpg'),
      io.File('test/images/pawan_kalyan.jpg'),
    ];

    test('Should able to decode body of `$multipartFormData` requests',
        () async {
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [MultipartFormDataRequestDecoder()],
          routeHandler: (request) {
            expect(request.body, isMap);
            final bodyMap = request.body as Map;
            expect(bodyMap['country']!.value, body['country']);
            expect(bodyMap['state']!.value, body['state']);
            expect(bodyMap['noOfStates']!.value, body['noOfStates']);
            expect(
              bodyMap['cities']!.map((element) => element.value),
              body['cities'],
            );
            return Response.created();
          },
        ),
      );
      await httpClient.post(
        httpServer.uri.path,
        headers: {'content-type': multipartFormData},
        data: http_client.FormData.fromMap(body),
      );
    });

    test(
        'Should able to decode body with file of `$multipartFormData` requests',
        () async {
      final file = files.first;
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [MultipartFormDataRequestDecoder()],
          routeHandler: (request) {
            expect(request.body, isMap);
            final bodyMap = request.body as Map;
            expect(bodyMap['file'], isA<MultipartFile>());
            final multipartFile = bodyMap['file'] as MultipartFile;
            expect(
              multipartFile.name,
              file.path.split('/').last,
            );
            expect(multipartFile.contentType, 'image/jpg');
            expect(multipartFile.value, file.readAsBytesSync());
            return Response.created();
          },
        ),
      );
      await httpClient.post(
        httpServer.uri.path,
        headers: {'content-type': multipartFormData},
        data: http_client.FormData.fromMap({
          'file': http_client.MultipartFile.fromFileSync(
            file.path,
            headers: {
              'content-type': ['image/jpg'],
            },
          ),
        }),
      );
    });

    test(
        'Should able to decode body with file of `$multipartFormData` requests',
        () async {
      final file = files.first;
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [MultipartFormDataRequestDecoder()],
          routeHandler: (request) {
            expect(request.body, isMap);
            final bodyMap = request.body as Map;
            expect(bodyMap['file'], isA<MultipartFile>());
            final multipartFile = bodyMap['file'] as MultipartFile;
            expect(
              multipartFile.name,
              file.path.split('/').last,
            );
            expect(multipartFile.contentType, 'image/jpg');
            expect(multipartFile.value, file.readAsBytesSync());
            return Response.created();
          },
        ),
      );
      await httpClient.post(
        httpServer.uri.path,
        headers: {'content-type': multipartFormData},
        data: http_client.FormData.fromMap({
          'file': http_client.MultipartFile.fromFileSync(
            file.path,
            headers: {
              'content-type': ['image/jpg'],
            },
          ),
        }),
      );
    });

    test(
        'Should able to decode body with text & files of `$multipartFormData` requests',
        () async {
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [MultipartFormDataRequestDecoder()],
          routeHandler: (request) {
            expect(request.body, isMap);
            final bodyMap = request.body as Map;
            expect(bodyMap['country']!.value, body['country']);
            expect(bodyMap['state']!.value, body['state']);
            expect(bodyMap['noOfStates']!.value, body['noOfStates']);
            expect(
              bodyMap['cities']!.map((element) => element.value),
              body['cities'],
            );
            expect(bodyMap['files'], isA<List>());
            final multipartFiles = bodyMap['files'].cast<MultipartFile>();
            expect(
              multipartFiles.first.name,
              files.first.path.split('/').last,
            );
            expect(multipartFiles.first.contentType, 'image/jpg');
            expect(multipartFiles.first.value, files.first.readAsBytesSync());
            expect(
              multipartFiles.last.name,
              files.last.path.split('/').last,
            );
            expect(multipartFiles.last.contentType, 'application/octet-stream');
            expect(multipartFiles.last.value, files.last.readAsBytesSync());
            return Response.created();
          },
        ),
      );
      await httpClient.post(
        httpServer.uri.path,
        headers: {'content-type': multipartFormData},
        data: http_client.FormData.fromMap({
          ...body,
          'files': List.generate(files.length, (index) {
            final file = files.elementAt(index);
            return http_client.MultipartFile.fromFileSync(
              file.path,
              headers: {
                if (index == 0) 'content-type': ['image/jpg'],
              },
            );
          }),
        }),
      );
    });

    test('Should not able to decode body of non `$multipartFormData` requests',
        () async {
      final body = 'Hi I am request body';
      httpServer.registerRoute(
        RouteBuilder(
          HttpMethod.post,
          httpServer.uri.path,
          interceptorsBuilder: (_) => [MultipartFormDataRequestDecoder()],
          routeHandler: (request) {
            expect(request.body, isNot(isMap));
            return Response.created();
          },
        ),
      );
      await httpClient.post(
        httpServer.uri.path,
        headers: {'content-type': applicationJson},
        data: body,
      );
    });
  });
}
