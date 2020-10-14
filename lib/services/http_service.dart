import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ecoupon_lib/common/errors.dart';
import 'package:ecoupon_lib/services/session_service.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;

class HTTPService {

  final String baseURL;
  final SessionService session;

  final http.Client _httpClient;

  HTTPService(this.baseURL, {this.session, http.Client client}): _httpClient = client ?? http.Client();

  Future<dynamic> getFrom(String path) async {
    return await _doGet(path);
  }

  Future<dynamic> _doGet(String path, {int iteration = 0, int maxRetries = 1}) async {
    try {
      final url = _url(path: path);
      final headers = _requestHeaders();
      // if (kDebugMode) {
      //   print("Sending request to: $url");
      //   print("Headers: $headers");
      // }
      final response = await _httpClient.get(url, headers: headers);
      // if (kDebugMode) {
      //   print("Response status: ${response.statusCode}");
      //   print("Response headers: ${response.headers}");
      //   print("Response body: ${response.body.toString()}");
      // }
      return _processResponse(response); 
    } on HTTPError catch (e) {
      if (session != null && e.statusCode == 401) {
        if (iteration >= maxRetries) {
          throw NotAuthenticatedError();
        }
        await session.refreshToken();
        return await _doGet(path, iteration: iteration + 1, maxRetries: maxRetries);
      } if (e.statusCode == 401) {
        throw NotAuthenticatedError();
      } else {
        throw e;
      }
    }
  }

  Future<dynamic> postTo(String path, dynamic body) async {
    return await _doPost(path, body);
  }

  Future<dynamic> _doPost(String path, dynamic body, {int iteration = 0, int maxRetries = 1}) async {
    try {
      final url = _url(path: path);
      final headers = _requestHeaders();
      headers[HttpHeaders.contentTypeHeader] = "application/json";
      // if (kDebugMode) {
      //   print("Sending request to: $url");
      //   print("Headers: $headers");
      //   print("Body: ${body.toString()}");
      // }
      final response = await _httpClient.post(url, headers: headers, body: jsonEncode(body));
      // if (kDebugMode) {
      //   print("Response status: ${response.statusCode}");
      //   print("Response body: ${response.body.toString()}");
      // }
      return _processResponse(response); 
    } on HTTPError catch (e) {
      if (session != null && e.statusCode == 401) {
        if (iteration >= maxRetries) {
          throw NotAuthenticatedError();
        }
        await session.refreshToken();
        return await _doPost(path, body, iteration: iteration + 1, maxRetries: maxRetries);
      } if (e.statusCode == 401) {
        throw NotAuthenticatedError();
      } else {
        throw e;
      }
    }
  }

  Future<dynamic> deleteAt(String path) async {
    return await _doDelete(path);
  }

  Future<dynamic> _doDelete(String path, {int iteration = 0, int maxRetries = 1}) async {
    try {
      final url = _url(path: path);
      final headers = _requestHeaders();
      // if (kDebugMode) {
      //   print("Sending request to: $url");
      //   print("Headers: $headers");
      // }
      final response = await _httpClient.delete(url, headers: headers);
      // if (kDebugMode) {
      //   print("Response status: ${response.statusCode}");
      //   print("Response body: ${response.body.toString()}");
      // }
      return _processResponse(response); 
    } on HTTPError catch (e) {
      if (session != null && e.statusCode == 401) {
        if (iteration >= maxRetries) {
          throw NotAuthenticatedError();
        }
        await session.refreshToken();
        return await _doDelete(path, iteration: iteration + 1, maxRetries: maxRetries);
      } if (e.statusCode == 401) {
        throw NotAuthenticatedError();
      } else {
        throw e;
      }
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic json;
    final contentType = response.headers[HttpHeaders.contentTypeHeader];
    if (contentType != null && contentType.startsWith("application/json")) {
      json = jsonDecode(response.body);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      Map<String, List<String>> details;
      try {
        if (json is Map<String, dynamic>) {
          details = json.map((key, value) {
            if (value is List<dynamic>) {
              return MapEntry(key, List<String>.from(value));
            } else {
              return MapEntry(key, <String>[value]);
            }
          });
        }
      } catch (e) {}
      throw HTTPError(response.statusCode, details);
    }
    return json;
  }

  Map<String, String> _requestHeaders() {
    Map<String, String> result = Map<String, String>();
    result[HttpHeaders.acceptHeader] = "application/json";
    if (session != null && session.token != null) {
      result[HttpHeaders.authorizationHeader] = "bearer ${session.token.access}";
    }
    return result;
  }

  String _url({@required String path}) {
    if (path.startsWith(baseURL)) {
      return path;
    }
    return "$baseURL$path";
  }
}