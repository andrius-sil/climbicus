import 'package:climbicus/models/app/area_route_list_items.dart';
import 'package:climbicus/models/app/route_user_meta.dart';
import 'package:climbicus/models/area.dart';
import 'package:climbicus/models/route.dart' as jsonmdl;

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('area items', () {
    var areas = {
      1: Area(1, 1, 1, "one", "", "", DateTime.now()),
      2: Area(2, 1, 1, "two", "", "", DateTime.now()),
      3: Area(3, 1, 1, "three", "", "", DateTime.now()),
    };
    var areaItems = AreaItems();

    areaItems.reset(areas);

    expect(areaItems.items, []);
    expect(Map.fromIterable(areaItems.itemsByArea), {});

    var item1 = RouteListItem(
      routeWithUserMeta: RouteWithUserMeta(
        jsonmdl.Route(1, null, null, null, null, null, null, null, null, null, null, null),
        null,
        null,
      ),
      image: null,
      isExpanded: false,
    );
    var item2 = RouteListItem(
      routeWithUserMeta: RouteWithUserMeta(
        jsonmdl.Route(2, null, null, null, null, null, null, null, null, null, null, null),
        null,
        null,
      ),
      image: null,
      isExpanded: false,
    );

    areaItems.add(2, item1);
    areaItems.add(3, item2);

    expect(areaItems.items, [item1, item2]);
    expect(Map.fromEntries(areaItems.itemsByArea).length, 2);

    expect(Map.fromEntries(areaItems.itemsByArea)[2]!.isExpanded, false);
    expect(Map.fromEntries(areaItems.itemsByArea)[3]!.isExpanded, false);
    expect(areaItems.isExpanded(0), false);
    expect(areaItems.isExpanded(1), false);
    expect(areaItems.isExpanded(2), false);

    item1.isExpanded = true;
    areaItems.expand(0, false);

    expect(Map.fromEntries(areaItems.itemsByArea)[2]!.isExpanded, true);
    expect(Map.fromEntries(areaItems.itemsByArea)[3]!.isExpanded, false);
    expect(areaItems.isExpanded(0), false);
    expect(areaItems.isExpanded(1), false);
    expect(areaItems.isExpanded(2), false);

    areaItems.reset(areas);
    areaItems.add(2, item1);
    areaItems.add(3, item2);

    expect(Map.fromEntries(areaItems.itemsByArea)[2]!.isExpanded, true);
    expect(Map.fromEntries(areaItems.itemsByArea)[3]!.isExpanded, false);
    expect(areaItems.isExpanded(0), false);
    expect(areaItems.isExpanded(1), true);
    expect(areaItems.isExpanded(2), false);
  });
}
