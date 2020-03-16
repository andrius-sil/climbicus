import 'package:bloc/bloc.dart';
import 'package:climbicus/json/route_image.dart';
import 'package:climbicus/utils/api.dart';
import 'package:flutter/widgets.dart';

abstract class RouteImagesEvent {
  const RouteImagesEvent();
}

class FetchRouteImages extends RouteImagesEvent {
  final List<int> routeIds;
  final String trigger;

  const FetchRouteImages({@required this.routeIds, this.trigger});
}

abstract class RouteImagesState {
  const RouteImagesState();
}

class RouteImagesUninitialized extends RouteImagesState {}

class RouteImagesLoading extends RouteImagesState {}

class RouteImagesLoaded extends RouteImagesState {
  final Map<int, RouteImage> images;
  final String trigger;
  const RouteImagesLoaded({this.images, this.trigger});
}

class RouteImagesError extends RouteImagesState {
  FlutterErrorDetails errorDetails;

  RouteImagesError({Exception exception, StackTrace stackTrace}):
        errorDetails = FlutterErrorDetails(exception: exception, stack: stackTrace) {
    FlutterError.dumpErrorToConsole(errorDetails);
  }
}

class RouteImagesBloc extends Bloc<RouteImagesEvent, RouteImagesState> {
  final ApiProvider api = ApiProvider();

  Map<int, RouteImage> _images = {};
  Map<int, RouteImage> get images => _images;

  @override
  RouteImagesState get initialState => RouteImagesUninitialized();

  @override
  Stream<RouteImagesState> mapEventToState(RouteImagesEvent event) async* {
    if (event is FetchRouteImages) {
      yield RouteImagesLoading();

      var routeIds = event.routeIds;

      // Do not fetch already present route images.
      routeIds.removeWhere((id) => _images.containsKey(id));

      try {
        Map<String, dynamic> result =
            (await api.fetchRouteImages(routeIds))["route_images"];
        var fetchedImages = result.map(
            (id, model) => MapEntry(int.parse(id), RouteImage.fromJson(model)));
        _images.addAll(fetchedImages);

        yield RouteImagesLoaded(images: _images, trigger: event.trigger);
        return;
      } catch (e, st) {
        yield RouteImagesError(exception: e, stackTrace: st);
      }
    }
  }
}
