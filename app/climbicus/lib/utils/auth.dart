import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';

class Auth {
  static const BASE_URL = "http://3.11.49.99:5000";

  final Api api;

  String _email;

  Auth({this.api});

  String get email => _email;

  Future<void> login(String email, String password) async {
    var accessToken = await api.login(email, password);
    this._email = email;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("email", email);
    prefs.setString("access_token", accessToken);

    api.accessToken = accessToken;
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("email");
    prefs.remove("access_token");

    this._email = null;
    api.accessToken = null;
  }

  Future<bool> loggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    this._email = prefs.getString("email");
    api.accessToken = prefs.getString("access_token");

    return this._email != null;
  }
}
