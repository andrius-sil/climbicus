
import 'package:flutter/material.dart';


const COLUMN_PADDING = 10.0;

const HEADING_SIZE_3 = 18.0;
const HEADING_SIZE_4 = 16.0;
const HEADING_SIZE_5 = 14.0;
const HEADING_SIZE_6 = 12.0;

double screenSmallOrLarge(BuildContext context, double small, double large) {
  double width = MediaQuery.of(context).size.width;
  return (width <= 320.0) ? small : large;
}

double headingSize5or6(BuildContext context) {
  return screenSmallOrLarge(context, HEADING_SIZE_6, HEADING_SIZE_5);
}

final primaryColorLight = Colors.grey[700];

// Using 'primaryColor' for flat button text color explicitly,
// until https://github.com/flutter/flutter/issues/54776 is fixed.

final accentColor = Colors.orangeAccent[700];

final appTheme = () =>  ThemeData(
  brightness: Brightness.dark,

  primaryColor: Colors.grey[900],
  accentColor: accentColor,

  buttonColor: accentColor,
  toggleableActiveColor: accentColor,

  iconTheme: IconThemeData(
    color: accentColor,
  ),

  sliderTheme: SliderThemeData.fromPrimaryColors(
      primaryColor: accentColor,
      primaryColorDark: accentColor,
      primaryColorLight: accentColor,
      valueIndicatorTextStyle: TextStyle(),
  ),

  fontFamily: 'Helvetica',
);
