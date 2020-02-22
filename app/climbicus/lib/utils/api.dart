import 'dart:convert';
import 'dart:io';

import 'package:climbicus/utils/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:async/async.dart';
import 'package:http/http.dart' as http;


class ApiException implements Exception {
  final http.StreamedResponse response;
  final String responseJson;

  String message;

  ApiException(this.response, this.responseJson) {
    message = jsonDecode(responseJson)["msg"];
  }

  String toString() => "ApiException: ${response.statusCode} - ${message}";
}


class UnauthorizedApiException extends ApiException {
  UnauthorizedApiException(http.StreamedResponse response, String responseJson) :
        super(response, responseJson);
}


class ApiProvider {
  static const CASTLE_GYM_ID = 1;

  // Singleton factory.
  ApiProvider._internal();
  static final ApiProvider _apiProvider = ApiProvider._internal();
  factory ApiProvider() => _apiProvider;

  final Settings settings = Settings();

  final client = http.Client();

  String _accessToken;
  int _userId;

  set accessToken(String value) => _accessToken = value;
  set userId(int value) => _userId = value;

  ApiException _apiException(response, responseJson) {
    switch (response.statusCode) {
      case 401:
        return UnauthorizedApiException(response, responseJson);
      default:
        return ApiException(response, responseJson);
    }
  }

  Future<Map> _request(http.BaseRequest request, bool auth) async {
    if (auth) {
      request.headers["Authorization"] = "Bearer $_accessToken";
    }

    final response = await client.send(request);

    if (response.statusCode != 200) {
      final exception = _apiException(response, await response.stream.bytesToString());
      debugPrint(exception.toString());
      throw exception;
    }

    final Map result = jsonDecode(await response.stream.bytesToString());
    return result;
  }

  Future<Map> _requestJson(String method, String urlPath, Map requestData, {bool auth = true}) async {
    var uri = Uri.parse("${settings.serverUrl}/$urlPath");
    var request = http.Request(method, uri);

    request.headers["Content-Type"] = "application/json";

    Map data = {};
    if (auth) {
      data["user_id"] = _userId;
    }
    data.addAll(requestData);
    request.body = json.encode(data);

    debugPrint("http json request: '${request.url}' - '${request.method}' - '${request.body}'");

    return _request(request, auth);
  }

  Future<Map> _requestMultipart(File image, String method, String urlPath, Map requestData) async {
    var uri = Uri.parse("${settings.serverUrl}/$urlPath");
    var request = http.MultipartRequest("POST", uri);

    var stream = http.ByteStream(DelegatingStream.typed(image.openRead()));
    var length = await image.length();
    var multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: basename(image.path)
    );
    request.files.add(multipartFile);

    Map data = {"user_id": _userId};
    data.addAll(requestData);
    request.fields["json"] = json.encode(data);

    debugPrint("http multipart request: '${request.url}' - '${request.method}' - '${request.fields}'");

    return _request(request, true);
  }

  Future<Map> login(String email, String password) async {
    Map data = {
      "email": email,
      "password": password,
    };

    return _requestJson("POST", "login", data, auth: false);
  }

  Future<void> routeMatch(int routeId, int routeImageId, bool routeMatched) async {
    Map data = {
      "is_match": routeMatched ? 1 : 0,
      "route_id": routeId,
    };

    _requestJson("PATCH", "route_images/$routeImageId", data);
  }

  Future<Map> logbookAdd(int routeId, String status) async {
    Map data = {
      "route_id": routeId,
      "status": status,
      "gym_id": CASTLE_GYM_ID,
    };

    return _requestJson("POST", "user_route_log/", data);
  }

  Future<Map> fetchRouteImages(List<int> routeIds) async {
    Map data = {
      "route_ids": routeIds,
    };

    return _requestJson("GET", "route_images/", data);
  }


  Future<Map> fetchLogbook() async {
    Map data = {
      "gym_id": CASTLE_GYM_ID,
    };

    return _requestJson("GET", "user_route_log/", data);
  }

  Future<Map> uploadRouteImage(File image) async {
    Map data = {
      "gym_id": CASTLE_GYM_ID,
    };
    return _requestMultipart(image, "POST", "routes/predictions", data);

  }
}
