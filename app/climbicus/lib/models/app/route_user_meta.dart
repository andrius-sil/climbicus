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

class RoutesWithUserMeta {
  late Map<String, Map<int, RouteWithUserMeta>> _data;
  late Map<int, jsonmdl.Route> _routes;

  RoutesWithUserMeta(
      Map<int, jsonmdl.Route> newRoutes,
      Map<int, UserRouteLog> newLogbook,
      Map<int, UserRouteVotes> newVotes,
      ) {

    _routes = newRoutes;
    _data = Map.fromIterable(ROUTE_CATEGORIES,
      key: (category) => category,
      value: (_) => {},
    );

    newRoutes.forEach((routeId, route) {
      _data[route.category]![routeId] = RouteWithUserMeta(route, {}, null);
    });

    newLogbook.forEach((_, userRouteLog) {
      addUserRouteLog(userRouteLog);
    });

    newVotes.forEach((_, userRouteVotes) {
      addUserRouteVotes(userRouteVotes);
    });
  }

  RouteWithUserMeta getRouteWithUserMeta(int routeId) {
    String category = _routes[routeId]!.category;
    return _data[category]![routeId]!;
  }

  RoutesWithUserMeta.fromRoutesWithUserMeta(RoutesWithUserMeta routesWithUserMeta) {
    _data = Map.fromIterable(ROUTE_CATEGORIES,
      key: (category) => category,
      value: ((category) => routesWithUserMeta._data[category]!) as Map<int, RouteWithUserMeta> Function(dynamic)?,
    );
    _routes = routesWithUserMeta._routes;
  }

  bool isEmpty(String category) => _data[category]!.isEmpty;

  List<int> routeIdsAll() => _routes.keys.toList();
  List<int> routeIds(String category) => _data[category]!.keys.toList();

  void addRoute(jsonmdl.Route route, UserRouteVotes? userRouteVotes) {
    _routes[route.id] = route;
    _data[route.category]![route.id] = RouteWithUserMeta(route, {}, userRouteVotes);
  }

  void updateRoute(jsonmdl.Route route,
      {UserRouteVotes? userRouteVotes, UserRouteLog? userRouteLog}) {
    _routes[route.id] = route;
    _data[route.category]![route.id]!.route = route;
    if (userRouteVotes != null) {
      _data[route.category]![route.id]!.userRouteVotes = userRouteVotes;
    }
    if (userRouteLog != null) {
      _data[route.category]![route.id]!.userRouteLogs[userRouteLog.id] = userRouteLog;
    }
  }

  void addUserRouteLog(UserRouteLog userRouteLog) {
    String category = _routes[userRouteLog.routeId]!.category;
    _data[category]![userRouteLog.routeId]!.userRouteLogs[userRouteLog.id] = userRouteLog;
  }

  void deleteUserRouteLog(UserRouteLog userRouteLog) {
    String category = _routes[userRouteLog.routeId]!.category;
    _data[category]![userRouteLog.routeId]!.userRouteLogs.remove(userRouteLog.id);
  }

  void addUserRouteVotes(UserRouteVotes userRouteVotes) {
    String category = _routes[userRouteVotes.routeId]!.category;
    _data[category]![userRouteVotes.routeId]!.userRouteVotes = userRouteVotes;
  }

  UserRouteVotes? getUserRouteVotes(int routeId) {
    String category = _routes[routeId]!.category;
    return _data[category]![routeId]!.userRouteVotes;
  }

  Map<int, RouteWithUserMeta>? allRoutes(String category) => _data[category];

  void filterSent(String category) {
    _data[category] = Map.from(_data[category]!)..removeWhere((routeId, routeWithUserMeta) =>
    (routeWithUserMeta.isSent()));
  }

  void filterAttempted(String category) {
    _data[category] = Map.from(_data[category]!)..removeWhere((routeId, routeWithUserMeta) =>
    (routeWithUserMeta.isAttempted()));
  }

  void filterGrades(String category, GradeValues gradeValues) {
    _data[category] = Map.from(_data[category]!)..removeWhere((routeId, routeWithUserMeta) =>
    (routeWithUserMeta.route.category == category) && (
        (routeWithUserMeta.route.upperGradeIndex() < gradeValues.start) ||
            (routeWithUserMeta.route.lowerGradeIndex() > gradeValues.end))
    );
  }
}

