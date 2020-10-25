
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';


RatingWidget ratingStar() {
  return RatingWidget(
    full: const Icon(Icons.star),
    half: const Icon(Icons.star_half),
    empty: const Icon(Icons.star_border),
  );
}
