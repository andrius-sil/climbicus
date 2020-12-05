
import 'package:flutter/material.dart';


const COLUMN_PADDING = 10.0;

const HEADING_SIZE_3 = 18.0;
const HEADING_SIZE_4 = 16.0;

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
