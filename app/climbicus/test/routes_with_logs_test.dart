import 'package:climbicus/constants.dart';
import 'package:climbicus/models/app/route_user_meta.dart';
import 'package:climbicus/models/route.dart' as jsonmdl;
import 'package:climbicus/models/user_route_log.dart';
import 'package:climbicus/models/user_route_votes.dart';
import 'package:climbicus/utils/route_grades.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes with logs - adding new routes and logs', () {
    var newRoutes = {
      1: jsonmdl.Route(1, 1, 1, 1, "sport", "", "Font_4+", "Font_4+", null, null, 2, DateTime.now()),
      2: jsonmdl.Route(2, 1, 1, 1, "sport", "", "Font_5+", "Font_5+", null, null, 0, DateTime.now()),
      3: jsonmdl.Route(3, 1, 1, 1, "bouldering", "", "V_V1", "V_V1", null, null, 2, DateTime.now()),
      4: jsonmdl.Route(4, 1, 1, 1, "bouldering", "", "V_V2", "V_V2", null, null, 0, DateTime.now()),
    };

    var newLogbook1 = {
      1: UserRouteLog(1, 1, 1, 1, false, 5, DateTime.utc(2020, 02, 01)),
      2: UserRouteLog(2, 1, 1, 1, false, 1, DateTime.utc(2020, 03, 01)),
    };

    var newLogbook2 = {
      3: UserRouteLog(3, 3, 1, 1, false, 1, DateTime.utc(2020, 01, 01)),
      4: UserRouteLog(4, 3, 1, 1, false, 1, DateTime.utc(2020, 01, 01)),
    };

    var newVotes = {
      1: UserRouteVotes(1, 1, 1, 1, 2.0, DIFFICULTY_SOFT, DateTime.utc(2020, 02, 01)),
      2: UserRouteVotes(2, 3, 1, 1, 1.0, DIFFICULTY_FAIR, DateTime.utc(2020, 03, 01)),
    };

    var routesWithUserMeta = RoutesWithUserMeta(
      newRoutes,
      {}..addAll(newLogbook1)..addAll(newLogbook2),
      newVotes,
    );

    var allRoutes = {
      1: RouteWithUserMeta(
        newRoutes[1],
        newLogbook1,
        newVotes[1],
      ),
      2: RouteWithUserMeta(
        newRoutes[2],
        {},
        null,
      ),
      3: RouteWithUserMeta(
        newRoutes[3],
        newLogbook2,
        newVotes[2],
      ),
      4: RouteWithUserMeta(
        newRoutes[4],
        {},
        null,
      ),
    };

    expect(routesWithUserMeta.routeIdsAll(), [1, 2, 3, 4]);

    // allRoutes
    expect(routesWithUserMeta.routeIds("sport"), [1, 2]);
    expect(routesWithUserMeta.allRoutes("sport").length, 2);
    expect(routesWithUserMeta.allRoutes("sport")[1].route, allRoutes[1].route);
    expect(routesWithUserMeta.allRoutes("sport")[1].userRouteLogs, allRoutes[1].userRouteLogs);
    expect(routesWithUserMeta.allRoutes("sport")[1].userRouteVotes, allRoutes[1].userRouteVotes);
    expect(routesWithUserMeta.allRoutes("sport")[2].route, allRoutes[2].route);
    expect(routesWithUserMeta.allRoutes("sport")[2].userRouteLogs, allRoutes[2].userRouteLogs);
    expect(routesWithUserMeta.allRoutes("sport")[2].userRouteVotes, allRoutes[2].userRouteVotes);

    expect(routesWithUserMeta.routeIds("bouldering"), [3, 4]);
    expect(routesWithUserMeta.allRoutes("bouldering").length, 2);
    expect(routesWithUserMeta.allRoutes("bouldering")[3].route, allRoutes[3].route);
    expect(routesWithUserMeta.allRoutes("bouldering")[3].userRouteLogs, allRoutes[3].userRouteLogs);
    expect(routesWithUserMeta.allRoutes("bouldering")[3].userRouteVotes, allRoutes[3].userRouteVotes);
    expect(routesWithUserMeta.allRoutes("bouldering")[4].route, allRoutes[4].route);
    expect(routesWithUserMeta.allRoutes("bouldering")[4].userRouteLogs, allRoutes[4].userRouteLogs);
    expect(routesWithUserMeta.allRoutes("bouldering")[4].userRouteVotes, allRoutes[4].userRouteVotes);

    // addRoute
    var fifthRoute = jsonmdl.Route(5, 1, 1, 1, "sport", "", "Font_6A", "Font_6A", null, null, 1, DateTime.now());
    var thirdVote = UserRouteVotes(3, 5, 1, 1, 3.0, DIFFICULTY_FAIR, DateTime.utc(2020, 02, 01));
    routesWithUserMeta.addRoute(fifthRoute, thirdVote);
    expect(routesWithUserMeta.routeIdsAll(), [1, 2, 3, 4, 5]);
    expect(routesWithUserMeta.allRoutes("sport")[5].route, fifthRoute);
    expect(routesWithUserMeta.allRoutes("sport")[5].userRouteLogs, {});
    expect(routesWithUserMeta.allRoutes("sport")[5].userRouteVotes, thirdVote);

    // addUserRouteLog
    var fifthLog = UserRouteLog(5, 5, 1, 1, false, 5, DateTime.now());
    routesWithUserMeta.addUserRouteLog(fifthLog);
    expect(routesWithUserMeta.allRoutes("sport")[5].userRouteLogs, {5: fifthLog});

    // addUserRouteVotes
    var fourthVote = UserRouteVotes(4, 2, 1, 1, 3.0, DIFFICULTY_HARD, DateTime.utc(2020, 02, 01));
    routesWithUserMeta.addUserRouteVotes(fourthVote);
    expect(routesWithUserMeta.allRoutes("sport")[2].userRouteVotes, fourthVote);

    expect(routesWithUserMeta.allRoutes("sport")[1].mostRecentLog(), newLogbook1[2]);

    // numAttempts
    expect(routesWithUserMeta.allRoutes("sport")[1].numAttempts(), 2);
    expect(routesWithUserMeta.allRoutes("sport")[2].numAttempts(), 0);
    expect(routesWithUserMeta.allRoutes("bouldering")[3].numAttempts(), 2);
    expect(routesWithUserMeta.allRoutes("bouldering")[4].numAttempts(), 0);
    expect(routesWithUserMeta.allRoutes("sport")[5].numAttempts(), 1);

    // qualityVote
    expect(routesWithUserMeta.allRoutes("sport")[1].qualityVote(), 2.0);
    expect(routesWithUserMeta.allRoutes("sport")[2].qualityVote(), 3.0);
    expect(routesWithUserMeta.allRoutes("bouldering")[3].qualityVote(), 1.0);
    expect(routesWithUserMeta.allRoutes("bouldering")[4].qualityVote(), null);
    expect(routesWithUserMeta.allRoutes("sport")[5].qualityVote(), 3.0);

    // difficultyVote
    expect(routesWithUserMeta.allRoutes("sport")[1].difficultyVote(), DIFFICULTY_SOFT);
    expect(routesWithUserMeta.allRoutes("sport")[2].difficultyVote(), DIFFICULTY_HARD);
    expect(routesWithUserMeta.allRoutes("bouldering")[3].difficultyVote(), DIFFICULTY_FAIR);
    expect(routesWithUserMeta.allRoutes("bouldering")[4].difficultyVote(), null);
    expect(routesWithUserMeta.allRoutes("sport")[5].difficultyVote(), DIFFICULTY_FAIR);

    // deleteUserRouteLog
    expect(routesWithUserMeta.allRoutes("sport")[1].userRouteLogs, newLogbook1);
    expect(routesWithUserMeta.allRoutes("sport")[1].mostRecentLog(), newLogbook1[2]);
    routesWithUserMeta.deleteUserRouteLog(newLogbook1[2]);
    expect(routesWithUserMeta.allRoutes("sport")[1].userRouteLogs, {1: newLogbook1[1]});
    expect(routesWithUserMeta.allRoutes("sport")[1].mostRecentLog(), newLogbook1[1]);
    routesWithUserMeta.deleteUserRouteLog(newLogbook1[1]);
    expect(routesWithUserMeta.allRoutes("sport")[1].userRouteLogs, {});
    expect(routesWithUserMeta.allRoutes("sport")[1].mostRecentLog(), null);
  });

  test('routes with logs - filters', () {
    var newRoutes = {
      1: jsonmdl.Route(1, 1, 1, 1, "sport", "", "Font_4+", "Font_4+", null, null, 0, DateTime.now()),
      2: jsonmdl.Route(2, 1, 1, 1, "sport", "", "Font_5+", "Font_5+", null, null, 0, DateTime.now()),
      3: jsonmdl.Route(3, 1, 1, 1, "sport", "", "Font_6A", "Font_6A", null, null, 0, DateTime.now()),
      4: jsonmdl.Route(4, 1, 1, 1, "sport", "", "Font_6B", "Font_6B", null, null, 0, DateTime.now()),
      5: jsonmdl.Route(5, 1, 1, 1, "sport", "", "Font_6C", "Font_6C", null, null, 0, DateTime.now()),
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

    var routesWithUserMeta = RoutesWithUserMeta(newRoutes, newLogbook, {});

    expect(routesWithUserMeta.isEmpty("sport"), false);
    expect(routesWithUserMeta.routeIds("sport"), [1, 2, 3, 4, 5]);

    var filteredSent = RoutesWithUserMeta.fromRoutesWithUserMeta(routesWithUserMeta)
      ..filterSent("sport");
    expect(filteredSent.routeIds("sport"), [2, 4, 5]);

    var filteredAttempted = RoutesWithUserMeta.fromRoutesWithUserMeta(routesWithUserMeta)
      ..filterAttempted("sport");
    expect(filteredAttempted.routeIds("sport"), [5]);

    var filteredGrades = RoutesWithUserMeta.fromRoutesWithUserMeta(routesWithUserMeta)
      ..filterGrades("sport", GradeValues(GRADE_SYSTEMS["Font"].indexOf("6A"), GRADE_SYSTEMS["Font"].indexOf("6B")));
    expect(filteredGrades.routeIds("sport"), [3, 4]);
  });

  test('routes with logs - grade filters', () {
    var newRoutes = {
      1: jsonmdl.Route(1, 1, 1, 1, "bouldering", "", "V_V1", "V_V1", null, null, 0, DateTime.now()),
      2: jsonmdl.Route(2, 1, 1, 1, "bouldering", "", "V_V2", "V_V3", null, null, 0, DateTime.now()),
      3: jsonmdl.Route(3, 1, 1, 1, "bouldering", "", "V_V4", "V_V4", null, null, 0, DateTime.now()),
      4: jsonmdl.Route(4, 1, 1, 1, "bouldering", "", "V_V4", "V_V5", null, null, 0, DateTime.now()),
      5: jsonmdl.Route(5, 1, 1, 1, "bouldering", "", "V_V5", "V_V5", null, null, 0, DateTime.now()),
      6: jsonmdl.Route(6, 1, 1, 1, "bouldering", "", "V_V6", "V_V7", null, null, 0, DateTime.now()),
      7: jsonmdl.Route(7, 1, 1, 1, "bouldering", "", "V_V7", "V_V7", null, null, 0, DateTime.now()),
    };

    var routesWithUserMeta = RoutesWithUserMeta(newRoutes, {}, {});

    expect(routesWithUserMeta.isEmpty("bouldering"), false);
    expect(routesWithUserMeta.routeIds("bouldering"), [1, 2, 3, 4, 5, 6, 7]);

    var filteredGrades = RoutesWithUserMeta.fromRoutesWithUserMeta(routesWithUserMeta)
      ..filterGrades("bouldering", GradeValues(GRADE_SYSTEMS["V"].indexOf("V5"), GRADE_SYSTEMS["V"].indexOf("V6")));
    expect(filteredGrades.routeIds("bouldering"), [4, 5, 6]);
  });
}
