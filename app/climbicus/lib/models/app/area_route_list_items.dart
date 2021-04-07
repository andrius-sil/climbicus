import 'package:climbicus/models/app/route_user_meta.dart';
import 'package:climbicus/models/area.dart';
import 'package:flutter/material.dart';

class RouteListItem {
  RouteWithUserMeta routeWithUserMeta;
  Widget image;
  bool isExpanded;
  RouteListItem({
    this.routeWithUserMeta,
    this.image,
    this.isExpanded: false
  });
}


class AreaItem {
  final Area area;
  final List<RouteListItem> routeItems;
  bool isExpanded;

  AreaItem(this.area, this.routeItems, this.isExpanded);
}


class AreaItems {
  List<RouteListItem> _items = [];
  Map<int, AreaItem> _itemsByArea = {};
  List<int> _itemsByAreaIndices = [];
  Map<int, bool> _isExpandedPrevious = {};

  get items => _items;
  Iterable<MapEntry<int, AreaItem>> get itemsByArea => _itemsByArea.entries.where((e) => e.value.routeItems.isNotEmpty);


  void reset(Map<int, Area> areas) {
    _items.forEach((item) => _isExpandedPrevious[item.routeWithUserMeta.route.id] = item.isExpanded);
    _items.clear();

    Map<int, bool> isExpandedPreviousArea = {};
    _itemsByAreaIndices.asMap().forEach((idx, areaId) => isExpandedPreviousArea[areaId] = _itemsByArea[areaId].isExpanded);
    _itemsByArea.clear();
    _itemsByAreaIndices.clear();

    areas.forEach((areaId, area) {
      _itemsByArea[areaId] = AreaItem(
        area,
        [],
        isExpandedPreviousArea[areaId] ?? false,
      );
      _itemsByAreaIndices.add(areaId);
    });
  }

  void add(int areaId, RouteListItem item) {
    _items.add(item);
    _itemsByArea[areaId].routeItems.add(item);
  }

  bool isExpanded(int routeId) {
    return _isExpandedPrevious.containsKey(routeId) ?
      _isExpandedPrevious[routeId] :
      false;
  }

  void expand(int panelIndex, bool isExpanded) {
    _itemsByArea[_itemsByAreaIndices[panelIndex]].isExpanded = !isExpanded;
  }
}
