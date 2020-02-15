import 'package:climbicus/ui/logbook.dart';
import 'package:climbicus/ui/login.dart';
import 'package:climbicus/ui/settings.dart';
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
  final Auth auth = Auth();
  AuthStatus authStatus = AuthStatus.notDetermined;

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
    switch (authStatus) {
      case AuthStatus.notDetermined:
        return _buildWaitingPage();
      case AuthStatus.notLoggedIn:
        return LoginPage(appBar: appBar("Login"), loginCallback: _loggedIn);
      case AuthStatus.loggedIn:
        return LogbookPage(appBar: appBar("Logbook"));
    }
  }

  Widget _buildWaitingPage() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ),
    );
  }

  AppBar appBar(String title) {
    return AppBar(
      title: Text(title),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings menu',
          onPressed: () {
            openSettingsPage(context);
          },
        ),
      ],
    );
  }

  void openSettingsPage(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (BuildContext context) {
        return SettingsPage(logoutCallback: _loggedOut);
      },
    ));
  }
}

