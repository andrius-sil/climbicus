import 'package:bloc/bloc.dart';
import 'package:climbicus/blocs/gym_route_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/blocs/route_predictions_bloc.dart';
import 'package:climbicus/blocs/user_route_log_bloc.dart';
import 'package:climbicus/ui/login.dart';
import 'package:climbicus/ui/route_view.dart';
import 'package:climbicus/ui/settings.dart';
import 'package:climbicus/utils/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/simple_bloc_delegate.dart';

void main() {
  ErrorWidget.builder = _buildErrorWidget;
  debugPrint = _debugPrintWrapper;

  BlocSupervisor.delegate = SimpleBlocDelegate();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<RouteImagesBloc>(create: (context) => RouteImagesBloc()),
        BlocProvider<RoutePredictionBloc>(create: (context) => RoutePredictionBloc(
          routeImagesBloc: BlocProvider.of<RouteImagesBloc>(context),
        )),
        BlocProvider<UserRouteLogBloc>(create: (context) => UserRouteLogBloc(
          routeImagesBloc: BlocProvider.of<RouteImagesBloc>(context),
        )),
        BlocProvider<GymRouteBloc>(create: (context) => GymRouteBloc(
          routeImagesBloc: BlocProvider.of<RouteImagesBloc>(context),
          userRouteLogBloc: BlocProvider.of<UserRouteLogBloc>(context),
        )),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: HomePage(),
      ),
    ),
  );
}

void _debugPrintWrapper(String message, {int wrapWidth}) {
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
        authStatus =
            userLoggedIn ? AuthStatus.loggedIn : AuthStatus.notLoggedIn;
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
        return LoginPage(appBarActions: appBarActions(), loginCallback: _loggedIn);
      case AuthStatus.loggedIn:
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              bottom: TabBar(
                tabs: [
                  Tab(text: "Logbook"),
                  Tab(text: "Gym"),
                ],
              ),
              title: Text("Routes"),
              actions: appBarActions(),
            ),
            body: TabBarView(
              children: <Widget>[
                RouteViewPage<UserRouteLogBloc>(),
                RouteViewPage<GymRouteBloc>(),
              ],
            ),
          ),
        );
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

  List<Widget> appBarActions() {
    return [
      IconButton(
        icon: const Icon(Icons.settings),
        tooltip: 'Settings menu',
        onPressed: () {
          openSettingsPage(context);
        },
      ),
    ];
  }

  void openSettingsPage(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (BuildContext context) {
        return SettingsPage(logoutCallback: _loggedOut);
      },
    ));
  }
}
