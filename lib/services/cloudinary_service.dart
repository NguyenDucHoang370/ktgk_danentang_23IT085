import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  // Tên Cloudinary lấy từ Dashboard
  static const String _cloudName = 'h7qj2761';

  // Tên Upload Preset đã tạo
  static const String _uploadPreset = 'ktgk_uploadImg';

  Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      throw StateError(
        'Thiếu CLOUDINARY_CLOUD_NAME hoặc CLOUDINARY_UPLOAD_PRESET. '
        'Xem hướng dẫn cấu hình trong docs/BAO_CAO.md.',
      );
    }

    final request =
        http.MultipartRequest(
            'POST',
            Uri.https('api.cloudinary.com', '/v1_1/$_cloudName/image/upload'),
          )
          ..fields['upload_preset'] = _uploadPreset
          ..fields['folder'] = 'giang_vien'
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: filename,
              contentType: _parseContentType(contentType),
            ),
          );

    final response = await http.Response.fromStream(await request.send());
    final dynamic payload = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? message;
      if (payload is Map<String, dynamic>) {
        final error = payload['error'];
        if (error is Map<String, dynamic> && error['message'] is String) {
          message = error['message'] as String;
        }
      }
      throw StateError(
        'Cloudinary từ chối tải ảnh (${response.statusCode}): '
        '${message ?? response.body}',
      );
    }

    if (payload is! Map<String, dynamic> ||
        payload['secure_url'] is! String ||
        (payload['secure_url'] as String).isEmpty) {
      throw const FormatException('Cloudinary không trả về secure_url hợp lệ.');
    }
    return payload['secure_url'] as String;
  }

  MediaType _parseContentType(String value) {
    final parts = value.split('/');
    return parts.length == 2
        ? MediaType(parts[0], parts[1])
        : MediaType('image', 'jpeg');
  }
}
