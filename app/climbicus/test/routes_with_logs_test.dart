import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/models/route.dart' as jsonmdl;
import 'package:climbicus/models/user_route_log.dart';
import 'package:climbicus/utils/route_grades.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes with logs - adding new routes and logs', () {
    var newRoutes = {
      1: jsonmdl.Route(1, 1, 1, "sport", "Font_4+", "Font_4+", DateTime.now()),
      2: jsonmdl.Route(2, 1, 1, "sport", "Font_5+", "Font_5+", DateTime.now()),
    };

    var newLogbook = {
      1: UserRouteLog(1, 1, 1, 1, false, 5, DateTime.utc(2020, 02, 01)),
      2: UserRouteLog(2, 1, 1, 1, false, 1, DateTime.utc(2020, 03, 01)),
      3: UserRouteLog(3, 1, 1, 1, false, 1, DateTime.utc(2020, 01, 01)),
    };

    var routesWithLogs = RoutesWithLogs(newRoutes, newLogbook);

    var allRoutes = {
      1: RouteWithLogs(
        newRoutes[1],
        newLogbook,
      ),
      2: RouteWithLogs(
        newRoutes[2],
        {},
      ),
    };

    // allRoutes
    expect(routesWithLogs.allRoutes().length, 2);
    expect(routesWithLogs.allRoutes()[1].route, allRoutes[1].route);
    expect(routesWithLogs.allRoutes()[1].userRouteLogs, allRoutes[1].userRouteLogs);
    expect(routesWithLogs.allRoutes()[2].route, allRoutes[2].route);
    expect(routesWithLogs.allRoutes()[2].userRouteLogs, allRoutes[2].userRouteLogs);

    // addRoute
    var thirdRoute = jsonmdl.Route(3, 1, 1, "sport", "Font_6A", "Font_6A", DateTime.now());
    routesWithLogs.addRoute(thirdRoute);
    expect(routesWithLogs.allRoutes()[3].route, thirdRoute);
    expect(routesWithLogs.allRoutes()[3].userRouteLogs, {});

    // addUserRouteLog
    var fourthLog = UserRouteLog(4, 3, 1, 1, false, 5, DateTime.now());
    routesWithLogs.addUserRouteLog(fourthLog);
    expect(routesWithLogs.allRoutes()[3].userRouteLogs, {4: fourthLog});

    expect(routesWithLogs.allRoutes()[1].mostRecentLog(), newLogbook[2]);
  });

  test('routes with logs - filters', () {
    var newRoutes = {
      1: jsonmdl.Route(1, 1, 1, "sport", "Font_4+", "Font_4+", DateTime.now()),
      2: jsonmdl.Route(2, 1, 1, "sport", "Font_5+", "Font_5+", DateTime.now()),
      3: jsonmdl.Route(3, 1, 1, "sport", "Font_6A", "Font_6A", DateTime.now()),
      4: jsonmdl.Route(4, 1, 1, "sport", "Font_6B", "Font_6B", DateTime.now()),
      5: jsonmdl.Route(5, 1, 1, "sport", "Font_6C", "Font_6C", DateTime.now()),
    };

    var newLogbook = {
      1: UserRouteLog(1, 1, 1, 1, false, 5, DateTime.now()),
      2: UserRouteLog(2, 1, 1, 1, false, 1, DateTime.now()),
      3: UserRouteLog(3, 1, 1, 1, true, 2, DateTime.now()),
      4: UserRouteLog(4, 2, 1, 1, false, 5, DateTime.now()),
      5: UserRouteLog(5, 2, 1, 1, false, 5, DateTime.now()),
      6: UserRouteLog(6, 3, 1, 1, true, 5, DateTime.now()),
      7: UserRouteLog(7, 4, 1, 1, false, 5, DateTime.now()),
    };

    var routesWithLogs = RoutesWithLogs(newRoutes, newLogbook);

    expect(routesWithLogs.isEmpty, false);
    expect(routesWithLogs.routeIds(), [1, 2, 3, 4, 5]);

    var filteredSent = RoutesWithLogs.fromRoutesWithLogs(routesWithLogs)
      ..filterSent("sport");
    expect(filteredSent.routeIds(), [2, 4, 5]);

    var filteredAttempted = RoutesWithLogs.fromRoutesWithLogs(routesWithLogs)
      ..filterAttempted("sport");
    expect(filteredAttempted.routeIds(), [1, 3]);

    var filteredGrades = RoutesWithLogs.fromRoutesWithLogs(routesWithLogs)
      ..filterGrades("sport", GradeValues(GRADE_SYSTEMS["Font"].indexOf("6A"), GRADE_SYSTEMS["Font"].indexOf("6B")));
    expect(filteredGrades.routeIds(), [3, 4]);
  });

  test('routes with logs - grade filters', () {
    var newRoutes = {
      1: jsonmdl.Route(1, 1, 1, "bouldering", "V_V1", "V_V1", DateTime.now()),
      2: jsonmdl.Route(2, 1, 1, "bouldering", "V_V2", "V_V3", DateTime.now()),
      3: jsonmdl.Route(3, 1, 1, "bouldering", "V_V4", "V_V4", DateTime.now()),
      4: jsonmdl.Route(4, 1, 1, "bouldering", "V_V4", "V_V5", DateTime.now()),
      5: jsonmdl.Route(5, 1, 1, "bouldering", "V_V5", "V_V5", DateTime.now()),
      6: jsonmdl.Route(6, 1, 1, "bouldering", "V_V6", "V_V7", DateTime.now()),
      7: jsonmdl.Route(7, 1, 1, "bouldering", "V_V7", "V_V7", DateTime.now()),
    };

    var routesWithLogs = RoutesWithLogs(newRoutes, {});

    expect(routesWithLogs.isEmpty, false);
    expect(routesWithLogs.routeIds(), [1, 2, 3, 4, 5, 6, 7]);

    var filteredGrades = RoutesWithLogs.fromRoutesWithLogs(routesWithLogs)
      ..filterGrades("bouldering", GradeValues(GRADE_SYSTEMS["V"].indexOf("V5"), GRADE_SYSTEMS["V"].indexOf("V6")));
    expect(filteredGrades.routeIds(), [4, 5, 6]);
  });
}
