
import 'dart:async';

import 'package:climbicus/repositories/api_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

class UserRepository {
  final getIt = GetIt.instance;
  final secureStorage = FlutterSecureStorage();

  String? _accessToken;
  String? _email;
  int? _userId;
  bool? _userIsAdmin;

  String get accessToken => _accessToken!;
  String get email => _email!;
  int get userId => _userId!;
  bool get userIsAdmin => _userIsAdmin!;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await getIt<ApiRepository>().register(name, email, password);
  }

  Future<Map> authenticate({
    required String email,
    required String password,
  }) async {
    var userAuth = await getIt<ApiRepository>().login(email, password);
    return userAuth;
  }

  Future<void> persistAuth({
    required String email,
    required Map userAuth,
  }) async {
    _accessToken = userAuth["access_token"];
    _userId = userAuth["user_id"];
    _userIsAdmin = userAuth["user_is_admin"];
    _email = email;

    await secureStorage.write(key: "access_token", value: _accessToken);
    await secureStorage.write(key: "user_id", value: _userId.toString());
    await secureStorage.write(key: "user_is_admin", value: _userIsAdmin.toString());
    await secureStorage.write(key: "email", value: _email);
  }

  Future<void> deauthenticate() async {
    _accessToken = null;
    _userId = null;
    _userIsAdmin = null;
    _email = null;

    await secureStorage.delete(key: "access_token");
    await secureStorage.delete(key: "user_id");
    await secureStorage.delete(key: "user_is_admin");
    await secureStorage.delete(key: "email");
  }

  Future<bool> hasAuthenticated() async {
    _accessToken = await secureStorage.read(key: "access_token");

    if (_accessToken == null) {
      return false;
    }

    var userIdStr = await secureStorage.read(key: "user_id");
    _userId = int.parse(userIdStr!);
    _userIsAdmin = (await secureStorage.read(key: "user_is_admin")) == "true";
    _email = await secureStorage.read(key: "email");

    return true;
  }
}