import 'package:dio/dio.dart';

export 'package:dio/src/form_data.dart';
export 'package:dio/src/multipart_file.dart';

class HttpResponse<T> {
  final int statusCode;
  final Map<String, dynamic> headers;
  final T? body;

  HttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });
}

class HttpClient {
  final Dio _dio;

  HttpClient._(this._dio);

  factory HttpClient({
    String address = '127.0.0.1',
    int port = 8080,
  }) {
    return HttpClient._(Dio(
      BaseOptions(
        baseUrl: 'http://$address:$port',
        validateStatus: (_) {
          // validate all status as success,
          // if we failed to do so then dio will throw error for
          // all on 2xx status codes
          return true;
        },
      ),
    ));
  }

  Future<HttpResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Object? data,
  }) async {
    final response = await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: Options(headers: headers),
      data: data,
    );
    return HttpResponse(
      statusCode: response.statusCode!,
      headers: response.headers.map,
      body: response.data,
    );
  }

  Future<HttpResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Object? data,
  }) async {
    final response = await _dio.post<T>(
      path,
      queryParameters: queryParameters,
      options: Options(headers: headers),
      data: data,
    );
    return HttpResponse(
      statusCode: response.statusCode!,
      headers: response.headers.map,
      body: response.data,
    );
  }

  Future<HttpResponse<T>> put<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Object? data,
  }) async {
    final response = await _dio.put<T>(
      path,
      queryParameters: queryParameters,
      options: Options(headers: headers),
      data: data,
    );
    return HttpResponse(
      statusCode: response.statusCode!,
      headers: response.headers.map,
      body: response.data,
    );
  }

  Future<HttpResponse<T>> patch<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Object? data,
  }) async {
    final response = await _dio.patch<T>(
      path,
      queryParameters: queryParameters,
      options: Options(headers: headers),
      data: data,
    );
    return HttpResponse(
      statusCode: response.statusCode!,
      headers: response.headers.map,
      body: response.data,
    );
  }

  Future<HttpResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Object? data,
  }) async {
    final response = await _dio.delete<T>(
      path,
      queryParameters: queryParameters,
      options: Options(headers: headers),
      data: data,
    );
    return HttpResponse(
      statusCode: response.statusCode!,
      headers: response.headers.map,
      body: response.data,
    );
  }

  Future<HttpResponse<T>> options<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Object? data,
  }) async {
    final response = await _dio.request<T>(
      path,
      queryParameters: queryParameters,
      options: Options(method: 'OPTIONS', headers: headers),
      data: data,
    );
    return HttpResponse(
      statusCode: response.statusCode!,
      headers: response.headers.map,
      body: response.data,
    );
  }
}
