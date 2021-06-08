import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/register_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/blocs/route_predictions_bloc.dart';
import 'package:climbicus/constants.dart';
import 'package:climbicus/repositories/api_repository.dart';
import 'package:climbicus/repositories/settings_repository.dart';
import 'package:climbicus/repositories/user_repository.dart';
import 'package:climbicus/screens/add_route.dart';
import 'package:climbicus/screens/gyms.dart';
import 'package:climbicus/screens/login.dart';
import 'package:climbicus/screens/register.dart';
import 'package:climbicus/screens/route_detailed.dart';
import 'package:climbicus/screens/route_match.dart';
import 'package:climbicus/screens/route_predictions.dart';
import 'package:climbicus/screens/route_view.dart';
import 'package:climbicus/screens/settings.dart';
import 'package:climbicus/screens/verify.dart';
import 'package:climbicus/style.dart';
import 'package:climbicus/widgets/camera_custom.dart';
import 'package:climbicus/widgets/route_painter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:device_preview/device_preview.dart';

import 'blocs/authentication_bloc.dart';
import 'blocs/gym_areas_bloc.dart';
import 'blocs/gyms_bloc.dart';
import 'blocs/login_bloc.dart';
import 'blocs/settings_bloc.dart';
import 'blocs/simple_bloc_delegate.dart';
import 'blocs/user_route_log_bloc.dart';
import 'blocs/users_bloc.dart';
import 'env.dart';
import 'models/gym.dart';


void main() {
  print("Using config:");
  EnvironmentConfig.display();

  var env = Environment.values.firstWhere(
          (e) => e.toString() == "Environment.${EnvironmentConfig.ENV}");

  mainDelegate(env);
}


Future<void> mainDelegate(Environment env) async {
  ErrorWidget.builder = _buildErrorWidget;
  debugPrint = _debugPrintWrapper;
  FlutterError.onError = _onError;

  WidgetsFlutterBinding.ensureInitialized();

  Bloc.observer = SimpleBlocObserver();

  final getIt = GetIt.instance;
  getIt.registerSingleton<ApiRepository>(ApiRepository(
    serverUrl: await getServerUrl(env),
  ));
  getIt.registerSingleton<UserRepository>(UserRepository());
  getIt.registerSingleton<SettingsRepository>(SettingsRepository(
      env: env,
  ));

  await _sentryInit(env);

  var app = MultiBlocProvider(
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
      BlocProvider<GymAreasBloc>(create: (context) => GymAreasBloc()),
      BlocProvider<UsersBloc>(create: (context) => UsersBloc()),
      BlocProvider<RouteImagesBloc>(create: (context) => RouteImagesBloc()),
      BlocProvider<RoutePredictionBloc>(create: (context) => RoutePredictionBloc()),
      BlocProvider<UserRouteLogBloc>(create: (context) => UserRouteLogBloc()),
      BlocProvider<GymRoutesBloc>(create: (context) => GymRoutesBloc(
        routeImagesBloc: BlocProvider.of<RouteImagesBloc>(context),
      )),
    ],
    child: ClimbicusApp(env: env),
  );

  var devicePreviewApp = DevicePreview(
    // TODO: use env var
    enabled: false,
    builder: (context) => app,
  );

  runZonedGuarded<Future<void>>(() async {
    runApp(devicePreviewApp);
  }, (Object error, StackTrace stackTrace) {
    var exception = error is FlutterErrorDetails ? error.exception : error;
    var trace = error is FlutterErrorDetails ? error.stack : stackTrace;

    print(exception);
    print(trace);
    Sentry.captureException(exception, stackTrace: trace);
  });
}

void _onError(FlutterErrorDetails details) {
  FlutterError.dumpErrorToConsole(details);

  if (details.context != null) {
    Sentry.addBreadcrumb(Breadcrumb(message: "Error context: ${details.context!.toDescription()}"));
  }
  Sentry.captureException(details.exception, stackTrace: details.stack);
}

SentryEvent? _sentryBeforeSend(SentryEvent event, {dynamic hint}) {
  return isInDebugMode ? null : event;
}

Future _sentryInit(Environment env) async {
  await SentryFlutter.init(
    (options) => options
        ..dsn = SENTRY_DSN
        ..environment = ENVIRONMENT_NAMES[env]
        ..beforeSend = _sentryBeforeSend
  );
}

