
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SimpleBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    debugPrint("Event: $event");

    Sentry.addBreadcrumb(Breadcrumb(message: "Event: $event", category: "bloc.event"));
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    debugPrint("$transition");

    Sentry.addBreadcrumb(Breadcrumb(message: "$transition", category: "bloc.transition"));
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stacktrace) {
    super.onError(bloc, error, stacktrace);
    var errorDetails = FlutterErrorDetails(exception: error, stack: stacktrace);
    throw errorDetails;
  }
}
