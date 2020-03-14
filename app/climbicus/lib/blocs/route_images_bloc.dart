import 'package:bloc/bloc.dart';
import 'package:climbicus/json/route_image.dart';
import 'package:climbicus/utils/api.dart';
import 'package:flutter/widgets.dart';

abstract class RouteImagesEvent {
  const RouteImagesEvent();
}

class FetchRouteImages extends RouteImagesEvent {
  final List<int> routeIds;

  const FetchRouteImages({@required this.routeIds});
}

abstract class RouteImagesState {
  const RouteImagesState();
}

class RouteImagesUninitialized extends RouteImagesState {}

class RouteImagesLoading extends RouteImagesState {}

class RouteImagesLoaded extends RouteImagesState {
  final Map<int, RouteImage> images;
  const RouteImagesLoaded({this.images});
}

class RouteImagesError extends RouteImagesState {
  final Exception exception;
  const RouteImagesError({this.exception});
}

class RouteImagesBloc extends Bloc<RouteImagesEvent, RouteImagesState> {
  final ApiProvider api = ApiProvider();

  Map<int, RouteImage> _images = {};

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

        yield RouteImagesLoaded(images: _images);
        return;
      } catch (e) {
        yield RouteImagesError(exception: e);
      }
    }
  }
}