void _debugPrintWrapper(String? message, {int? wrapWidth}) {
  var now = DateTime.now();
  message = "$now: $message";
  debugPrintThrottled(message, wrapWidth: wrapWidth);
}


Widget _buildErrorWidget(FlutterErrorDetails details) {
  return Center(
    child: Text("Ooops.. an error has occured"),
  );
}

bool get isInDebugMode {
  bool inDebugMode = false;

  // Assert expressions are only evaluated during development. They are ignored
  // in production. Therefore, this code only sets `inDebugMode` to true
  // in a development environment.
  assert(inDebugMode = true);

  return inDebugMode;
}


class ClimbicusApp extends StatelessWidget {
  final Environment env;

  const ClimbicusApp({required this.env});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: appTheme(),
      locale: DevicePreview.locale(context),
      navigatorObservers: [
        SentryNavigatorObserver(),
      ],
      builder: DevicePreview.appBuilder,
      home: HomePage(env: env),
      routes: {
        RegisterPage.routeName: (BuildContext context) => RegisterPage(),
        GymsPage.routeName: (BuildContext context) => GymsPage(),
        CameraCustom.routeName: (BuildContext context) => CameraCustom(),
        RoutePredictionsPage.routeName: (BuildContext context) => RoutePredictionsPage(
          ModalRoute.of(context)!.settings.arguments as RoutePredictionsArgs,
        ),
        AddRoutePage.routeName: (BuildContext context) => AddRoutePage(
          ModalRoute.of(context)!.settings.arguments as AddRouteArgs,
        ),
        RouteMatchPage.routeName: (BuildContext context) => RouteMatchPage(
          ModalRoute.of(context)!.settings.arguments as RouteMatchArgs,
        ),
        RouteDetailedPage.routeName : (BuildContext context) => RouteDetailedPage(
          ModalRoute.of(context)!.settings.arguments as RouteDetailedArgs,
        ),
      },
    );
  }
}


class HomePage extends StatefulWidget {
  final Environment env;

  HomePage({required this.env});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final getIt = GetIt.instance;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, state) {
        if (state is AuthenticationAuthenticated) {
          Sentry.configureScope((scope) => scope.user = SentryUser(
            id: "${getIt<UserRepository>().userId}",
            email: getIt<UserRepository>().email,
          ));

          // return RoutePainter(
          //   height: 400.0,
          //   imageNetworkPath: "http://dev-cdn.climbicus.com/white_boulder.jpg",
          // );

          return _buildHomePage();
        } else if (state is AuthenticationUnauthenticated) {
          Sentry.configureScope((scope) => scope.user = null);

          return LoginPage();
        } else if (state is AuthenticationUnverified) {
          Sentry.configureScope((scope) => scope.user = null);

          return VerifyPage();
        }

        return _buildWaitingPage();
      }
    );
  }

  Widget _buildHomePage() {
    return BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          if (settingsState is SettingsUninitialized) {
            return _buildWaitingPage();
          }

          // Ask user to select their gym if app is installed for the first time.
          if (settingsState.gymId == PLACEHOLDER_GYM_ID) {
            return GymsPage();
          }

          return BlocBuilder<GymsBloc, GymsState>(
            builder: (context, gymState) {
              if (gymState is GymsLoaded) {
                return _buildRouteTabView(gymState.gyms[settingsState.gymId]!);
              } else if (gymState is GymsError) {
                return ErrorWidget.builder(gymState.errorDetails);
              }

              return _buildWaitingPage();
            }
          );

        }
    );
  }

  Widget _buildRouteTabView(Gym gym) {
    List<Tab> tabs = [];
    List<RouteViewPage> tabViews = [];
    if (gym.hasSport) {
      tabViews.add(RouteViewPage(routeCategory: SPORT_CATEGORY, gym: gym));
      tabs.add(Tab(text: "Sport"));
    }
    if (gym.hasBouldering) {
      tabViews.add(RouteViewPage(routeCategory: BOULDERING_CATEGORY, gym: gym));
      tabs.add(Tab(text: "Bouldering"));
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            tabs: tabs,
          ),
          title: _buildTitle(gym),
        ),
        body: TabBarView(
          children: tabViews,
        ),
        drawer: Drawer(
          child: SettingsPage(env: widget.env),
        ),
      ),
    );
  }

  Widget _buildTitle(Gym gym) {
    return BlocBuilder<GymsBloc, GymsState>(
      builder: (context, state) {
        if (state is GymsLoaded) {
          return Text(gym.name);
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
