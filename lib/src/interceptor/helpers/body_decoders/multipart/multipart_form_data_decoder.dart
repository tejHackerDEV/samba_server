import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:samba_server/src/extensions/map_extension.dart';

import '../../../../utils/content_types.dart';
import '../../../../utils/headers.dart';
import '../request_decoder.dart';
import '../string_request_decoder.dart';
import 'multipart_file.dart';
import 'multipart_form_data.dart';
import 'multipart_text.dart';

class MultipartFormDataRequestDecoder
    extends RequestDecoder<Map<String, dynamic>> {
  /// An interceptor to decode body of a request which contains `content-type`
  /// as [ContentType.kMultipartFormData] in request headers.
  ///
  /// In order to decode the body correctly, one should pass correct
  /// [encoding] strategy used in encoding the request body.
  const MultipartFormDataRequestDecoder({
    Encoding fallbackEncoding = utf8,
  }) : super(
          contentType: ContentTypes.kMultipartFormData,
          fallbackEncoding: fallbackEncoding,
        );

  @override
  FutureOr<Map<String, dynamic>> decode(
    io.ContentType contentType,
    Encoding encoding,
    Stream<Uint8List> stream,
  ) async {
    final boundary = contentType.parameters['boundary'];
    if (boundary == null) {
      return {};
    }
    final mimeMultipartList =
        await MimeMultipartTransformer(boundary).bind(stream).toList();
    final multipartFormDataList = await Future.wait(
      mimeMultipartList.map(
        (mimeMultipart) async => await _parse(
          mimeMultipart,
          contentType: contentType,
          encoding: encoding,
        ),
      ),
    );
    final Map<String, dynamic> body = {};
    for (final multipartFormData in multipartFormDataList) {
      body.addOrUpdateValue(
        key: multipartFormData.key,
        value: multipartFormData,
      );
    }
    return body;
  }

  Future<MultipartFormData> _parse(
    MimeMultipart mimeMultipart, {
    required io.ContentType contentType,
    required Encoding encoding,
  }) async {
    String? key;
    String? filename;
    String? fileContentType;
    for (final entry in mimeMultipart.headers.entries) {
      switch (entry.key) {
        case 'content-disposition':
          // entry.value contains as follows:-
          // {content-disposition: form-data; key="value"; key="value"}
          //
          // skip 1st element because the 1st element is always
          // "form-data" with no "=" which we are not interested in
          final parameters = entry.value.split(';').skip(1);
          for (final param in parameters) {
            final index = param.indexOf('=');
            final dummyKey = param.substring(0, index).trim();
            final value = param.substring(index + 2, param.length - 1).trim();
            switch (dummyKey) {
              case 'name':
                // value will be the actual form-data key that we are looking
                key = value;
                break;
              case 'filename':
                // value will be the actual name of the file
                filename = value;
                break;
            }
          }
          break;
        case Headers.kContentType:
          // value will be the actual content-type of the file
          fileContentType = entry.value;
          break;
      }
    }
    if (key == null) {
      // key can't be null
      // TODO: Throw custom error
      throw Error();
    }
    if (filename != null) {
      if (fileContentType == null) {
        // contentType can't be null
        // TODO: Throw custom error
        throw Error();
      }
      // this is an file, so parse it as file
      return MultipartFile(
        key,
        Uint8List.fromList(
          await mimeMultipart.fold<List<int>>(
            [],
            (previous, element) => previous..addAll(element),
          ),
        ),
        filename,
        fileContentType,
      );
    }
    // as there is no fileName, this will be a text. So parse it as text
    return MultipartText(
      key,
      await StringRequestDecoder(fallbackEncoding: fallbackEncoding).decode(
        contentType,
        encoding,
        mimeMultipart.map((event) => Uint8List.fromList(event)),
      ),
    );
  }
}
