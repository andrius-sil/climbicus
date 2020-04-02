import 'package:bloc/bloc.dart';
import 'package:climbicus/json/route_image.dart';
import 'package:climbicus/utils/api.dart';
import 'package:flutter/widgets.dart';


class ImagesData {
  ImagesData(this.defaultRouteImageId, this.routeImages);

  int defaultRouteImageId;
  Map<int, RouteImage> routeImages;

  RouteImage get defaultRouteImage => routeImages[defaultRouteImageId];
}

class Images {
  Map<int, ImagesData> _data = {};

  RouteImage defaultImage(int routeId) {
    if (!_data.containsKey(routeId)) {
      return null;
    }

    return _data[routeId].defaultRouteImage;
  }

  Map<int, RouteImage> allImages(int routeId) {
    if (!_data.containsKey(routeId)) {
      return null;
    }

    return _data[routeId].routeImages;
  }

  bool contains(int routeId) => _data.containsKey(routeId);

  void addRoutes(Map<int, RouteImage> routes) {
    _data.addAll(routes.map((routeId, routeImage) =>
        MapEntry(routeId, ImagesData(routeImage.id, {routeImage.id: routeImage})))
    );
  }

  void addRouteImages(int routeId, List<RouteImage> images) {
    if (!_data.containsKey(routeId)) {
      return;
    }

    _data[routeId].routeImages = Map.fromIterable(images,
      key: (img) => img.id,
      value: (img) => img,
    );
  }
}

abstract class RouteImagesEvent {
  const RouteImagesEvent();
}

class FetchRouteImages extends RouteImagesEvent {
  final List<int> routeIds;
  final String trigger;
  const FetchRouteImages({@required this.routeIds, this.trigger});
}

class FetchRouteImagesAll extends RouteImagesEvent {
  final int routeId;
  const FetchRouteImagesAll({@required this.routeId});
}

class AddNewRouteImage extends RouteImagesEvent {
  final int routeId;
  final RouteImage routeImage;
  final String trigger;
  const AddNewRouteImage({this.routeId, this.routeImage, this.trigger});
}

class UpdateRouteImage extends RouteImagesEvent {
  final int routeId;
  final int routeImageId;
  const UpdateRouteImage({this.routeId, this.routeImageId});
}

abstract class RouteImagesState {
  const RouteImagesState();
}

class RouteImagesUninitialized extends RouteImagesState {}

class RouteImagesLoading extends RouteImagesState {}

class RouteImagesLoaded extends RouteImagesState {
  final Images images;
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

  final Images images = Images();

  @override
  RouteImagesState get initialState => RouteImagesUninitialized();

  @override
  Stream<RouteImagesState> mapEventToState(RouteImagesEvent event) async* {
    if (event is FetchRouteImages) {
      yield RouteImagesLoading();

      var routeIds = event.routeIds;

      // Do not fetch already present route images.
      routeIds.removeWhere((id) => images.contains(id));

      try {
        Map<String, dynamic> routeImages =
            (await api.fetchRouteImages(routeIds))["route_images"];
        var fetchedImages = routeImages.map((routeId, model) =>
            MapEntry(int.parse(routeId), RouteImage.fromJson(model)));
        images.addRoutes(fetchedImages);

        yield RouteImagesLoaded(images: images, trigger: event.trigger);
        return;
      } catch (e, st) {
        yield RouteImagesError(exception: e, stackTrace: st);
      }
    } else if (event is FetchRouteImagesAll) {
      yield RouteImagesLoading();

      try {
        List<dynamic> routeImages =
            (await api.fetchRouteImagesAllRoute(event.routeId))["route_images"];
        var fetchedImages = routeImages.map((model) => RouteImage.fromJson(model)).toList();
        images.addRouteImages(event.routeId, fetchedImages);

        yield RouteImagesLoaded(images: images);
      } catch (e, st) {
        yield RouteImagesError(exception: e, stackTrace: st);
      }
  } else if (event is AddNewRouteImage) {
      // Not uploading image to the database via API because all images are
      // uploaded as part of predictions at the moment.
      api.routeMatch(event.routeId, event.routeImage.id);

      images.addRoutes({event.routeId: event.routeImage});

      yield RouteImagesLoaded(images: images, trigger: event.trigger);
    } else if (event is UpdateRouteImage) {
      api.routeMatch(event.routeId, event.routeImageId);
    }
  }
}
