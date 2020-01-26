import 'package:climbicus/ui/image_picker.dart';
import 'package:climbicus/ui/login.dart';
import 'package:climbicus/ui/settings.dart';
import 'package:climbicus/utils/api.dart';
import 'package:climbicus/utils/auth.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: HomePage(),
    ),
  );
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

enum AuthStatus {
  notDetermined,
  notLoggedIn,
  loggedIn,
}

class _HomePageState extends State<HomePage> {
  final Api api = new Api();

  Auth auth;
  AuthStatus authStatus = AuthStatus.notDetermined;

  _HomePageState() {
    auth = new Auth(api: api);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    auth.loggedIn().then((bool userLoggedIn) {
      setState(() {
        authStatus = userLoggedIn ? AuthStatus.loggedIn : AuthStatus.notLoggedIn;
      });
    });
  }

  void _loggedIn() {
    setState(() {
      authStatus = AuthStatus.loggedIn;
    });
  }

  void _loggedOut() {
    setState(() {
      authStatus = AuthStatus.notLoggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    var screen = null;
    switch (authStatus) {
      case AuthStatus.notDetermined:
        screen = _buildWaitingPage();
        break;
      case AuthStatus.notLoggedIn:
        screen = LoginPage(auth: auth, loginCallback: _loggedIn);
        break;
      case AuthStatus.loggedIn:
        screen = ImagePickerPage(api: api);
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Climbicus v0.000001'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings menu',
            onPressed: () {
              openSettingsPage(context);
            },
          ),
        ],
      ),
      body: Center(
        child: screen,
      ),
    );
  }

  Widget _buildWaitingPage() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ),
    );
  }

  void openSettingsPage(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (BuildContext context) {
        return SettingsPage(auth: auth, logoutCallback: _loggedOut);
      },
    ));
  }
}

