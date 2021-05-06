
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

class SimpleBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    debugPrint("Event: $event");
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    debugPrint("$transition");
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stacktrace) {
    super.onError(bloc, error, stacktrace);
    var errorDetails = FlutterErrorDetails(exception: error, stack: stacktrace);
    throw errorDetails;
  }
}
