import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/io_client.dart';
import 'package:nai_casrand/data/models/api_request.dart';
import 'package:http/http.dart' as http;

class ApiService {
  Future<ApiResponse> fetchData(ApiRequest request) async {
    final url = Uri.parse(request.endpoint);
    final client = createHttpClient(request.proxy);
    try {
      Future<http.Response> responseFuture;
      if (client == null) {
        responseFuture = http.post(
          url,
          headers: request.headers,
          body: json.encode(request.payload),
        );
      } else {
        responseFuture = client.post(
          url,
          headers: request.headers,
          body: json.encode(request.payload),
        );
      }
      if (request.timeout != null) {
        responseFuture = responseFuture.timeout(request.timeout!);
      }
      final response = await responseFuture;
      return ApiResponse(
        status: response.statusCode.toString(),
        data: response.bodyBytes,
      );
    } finally {
      client?.close();
    }
  }

  http.Client? createHttpClient(String proxy) {
    if (kIsWeb || proxy == '') return null;
    final ioClient = HttpClient();
    ioClient.findProxy = (uri) => 'PROXY $proxy';
    ioClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }
}
