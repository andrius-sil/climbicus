import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:async/async.dart';
import 'package:http/http.dart' as http;

class Api {
//  static const BASE_URL = "http://3.11.49.99:5000"; // PROD
  static const BASE_URL = "http://3.11.0.15:5000"; // DEV

  final client = http.Client();

  String _accessToken;
  int _user_id;

  set accessToken(String value) {
    _accessToken = value;
  }

  set userId(int value) {
    _user_id = value;
  }

  Future<Map> login(String email, String password) async {
    Map data = {
      "email": email,
      "password": password,
    };

    final response = await client.post(
      "$BASE_URL/login",
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    );

    if (response.statusCode != 200) {
      throw Exception("request failed with ${response.statusCode}");
    }

    final Map result = jsonDecode(response.body);
    return result;
  }

  Future<Map> fetchLogbook() async {
    //HttpHeaders.authorizationHeader
    final response = await client.get(
      "$BASE_URL/users/$_user_id/logbooks/view",
      headers: {"Authorization": "Bearer $_accessToken"},
    );

    if (response.statusCode != 200) {
      throw Exception("request failed with ${response.statusCode}");
    }

    final Map result = jsonDecode(response.body);
    return result;
  }

  Future<Map> uploadRouteImage(File image) async {
    var uri = Uri.parse("$BASE_URL/users/$_user_id/predict");
    var request = new http.MultipartRequest("POST", uri);

    request.headers["Authorization"] = "Bearer $_accessToken";

    var stream = new http.ByteStream(DelegatingStream.typed(image.openRead()));
    var length = await image.length();
    var multipartFile = new http.MultipartFile(
        'image',
        stream,
        length,
        filename: basename(image.path)
    );
    request.files.add(multipartFile);

    var response = await client.send(request);
    if (response.statusCode == 200) {
      final Map result = jsonDecode(await response.stream.bytesToString());
      return result;
    } else {
      var value = await response.stream.bytesToString();
      print(value);
      throw Exception("request failed with ${response.statusCode}");
    }
  }

  Future<Map> fetchRouteImages(List routeIds) async {
    Map data = {
      "route_ids": routeIds,
    };

    var uri = Uri.parse("$BASE_URL/users/$_user_id/route_images");
    var request = new http.Request("GET", uri);

    request.body = json.encode(data);
    request.headers["Authorization"] = "Bearer $_accessToken";
    request.headers["Content-Type"] = "application/json";

    var response = await client.send(request);

    if (response.statusCode != 200) {
      throw Exception("request failed with ${response.statusCode}");
    }

    final Map result = jsonDecode(await response.stream.bytesToString());
    return result;
  }

  Future<void> routeMatch(int routeId, int routeImageId, bool routeMatched) async {
    Map data = {
      "is_match": routeMatched ? 1 : 0,
      "route_id": routeId,
    };

    var uri = Uri.parse("$BASE_URL/users/$_user_id/route_match/$routeImageId");
    var request = new http.Request("PATCH", uri);

    request.body = json.encode(data);
    request.headers["Authorization"] = "Bearer $_accessToken";
    request.headers["Content-Type"] = "application/json";

    var response = await client.send(request);

    if (response.statusCode != 200) {
      throw Exception("request failed with ${response.statusCode}");
    }
  }
}
