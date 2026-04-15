import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class BarkService {
  static const String _titlePrefix = '[Nai] ';

  Future<void> sendAuthFailNotification({
    required String token,
    required String title,
    required String body,
    String proxy = '',
  }) async {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) return;
    final url = Uri.parse('https://api.day.app/push');
    final payload = {
      'device_key': trimmedToken,
      'title': title.startsWith(_titlePrefix) ? title : '$_titlePrefix$title',
      'body': body,
    };
    final headers = const {
      'Content-Type': 'application/json; charset=utf-8',
    };
    final client = _createHttpClient(proxy);
    try {
      if (client == null) {
        await http.post(url, headers: headers, body: json.encode(payload));
      } else {
        await client.post(url, headers: headers, body: json.encode(payload));
      }
    } finally {
      client?.close();
    }
  }

  http.Client? _createHttpClient(String proxy) {
    if (kIsWeb || proxy.isEmpty) return null;
    final ioClient = HttpClient();
    ioClient.findProxy = (uri) => 'PROXY $proxy';
    ioClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }
}
