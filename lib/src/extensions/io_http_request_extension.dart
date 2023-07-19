import 'dart:io' as io;

import 'package:samba_server/src/extensions/iterable_extension.dart';

import '../helpers/enums/index.dart';

extension IOHttpRequestExtension on io.HttpRequest {
  HttpMethod? extractHttpMethod() {
    return HttpMethod.values.firstWhereOrNull(
      (httpMethod) => httpMethod.name.toLowerCase() == method.toLowerCase(),
    );
  }
}
