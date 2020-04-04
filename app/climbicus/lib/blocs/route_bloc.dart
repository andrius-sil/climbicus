import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';


abstract class RouteState {
  const RouteState();
}

class RouteUninitialized extends RouteState {}

class RouteLoading extends RouteState {}

class RouteLoaded extends RouteState {
  final Map entries;
  const RouteLoaded({this.entries});
}

class RouteLoadedWithImages extends RouteLoaded {
  const RouteLoadedWithImages({entries}) : super(entries: entries);
}

class RouteError extends RouteState {
  FlutterErrorDetails errorDetails;

  RouteError({Object exception, StackTrace stackTrace}):
        errorDetails = FlutterErrorDetails(exception: exception, stack: stackTrace) {
    FlutterError.dumpErrorToConsole(errorDetails);
  }
}


abstract class RouteBloc<Event, Entry> extends Bloc<Event, RouteState> {
  void fetch();

  String headerTitle(entry);

  String bodyTitle(entry);

  String bodySubtitle(entry);

  int routeId(entryId, entry);
}

