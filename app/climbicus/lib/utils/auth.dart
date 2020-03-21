import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';

class Auth {
  // Singleton factory.
  Auth._internal();

  static final Auth _auth = Auth._internal();

  factory Auth() => _auth;

  final ApiProvider api = ApiProvider();

  String _email;

  String get email => _email;

  Future<void> login(String email, String password) async {
    var userAuth = await api.login(email, password);
    var accessToken = userAuth["access_token"];
    var userId = userAuth["user_id"];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("email", email);
    prefs.setString("access_token", accessToken);
    prefs.setInt("user_id", userId);

    this._email = email;
    api.accessToken = accessToken;
    api.userId = userId;
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("email");
    prefs.remove("access_token");
    prefs.remove("user_id");

    this._email = null;
    api.accessToken = null;
    api.userId = null;
  }

  Future<bool> loggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    this._email = prefs.getString("email");
    api.accessToken = prefs.getString("access_token");
    api.userId = prefs.getInt("user_id");

    return this._email != null;
  }
}
