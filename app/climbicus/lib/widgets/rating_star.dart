
import 'package:climbicus/blocs/gym_routes_bloc.dart';
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
  Widget ratingBarIndicator = RatingBar(
    itemSize: 20.0,
    initialRating: routeWithUserMeta.route.avgQuality ?? 0.0,
    itemCount: 3,
    ratingWidget: ratingStar(
      context,
      disabled: routeWithUserMeta.route.avgQuality == null,
    ),
    onRatingUpdate: (_) => {},
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
