import 'package:bloc/bloc.dart';
import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/blocs/route_predictions_bloc.dart';
import 'package:climbicus/ui/login.dart';
import 'package:climbicus/ui/route_view.dart';
import 'package:climbicus/ui/settings.dart';
import 'package:climbicus/utils/api.dart';
import 'package:climbicus/utils/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/gyms_bloc.dart';
import 'blocs/settings_bloc.dart';
import 'blocs/simple_bloc_delegate.dart';
import 'env.dart';


const Map<Environment, String> SERVER_URLS = {
  Environment.dev: "http://x1carbon:5000",
  Environment.stag: "http://3.11.0.15:5000",
  Environment.prod: "http://3.11.49.99:5000",
};


void mainDelegate(Environment env) {
  ErrorWidget.builder = _buildErrorWidget;
  debugPrint = _debugPrintWrapper;

  BlocSupervisor.delegate = SimpleBlocDelegate();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(create: (context) => SettingsBloc()),
        BlocProvider<GymsBloc>(create: (context) => GymsBloc()),
        BlocProvider<RouteImagesBloc>(create: (context) => RouteImagesBloc()),
        BlocProvider<RoutePredictionBloc>(create: (context) => RoutePredictionBloc()),
        BlocProvider<GymRoutesBloc>(create: (context) => GymRoutesBloc(
          routeImagesBloc: BlocProvider.of<RouteImagesBloc>(context),
        )),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: HomePage(env: env),
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
  final Environment env;
  HomePage({this.env});

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
  final ApiProvider api = ApiProvider();

  AuthStatus authStatus = AuthStatus.notDetermined;

  @override
  void initState() {
    super.initState();

    api.serverUrl = SERVER_URLS[widget.env];
  }

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
        return LoginPage(loginCallback: _loggedIn);
      case AuthStatus.loggedIn:
        return BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            if (state is SettingsUninitialized) {
              return _buildWaitingPage();
            }

            api.gymId = state.gymId;

            return DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  bottom: TabBar(
                    tabs: [
                      Tab(text: "Sport"),
                      Tab(text: "Bouldering"),
                    ],
                  ),
                  title: _buildTitle(state.gymId),
                ),
                body: TabBarView(
                  children: <Widget>[
                    RouteViewPage(routeCategory: "sport"),
                    RouteViewPage(routeCategory: "bouldering"),
                  ],
                ),
                drawer: Drawer(
                  child: SettingsPage(env: widget.env, logoutCallback: _loggedOut),
                ),
              ),
            );
          }
        );
    }
  }

  Widget _buildTitle(int gymId) {
    return BlocBuilder<GymsBloc, GymsState>(
      builder: (context, state) {
        if (state is GymsLoaded) {
          return Text(state.gyms[gymId].name);
        }

        return Text("");
      }
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
}
