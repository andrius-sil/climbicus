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

class AddNewRouteImage extends RouteImagesEvent {
  final int routeId;
  final RouteImage routeImage;
  const AddNewRouteImage({this.routeId, this.routeImage});
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
        Map<String, dynamic> routeImages =
            (await api.fetchRouteImages(routeIds))["route_images"];
        var fetchedImages = routeImages.map((routeId, model) =>
            MapEntry(int.parse(routeId), RouteImage.fromJson(model)));
        _images.addAll(fetchedImages);

        yield RouteImagesLoaded(images: _images);
        return;
      } catch (e, st) {
        yield RouteImagesError(exception: e, stackTrace: st);
      }
    } else if (event is AddNewRouteImage) {
      // Not uploading image to the database via API because all images are
      // uploaded as part of predictions at the moment.
      api.routeMatch(event.routeId, event.routeImage.routeImageId);

      _images[event.routeId] = event.routeImage;

      yield RouteImagesLoaded(images: _images);
    }
  }
}
