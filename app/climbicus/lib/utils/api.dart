import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:async/async.dart';
import 'package:http/http.dart' as http;

class Api {
//  static const BASE_URL = "http://3.11.49.99:5000"; // PROD
  static const BASE_URL = "http://3.11.0.15:5000"; // DEV

  static const CASTLE_GYM_ID = 1;

  final client = http.Client();

  String _accessToken;
  int _userId;

  set accessToken(String value) {
    _accessToken = value;
  }

  set userId(int value) {
    _userId = value;
  }

  Future<Map> _request(http.BaseRequest request, bool auth) async {
    if (auth) {
      request.headers["Authorization"] = "Bearer $_accessToken";
    }

    var response = await client.send(request);

    if (response.statusCode != 200) {
      throw Exception("request failed with ${response.statusCode}");
    }

    final Map result = jsonDecode(await response.stream.bytesToString());
    return result;
  }

  Future<Map> _requestJson(String method, String urlPath, Map requestData, {bool auth = true}) async {
    var uri = Uri.parse("$BASE_URL/$urlPath");
    var request = new http.Request(method, uri);

    request.headers["Content-Type"] = "application/json";

    Map data = {};
    if (auth) {
      data["user_id"] = _userId;
    }
    data.addAll(requestData);
    request.body = json.encode(data);

    return _request(request, auth);
  }

  Future<Map> _requestMultipart(File image, String method, String urlPath, Map requestData) async {
    var uri = Uri.parse("$BASE_URL/$urlPath");
    var request = new http.MultipartRequest("POST", uri);

    var stream = new http.ByteStream(DelegatingStream.typed(image.openRead()));
    var length = await image.length();
    var multipartFile = new http.MultipartFile(
        'image',
        stream,
        length,
        filename: basename(image.path)
    );
    request.files.add(multipartFile);

    Map data = {"user_id": _userId};
    data.addAll(requestData);
    request.fields["json"] = json.encode(data);

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

  Future<void> logbookAdd(int routeId, String status) async {
    Map data = {
      "route_id": routeId,
      "status": status,
      "gym_id": CASTLE_GYM_ID,
    };

    _requestJson("POST", "user_route_log/", data);
  }

  Future<Map> fetchRouteImages(List routeIds) async {
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
