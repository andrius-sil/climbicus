
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/models/route_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('route images can be added added', () {
    var images = Images();

    // Add 10 new routes.
    var routeIds = List<int>.generate(10, (int index) => index + 1);
    var routes = Map<int, RouteImage>.fromIterable(routeIds,
      key: (id) => id,
      value: (id) => RouteImage(id, 1, id, DateTime.now(), "", ""),
    );
    images.addRoutes(routes);
    routeIds.forEach((index) {
      expect(images.defaultImage(index), routes[index]);
    });
    expect(images.defaultImage(11), null);

    // Add 10 images to an existing route.
    var routeImageIds = List<int>.generate(20, (int index) => index + 11);
    var routeImages = routeImageIds.map(
            (id) => RouteImage(id, 1, 5, DateTime.now(), "", "")
    ).toList();
    images.addRouteImages(5, routeImages);
    expect(images.allImages(5).values, routeImages);

    expect(images.allImages(1)[1], routes[1]);
    expect(images.allImages(1)[2], null);
    expect(images.allImages(11), null);
  });
}