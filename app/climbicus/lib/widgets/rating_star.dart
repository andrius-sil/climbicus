
import 'package:climbicus/models/app/route_user_meta.dart';
import 'package:climbicus/models/user_route_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';


RatingWidget ratingStar(BuildContext context, {bool disabled: false}) {
  var color = (disabled) ?
    Theme.of(context).disabledColor :
    Theme.of(context).accentColor;
  return RatingWidget(
    full: Icon(Icons.star, color: color),
    half: Icon(Icons.star_half, color: color),
    empty: Icon(Icons.star_border, color: color),
  );
}


Widget gradeAndDifficulty(RouteWithUserMeta routeWithUserMeta, double height) {
  return Container(
    height: height,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(routeWithUserMeta.route.grade, style: TextStyle(fontSize: 18)),
        Text(
          routeWithUserMeta.route.avgDifficulty ?? "",
          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
        ),
      ],
    ),
  );
}


Widget qualityAndAscents(BuildContext context,
    RouteWithUserMeta routeWithUserMeta, double height) {
  var avgQuality = routeWithUserMeta.route.avgQuality ?? 0.0;
  Widget ratingBarIndicator = RatingBarIndicator(
    itemSize: 20.0,
    rating: avgQuality,
    itemCount: 3,
    itemBuilder: (context, index) {
      // Use border stars icons for "unfilled" rating part.
      if (avgQuality < index + 1) {
        return Icon(Icons.star_border);
      } else {
        return Icon(Icons.star);
      }
    },
  );

  return Container(
    height: height,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ratingBarIndicator,
        Text(
          (routeWithUserMeta.numAttempts() == 1) ?
            "${routeWithUserMeta.numAttempts().toString()} ascent" :
            "${routeWithUserMeta.numAttempts().toString()} ascents",
          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
        ),
      ],
    ),
  );
}

class AscentWidget extends StatelessWidget {
  final UserRouteLog userRouteLog;

  AscentWidget(this.userRouteLog);

  @override
  Widget build(BuildContext context) {
    var ascentDecoration;
    var ascentStatus;

    if (userRouteLog != null) {
      var boxColor = (userRouteLog.completed) ?
        Theme.of(context).accentColor :
        null;

      ascentDecoration = BoxDecoration(
        border: Border.all(
          color: Theme.of(context).accentColor,
          width: 2,
        ),
        color: boxColor,
        borderRadius: BorderRadius.circular(12),
      );

      var numAttemptsStr = userRouteLog.numAttempts != null ?
        userRouteLog.numAttempts.toString() :
        " — ";
      ascentStatus = Center(
        child: (userRouteLog.completed && userRouteLog.numAttempts == 1) ?
        Icon(Icons.flash_on, color: Theme.of(context).textTheme.headline6!.color) :
        Text(numAttemptsStr, style: TextStyle(fontSize: 18)),
      );
    }

    return Container(
      height: 60,
      width: 60,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: ascentDecoration,
      child: ascentStatus,
    );
  }
}
