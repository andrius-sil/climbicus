
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
