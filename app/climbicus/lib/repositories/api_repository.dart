import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:climbicus/repositories/user_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

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
  UnauthorizedApiException(http.StreamedResponse response, String responseJson)
      : super(response, responseJson);
}

class ConflictingResourceApiException extends ApiException {
  ConflictingResourceApiException(http.StreamedResponse response, String responseJson)
      : super(response, responseJson);
}

class SignatureVerificationApiException extends ApiException {
  SignatureVerificationApiException(http.StreamedResponse response, String responseJson)
      : super(response, responseJson);
}

class ApiRepository {
  final getIt = GetIt.instance;

  final String serverUrl;
  final client = http.Client();

  int _gymId;
  set gymId(int value) => _gymId = value;

  ApiRepository({this.serverUrl});

  ApiException _apiException(response, responseJson) {
    switch (response.statusCode) {
      case 401:
        return UnauthorizedApiException(response, responseJson);
      case 409:
        return ConflictingResourceApiException(response, responseJson);
      case 422:
        return SignatureVerificationApiException(response, responseJson);
      default:
        return ApiException(response, responseJson);
    }
  }

  Future<Map> _request(http.BaseRequest request, bool auth) async {
    if (auth) {
      var accessToken = getIt<UserRepository>().accessToken;
      request.headers["Authorization"] = "Bearer $accessToken";
    }

    final response = await client.send(request);

    if (response.statusCode != 200) {
      final exception =
          _apiException(response, await response.stream.bytesToString());
      debugPrint(exception.toString());
      throw exception;
    }

    return jsonDecode(await response.stream.bytesToString());
  }

  Future<Map> _requestJson(String method, String urlPath, Map requestData,
      {bool auth = true}) async {
    var uri = Uri.parse("$serverUrl/$urlPath");
    var request = http.Request(method, uri);

    request.headers["Content-Type"] = "application/json";

    Map data = {};
    if (auth) {
      data["user_id"] = getIt<UserRepository>().userId;
    }
    data.addAll(requestData);
    request.body = json.encode(data);

    debugPrint(
        "http json request: '${request.url}' - '${request.method}' - '${request.body}'");

    return _request(request, auth);
  }

  Future<Map> _requestMultipart(
      File image, String method, String urlPath, Map requestData) async {
    var uri = Uri.parse("$serverUrl/$urlPath");
    var request = http.MultipartRequest("POST", uri);

    var stream = http.ByteStream(DelegatingStream.typed(image.openRead()));
    var length = await image.length();
    var multipartFile = http.MultipartFile('image', stream, length,
        filename: basename(image.path));
    request.files.add(multipartFile);

    Map data = {"user_id": getIt<UserRepository>().userId};
    data.addAll(requestData);
    request.fields["json"] = json.encode(data);

    debugPrint(
        "http multipart request: '${request.url}' - '${request.method}' - '${request.fields}'");

    return _request(request, true);
  }

  Future<Map> login(String email, String password) async {
    Map data = {
      "email": email,
      "password": password,
    };

    return _requestJson("POST", "login", data, auth: false);
  }

  Future<Map> register(String name, String email, String password) async {
    Map data = {
      "name": name,
      "email": email,
      "password": password,
    };

    return _requestJson("POST", "register", data, auth: false);
  }

  Future<Map> routeMatch(int routeImageId, int routeId) async {
    Map data = {
      "is_match": (routeId != null) ? 1 : 0,
      "route_id": routeId,
    };

    return _requestJson("PATCH", "route_images/$routeImageId", data);
  }

  Future<Map> logbookAdd(int routeId, bool completed, int numAttempts) async {
    Map data = {
      "route_id": routeId,
      "completed": completed,
      "num_attempts": numAttempts,
      "gym_id": _gymId,
    };

    return _requestJson("POST", "user_route_log/", data);
  }

  Future<Map> fetchRouteImages(List<int> routeIds) async {
    Map data = {
      "route_ids": routeIds,
    };

    return _requestJson("GET", "route_images/", data);
  }

  Future<Map> fetchRouteImagesAllRoute(int routeId) async {
    return _requestJson("GET", "route_images/route/$routeId", {});
  }

  Future<Map> fetchLogbook() async {
    Map data = {
      "gym_id": _gymId,
    };

    return _requestJson("GET", "user_route_log/", data);
  }

  Future<Map> fetchLogbookOneRoute(int routeId) async {
    Map data = {
      "gym_id": _gymId,
    };

    return _requestJson("GET", "user_route_log/$routeId", data);
  }

  Future<Map> deleteUserRouteLog(int userRouteLogId) async {
    Map data = {
      "gym_id": _gymId,
    };

    return _requestJson("DELETE", "user_route_log/$userRouteLogId", data);
  }

  Future<Map> routePredictions(File image, String category) async {
    Map data = {
      "gym_id": _gymId,
      "category": category,
    };
    return _requestMultipart(image, "POST", "routes/predictions_cbir", data);
  }

  Future<Map> fetchRoutes() async {
    Map data = {
      "gym_id": _gymId,
    };
    return _requestJson("GET", "routes/", data);
  }

  Future<Map> fetchOneRoute(int routeId) async {
    Map data = {
      "gym_id": _gymId,
    };
    return _requestJson("GET", "routes/$routeId", data);
  }

  Future<Map> routeAdd(String category, String grade, String name) async {
    Map data = {
      "gym_id": _gymId,
      "category": category,
      "name": name,
      "lower_grade": grade,
      "upper_grade": grade,
    };

    return _requestJson("POST", "routes/", data);
  }

  Future<Map> fetchGyms() async {
    return _requestJson("GET", "gyms/", {});
  }

  Future<Map> fetchUsers() async {
    return _requestJson("GET", "users/", {});
  }

  Future<Map> fetchVotes() async {
    Map data = {
      "gym_id": _gymId,
    };
    return _requestJson("GET", "user_route_votes/", data);
  }

  Future<Map> fetchOneUserRouteVotes(int routeId) async {
    Map data = {
      "gym_id": _gymId,
    };
    return _requestJson("GET", "user_route_votes/$routeId", data);
  }

  Future<Map> userRouteVotesAdd(int routeId, double quality, String difficulty) async {
    Map data = {
      "gym_id": _gymId,
      "route_id": routeId,
      "quality": quality,
      "difficulty": difficulty,
    };

    return _requestJson("POST", "user_route_votes/", data);
  }

  Future<Map> userRouteVotesUpdate(int userRouteVotesId, double quality, String difficulty) async {
    Map data = {
      "quality": quality,
      "difficulty": difficulty,
    };

    return _requestJson("PATCH", "user_route_votes/$userRouteVotesId", data);
  }
}
