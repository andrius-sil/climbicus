import 'package:bloc/bloc.dart';
import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/register_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/blocs/route_predictions_bloc.dart';
import 'package:climbicus/repositories/api_repository.dart';
import 'package:climbicus/repositories/user_repository.dart';
import 'package:climbicus/ui/login.dart';
import 'package:climbicus/ui/route_view.dart';
import 'package:climbicus/ui/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'blocs/authentication_bloc.dart';
import 'blocs/gyms_bloc.dart';
import 'blocs/login_bloc.dart';
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

  final getIt = GetIt.instance;
  getIt.registerSingleton<ApiRepository>(ApiRepository(
    serverUrl: SERVER_URLS[env],
  ));
  getIt.registerSingleton<UserRepository>(UserRepository());

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthenticationBloc>(create: (context) => AuthenticationBloc()),
        BlocProvider<LoginBloc>(create: (context) => LoginBloc(
          authenticationBloc: BlocProvider.of<AuthenticationBloc>(context),
        )),
        BlocProvider<RegisterBloc>(create: (context) => RegisterBloc(
          authenticationBloc: BlocProvider.of<AuthenticationBloc>(context),
        )),
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

  HomePage({@required this.env});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, state) {
        if (state is AuthenticationAuthenticated) {
          return _buildHomePage();
        } else if (state is AuthenticationUnauthenticated) {
          return LoginPage();
        }

        return _buildWaitingPage();
      }
    );
  }

  Widget _buildHomePage() {
    return BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsUninitialized) {
            return _buildWaitingPage();
          }

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
                  RouteViewPage(routeCategory: "sport", gymId: state.gymId),
                  RouteViewPage(routeCategory: "bouldering", gymId: state.gymId),
                ],
              ),
              drawer: Drawer(
                child: SettingsPage(env: widget.env),
              ),
            ),
          );
        }
    );
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
