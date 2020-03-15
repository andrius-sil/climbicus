import 'package:bloc/bloc.dart';


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
  final Exception exception;
  const RouteError({this.exception});
}


abstract class RouteBloc<Event, Entry> extends Bloc<Event, RouteState> {
  void fetch();

  List<String> displayAttrs(entry);

  int routeId(entryId, entry);
}

