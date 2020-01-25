import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Auth {
  static const BASE_URL = "http://3.11.49.99:5000";

  String _email;
  String _accessToken;

  String get email => _email;
  String get accessToken => _accessToken;

  Future<void> login(String email, String password) async {
    Map data = {
      "email": email,
      "password": password,
    };

    final response = await http.post(
        "$BASE_URL/login",
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
    );

    if (response.statusCode != 200) {
      throw Exception("request failed with ${response.statusCode}");
    }

    final Map result = jsonDecode(response.body);
    this._accessToken = result["access_token"];
    this._email = email;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("email", email);
    prefs.setString("access_token", result["access_token"]);
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("email");
    prefs.remove("access_token");

    this._accessToken = null;
    this._email = null;
  }

  Future<bool> loggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("email") != null;
  }
}
