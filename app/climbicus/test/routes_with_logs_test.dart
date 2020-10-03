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
      3: jsonmdl.Route(3, 1, 1, "bouldering", "V_V1", "V_V1", DateTime.now()),
      4: jsonmdl.Route(4, 1, 1, "bouldering", "V_V2", "V_V2", DateTime.now()),
    };

    var newLogbook1 = {
      1: UserRouteLog(1, 1, 1, 1, false, 5, DateTime.utc(2020, 02, 01)),
      2: UserRouteLog(2, 1, 1, 1, false, 1, DateTime.utc(2020, 03, 01)),
    };

    var newLogbook2 = {
      3: UserRouteLog(3, 3, 1, 1, false, 1, DateTime.utc(2020, 01, 01)),
      4: UserRouteLog(4, 3, 1, 1, false, 1, DateTime.utc(2020, 01, 01)),
    };

    var routesWithLogs = RoutesWithLogs(newRoutes, {}..addAll(newLogbook1)..addAll(newLogbook2));

    var allRoutes = {
      1: RouteWithLogs(
        newRoutes[1],
        newLogbook1,
      ),
      2: RouteWithLogs(
        newRoutes[2],
        {},
      ),
      3: RouteWithLogs(
        newRoutes[3],
        newLogbook2,
      ),
      4: RouteWithLogs(
        newRoutes[4],
        {},
      ),
    };

    expect(routesWithLogs.routeIdsAll(), [1, 2, 3, 4]);

    // allRoutes
    expect(routesWithLogs.routeIds("sport"), [1, 2]);
    expect(routesWithLogs.allRoutes("sport").length, 2);
    expect(routesWithLogs.allRoutes("sport")[1].route, allRoutes[1].route);
    expect(routesWithLogs.allRoutes("sport")[1].userRouteLogs, allRoutes[1].userRouteLogs);
    expect(routesWithLogs.allRoutes("sport")[2].route, allRoutes[2].route);
    expect(routesWithLogs.allRoutes("sport")[2].userRouteLogs, allRoutes[2].userRouteLogs);

    expect(routesWithLogs.routeIds("bouldering"), [3, 4]);
    expect(routesWithLogs.allRoutes("bouldering").length, 2);
    expect(routesWithLogs.allRoutes("bouldering")[3].route, allRoutes[3].route);
    expect(routesWithLogs.allRoutes("bouldering")[3].userRouteLogs, allRoutes[3].userRouteLogs);
    expect(routesWithLogs.allRoutes("bouldering")[4].route, allRoutes[4].route);
    expect(routesWithLogs.allRoutes("bouldering")[4].userRouteLogs, allRoutes[4].userRouteLogs);

    // addRoute
    var fifthRoute = jsonmdl.Route(5, 1, 1, "sport", "Font_6A", "Font_6A", DateTime.now());
    routesWithLogs.addRoute(fifthRoute);
    expect(routesWithLogs.routeIdsAll(), [1, 2, 3, 4, 5]);
    expect(routesWithLogs.allRoutes("sport")[5].route, fifthRoute);
    expect(routesWithLogs.allRoutes("sport")[5].userRouteLogs, {});

    // addUserRouteLog
    var fifthLog = UserRouteLog(5, 5, 1, 1, false, 5, DateTime.now());
    routesWithLogs.addUserRouteLog(fifthLog);
    expect(routesWithLogs.allRoutes("sport")[5].userRouteLogs, {5: fifthLog});

    expect(routesWithLogs.allRoutes("sport")[1].mostRecentLog(), newLogbook1[2]);
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

    expect(routesWithLogs.isEmpty("sport"), false);
    expect(routesWithLogs.routeIds("sport"), [1, 2, 3, 4, 5]);

    var filteredSent = RoutesWithLogs.fromRoutesWithLogs(routesWithLogs)
      ..filterSent("sport");
    expect(filteredSent.routeIds("sport"), [2, 4, 5]);

    var filteredAttempted = RoutesWithLogs.fromRoutesWithLogs(routesWithLogs)
      ..filterAttempted("sport");
    expect(filteredAttempted.routeIds("sport"), [5]);

    var filteredGrades = RoutesWithLogs.fromRoutesWithLogs(routesWithLogs)
      ..filterGrades("sport", GradeValues(GRADE_SYSTEMS["Font"].indexOf("6A"), GRADE_SYSTEMS["Font"].indexOf("6B")));
    expect(filteredGrades.routeIds("sport"), [3, 4]);
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

    expect(routesWithLogs.isEmpty("bouldering"), false);
    expect(routesWithLogs.routeIds("bouldering"), [1, 2, 3, 4, 5, 6, 7]);

    var filteredGrades = RoutesWithLogs.fromRoutesWithLogs(routesWithLogs)
      ..filterGrades("bouldering", GradeValues(GRADE_SYSTEMS["V"].indexOf("V5"), GRADE_SYSTEMS["V"].indexOf("V6")));
    expect(filteredGrades.routeIds("bouldering"), [4, 5, 6]);
  });
}