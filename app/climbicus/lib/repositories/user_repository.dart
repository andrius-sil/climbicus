
import 'package:climbicus/repositories/api_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRepository {
  final getIt = GetIt.instance;

  String _accessToken;
  String _email;
  int _userId;

  String get accessToken => _accessToken;
  String get email => _email;
  int get userId => _userId;

  Future<Map> authenticate({
    @required String email,
    @required String password,
  }) async {
    var userAuth = await getIt<ApiRepository>().login(email, password);
    return userAuth;
  }

  Future<void> persistAuth({
    @required String email,
    @required Map userAuth,
  }) async {
    _accessToken = userAuth["access_token"];
    _userId = userAuth["user_id"];
    _email = email;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("access_token", _accessToken);
    prefs.setInt("user_id", _userId);
    prefs.setString("email", _email);
  }

  Future<void> deauthenticate() async {
    _accessToken = null;
    _userId = null;
    _email = null;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("access_token");
    prefs.remove("user_id");
    prefs.remove("email");
  }

  Future<bool> hasAuthenticated() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    _accessToken = prefs.getString("access_token");
    _userId = prefs.getInt("user_id");
    _email = prefs.getString("email");

    return _accessToken != null;
  }
}