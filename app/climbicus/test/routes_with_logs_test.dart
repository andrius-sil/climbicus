import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/models/route.dart' as jsonmdl;
import 'package:climbicus/models/user_route_log.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes with logs - adding new routes and logs', () {
    var newRoutes = {
      1: jsonmdl.Route(1, 1, 1, "sport", "4+", "4+", DateTime.now()),
      2: jsonmdl.Route(2, 1, 1, "sport", "5+", "5+", DateTime.now()),
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
    var thirdRoute = jsonmdl.Route(3, 1, 1, "sport", "6", "4", DateTime.now());
    routesWithLogs.addRoute(thirdRoute);
    expect(routesWithLogs.allRoutes()[3].route, thirdRoute);
    expect(routesWithLogs.allRoutes()[3].userRouteLogs, {});

    // addUserRouteLog
    var fourthLog = UserRouteLog(4, 3, 1, 1, false, 5, DateTime.now());
    routesWithLogs.addUserRouteLog(fourthLog);
    expect(routesWithLogs.allRoutes()[3].userRouteLogs, {4: fourthLog});

    expect(routesWithLogs.allRoutes()[1].mostRecentLog(), newLogbook[2]);
  });

  test('routes with logs', () {
    var newRoutes = {
      1: jsonmdl.Route(1, 1, 1, "sport", "4+", "4+", DateTime.now()),
      2: jsonmdl.Route(2, 1, 1, "sport", "5+", "5+", DateTime.now()),
      3: jsonmdl.Route(3, 1, 1, "sport", "6A", "6A", DateTime.now()),
      4: jsonmdl.Route(4, 1, 1, "sport", "6B", "6B", DateTime.now()),
      5: jsonmdl.Route(5, 1, 1, "sport", "6C", "6C", DateTime.now()),
    };

    var newLogbook = {
      1: UserRouteLog(1, 1, 1, 1, false, 5, DateTime.now()),
      2: UserRouteLog(2, 1, 1, 1, false, 1, DateTime.now()),
      3: UserRouteLog(3, 1, 1, 1, true, 2, DateTime.now()),
      4: UserRouteLog(4, 2, 1, 1, false, 5, DateTime.now()),
      5: UserRouteLog(5, 2, 1, 1, false, 5, DateTime.now()),
      6: UserRouteLog(6, 3, 1, 1, false, 5, DateTime.now()),
      7: UserRouteLog(7, 4, 1, 1, false, 5, DateTime.now()),
    };

    var routesWithLogs = RoutesWithLogs(newRoutes, newLogbook);

    expect(routesWithLogs.isEmpty, false);
    expect(routesWithLogs.routeIds(), [1, 2, 3, 4, 5]);
  });
}
