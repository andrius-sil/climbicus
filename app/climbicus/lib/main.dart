import 'package:climbicus/models/route_images.dart';
import 'package:climbicus/models/user_route_log.dart';
import 'package:climbicus/ui/logbook.dart';
import 'package:climbicus/ui/login.dart';
import 'package:climbicus/ui/settings.dart';
import 'package:climbicus/utils/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


void main() {
  ErrorWidget.builder = _buildErrorWidget;
  debugPrint = _debugPrintWrapper;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserRouteLogModel()),
        ChangeNotifierProvider(create: (context) => RouteImagesModel()),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: HomePage(),
      ),
    ),
  );
}

void _debugPrintWrapper(String message, { int wrapWidth }) {
  var now = DateTime.now();
  message = "$now: $message";
  debugPrintThrottled(message, wrapWidth: wrapWidth);
}

Widget _buildErrorWidget(FlutterErrorDetails details) {
  return Center(
    child: Text("Ooops.. an error has occured"),
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

