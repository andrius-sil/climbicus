import 'dart:collection';

import 'package:climbicus/constants.dart';
import 'package:climbicus/models/route.dart' as jsonmdl;
import 'package:climbicus/models/user_route_log.dart';
import 'package:climbicus/models/user_route_votes.dart';
import 'package:climbicus/utils/route_grades.dart';


class RouteWithUserMeta {
  jsonmdl.Route route;
  Map<int, UserRouteLog> userRouteLogs;
  UserRouteVotes? userRouteVotes;

  RouteWithUserMeta(this.route, this.userRouteLogs, this.userRouteVotes);

  UserRouteLog? mostRecentLog() {
    if (userRouteLogs.isEmpty) {
      return null;
    }

    var sortedKeys = userRouteLogs.keys.toList(growable: false)
      ..sort((k1, k2) => userRouteLogs[k2]!.createdAt.compareTo(userRouteLogs[k1]!.createdAt));

    return userRouteLogs[sortedKeys.first];
  }

  DateTime mostRecentCreatedAt() {
    var log = mostRecentLog();
    if (log != null) {
      return log.createdAt;
    }

    return route.createdAt;
  }

  bool isSent() {
    for (var e in userRouteLogs.entries) {
      if (e.value.completed) {
        return true;
      }
    }

    return false;
  }

  bool isAttempted() => userRouteLogs.isNotEmpty;

  int numAttempts() => route.countAscents;

  double? qualityVote() {
    if (userRouteVotes == null) {
      return null;
    }

    return userRouteVotes!.quality;
  }

  String? difficultyVote() {
    if (userRouteVotes == null) {
      return null;
    }

    return userRouteVotes!.difficulty;
  }
}


class CategoryRoutes {
  Map<int, RouteWithUserMeta> _routes;

  CategoryRoutes(): _routes = {};
  CategoryRoutes.from(CategoryRoutes categoryRoutes): _routes = Map.from(categoryRoutes._routes);

  void add(int routeId, RouteWithUserMeta route) => _routes[routeId] = route;

  void updateRoute(int routeId, jsonmdl.Route route) => _routes[routeId]!.route = route;
  void updateLog(int routeId, int logId, UserRouteLog log) => _routes[routeId]!.userRouteLogs[logId] = log;
  void updateVotes(int routeId, UserRouteVotes votes) => _routes[routeId]!.userRouteVotes = votes;

  void removeLog(int routeId, int logId) => _routes[routeId]!.userRouteLogs.remove(logId);

  RouteWithUserMeta? getRoute(int routeId) => _routes[routeId];

  bool get isEmpty => _routes.isEmpty;

  int get length => _routes.length;

  List<int> routeIds() => _routes.keys.toList();

  void filterSent() {
    _routes.removeWhere((routeId, routeWithUserMeta) => (routeWithUserMeta.isSent()));
  }

  void filterAttempted() {
    _routes.removeWhere((routeId, routeWithUserMeta) => (routeWithUserMeta.isAttempted()));
  }

  void filterGrades(GradeValues gradeValues) {
    _routes.removeWhere((routeId, routeWithUserMeta) =>
      ((routeWithUserMeta.route.upperGradeIndex() < gradeValues.start) ||
       (routeWithUserMeta.route.lowerGradeIndex() > gradeValues.end))
    );
  }

  Map<int, RouteWithUserMeta> sortEntriesByLogDate() {
    var sortedKeys = _routes.keys.toList(growable: false)
      ..sort((k1, k2) => _routes[k2]!.mostRecentCreatedAt().compareTo(_routes[k1]!.mostRecentCreatedAt()));

    return LinkedHashMap.fromIterable(sortedKeys, key: ((k) => k), value: ((k) => _routes[k]!));
  }

}


class GymRoutes {
  late Map<String, CategoryRoutes> _data;
  late Map<int, jsonmdl.Route> _routes;

  GymRoutes(
      Map<int, jsonmdl.Route> newRoutes,
      Map<int, UserRouteLog> newLogbook,
      Map<int, UserRouteVotes> newVotes,
      ) {

    _routes = newRoutes;
    _data = Map.fromIterable(ROUTE_CATEGORIES,
      key: (category) => category,
      value: (_) => CategoryRoutes(),
    );

    newRoutes.forEach((routeId, route) {
      _data[route.category]!.add(routeId, RouteWithUserMeta(route, {}, null));
    });

    newLogbook.forEach((_, userRouteLog) {
      addUserRouteLog(userRouteLog);
    });

    newVotes.forEach((_, userRouteVotes) {
      addUserRouteVotes(userRouteVotes);
    });
  }

  GymRoutes.from(GymRoutes gymRoutes) {
    _data = Map.fromIterable(ROUTE_CATEGORIES,
      key: (category) => category,
      value: ((category) => CategoryRoutes.from(gymRoutes._data[category]!)),
    );
    _routes = gymRoutes._routes;
  }

  bool isEmpty(String category) => _data[category]!.isEmpty;

  List<int> routeIdsAll() => _routes.keys.toList();
  List<int> routeIds(String category) => _data[category]!.routeIds();

  void addRoute(jsonmdl.Route route, UserRouteVotes? userRouteVotes) {
    _routes[route.id] = route;
    _data[route.category]!.add(route.id, RouteWithUserMeta(route, {}, userRouteVotes));
  }

  void updateRoute(jsonmdl.Route route,
      {UserRouteVotes? userRouteVotes, UserRouteLog? userRouteLog}) {
    _routes[route.id] = route;
    _data[route.category]!.updateRoute(route.id, route);
    if (userRouteVotes != null) {
      _data[route.category]!.updateVotes(route.id, userRouteVotes);
    }
    if (userRouteLog != null) {
      _data[route.category]!.updateLog(route.id, userRouteLog.id, userRouteLog);
    }
  }

  void addUserRouteLog(UserRouteLog userRouteLog) {
    String category = _routes[userRouteLog.routeId]!.category;
    _data[category]!.updateLog(userRouteLog.routeId, userRouteLog.id, userRouteLog);
  }

  void deleteUserRouteLog(UserRouteLog userRouteLog) {
    String category = _routes[userRouteLog.routeId]!.category;
    _data[category]!.removeLog(userRouteLog.routeId, userRouteLog.id);
  }

  void addUserRouteVotes(UserRouteVotes userRouteVotes) {
    String category = _routes[userRouteVotes.routeId]!.category;
    _data[category]!.updateVotes(userRouteVotes.routeId, userRouteVotes);
  }

  UserRouteVotes? getUserRouteVotes(int routeId) {
    String category = _routes[routeId]!.category;
    return _data[category]!.getRoute(routeId)!.userRouteVotes;
  }

  CategoryRoutes? allRoutes(String category) => _data[category];

  void filterSent(String category) {
    _data[category]!.filterSent();
  }

  void filterAttempted(String category) {
    _data[category]!.filterAttempted();
  }

  void filterGrades(String category, GradeValues gradeValues) {
    _data[category]!.filterGrades(gradeValues);
  }
}

