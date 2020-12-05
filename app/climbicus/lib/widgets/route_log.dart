
import 'package:climbicus/constants.dart';
import 'package:climbicus/style.dart';
import 'package:climbicus/utils/route_grades.dart';
import 'package:climbicus/widgets/rating_star.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:toggle_switch/toggle_switch.dart';


const NOT_SELECTED = "not selected";


Widget decorateLogWidget(BuildContext context, Widget logWidget) {
  return Container(
    padding: const EdgeInsets.all(4),
    margin: const EdgeInsets.all(4),
    height: 100.0,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.grey[700],
      borderRadius: BorderRadius.circular(6),
    ),
    child: logWidget,
  );
}

class CheckboxSent extends CheckboxWithTitle {
  const CheckboxSent({Key key}) : super(key: key, title: "Sent?");
}

class CheckboxWithTitle extends StatefulWidget {
  final String title;
  final VoidCallback onTicked;
  final bool titleAbove;

  const CheckboxWithTitle({Key key, this.title, this.onTicked, this.titleAbove = true}) : super(key: key);

  @override
  CheckboxWithTitleState createState() => CheckboxWithTitleState();
}

class CheckboxWithTitleState extends State<CheckboxWithTitle> {
  bool _value = false;

  bool get value => _value;

  @override
  Widget build(BuildContext context) {
    var checkbox = Transform.scale(
      scale: 1.0,
      child: Checkbox(
        value: _value,
        onChanged: (bool value) {
          setState(() {
            _value = value;
            if (widget.onTicked != null) {
              widget.onTicked();
            }
          });
        },
      ),
    );

    var titledCheckbox;
    if (widget.titleAbove) {
      titledCheckbox = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(widget.title),
          checkbox,
        ],
      );
    } else {
      titledCheckbox = Row(
        children: <Widget>[
          checkbox,
          Text(widget.title),
        ],
      );
    }

    return decorateLogWidget(context, titledCheckbox);
  }
}


class NumberAttempts extends StatefulWidget {
  const NumberAttempts({Key key}) : super(key: key);

  @override
  NumberAttemptsState createState() => NumberAttemptsState();
}

class NumberAttemptsState extends State<NumberAttempts> {
  int _value = 0;

  int get value => (_value == 0) ? null : _value;

  @override
  Widget build(BuildContext context) {
    return decorateLogWidget(
      context,
      Column(
        children: <Widget>[
          Text("How many attempts?"),
          Container(
            child: NumberPicker.integer(
              initialValue: _value,
              minValue: 0,
              maxValue: 30,
              itemExtent: 25.0,
              textMapper: (String text) => ((text == "0") ? "-" : "$text"),
              onChanged: (num value) => setState(() {
                _value = value.toInt();
              }),
            ),
          ),
        ],
      ),
    );
  }
}


class SliderAttempts extends StatefulWidget {
  const SliderAttempts({Key key}) : super(key: key);

  @override
  SliderAttemptsState createState() => SliderAttemptsState();
}

class SliderAttemptsState extends State<SliderAttempts> {
  double _value;

  int get value => (_value == null) ? null : _value.toInt();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text("How many attempts?\t${_numAttemptsLabel()}"),
        Slider(
          value: (_value == null) ? 0.0 : _value,
          min: 0.0,
          max: 30.0,
          divisions: 30,
          label: _numAttemptsLabel(),
          onChanged: (double value) => setState(() {
            (value == 0.0) ?
            _value = null :
            _value = value;
          }),
        ),
      ],
    );
  }

  String _numAttemptsLabel() {
    return (_value == null) ?
    "-" :
    "${_value.toInt()}";
  }
}


class SliderRouteGrades extends StatefulWidget {
  final String routeCategory;
  final List<String> gradeSystem;
  final VoidCallback onChangeEnd;

  SliderRouteGrades({Key key, this.routeCategory, this.onChangeEnd}) :
    gradeSystem = GRADE_SYSTEMS[DEFAULT_GRADE_SYSTEM[routeCategory]],
    super(key: key);

  @override
  SliderRouteGradesState createState() => SliderRouteGradesState();
}

class SliderRouteGradesState extends State<SliderRouteGrades> {
  RangeValues _values;

  GradeValues get values => GradeValues(_values.start.toInt(), _values.end.toInt());

  @override
  void initState() {
    super.initState();

    _values = RangeValues(0.0, (widget.gradeSystem.length - 1).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 50.0,
          alignment: Alignment.centerRight,
          child: Text(_startLabel(), style: TextStyle(fontSize: HEADING_SIZE_4)),
        ),
        Expanded(
          child: RangeSlider(
            values: _values,
            min: 0.0,
            max: (widget.gradeSystem.length - 1).toDouble(),
            divisions: widget.gradeSystem.length - 1,
            labels: RangeLabels(_startLabel(), _endLabel()),
            onChanged: (RangeValues values) => setState(() {
              _values = values;
            }),
            onChangeEnd: (RangeValues values) => widget.onChangeEnd(),
          ),
        ),
        Container(
          width: 50.0,
          alignment: Alignment.centerLeft,
          child: Text(_endLabel(), style: TextStyle(fontSize: HEADING_SIZE_4)),
        ),
      ],
    );
  }

  String _startLabel() => widget.gradeSystem[_values.start.toInt()];

  String _endLabel() => widget.gradeSystem[_values.end.toInt()];
}


class RouteDifficultyRating extends StatefulWidget {
  final String initialValue;

  const RouteDifficultyRating({Key key, this.initialValue}) : super(key: key);

  @override
  RouteDifficultyRatingState createState() => RouteDifficultyRatingState();
}

class RouteDifficultyRatingState extends State<RouteDifficultyRating> {
  final _labels = [DIFFICULTY_NAME_SOFT, DIFFICULTY_NAME_FAIR, DIFFICULTY_NAME_HARD];
  final _values = [DIFFICULTY_SOFT, DIFFICULTY_FAIR, DIFFICULTY_HARD];

  int _index;

  String get value => (_index == -1) ? null : _values[_index];

  @override
  void initState() {
    super.initState();

    _index = (widget.initialValue == null) ? -1 : _values.indexOf(widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return decorateLogWidget(context, ToggleSwitch(
      activeBgColor: Theme.of(context).accentColor,
      inactiveBgColor: Colors.grey[700],
      cornerRadius: 0.0,
      initialLabelIndex: _index,
      labels: _labels,
      onToggle: (index) => _index = index,
      minWidth: 48.0,
    ));
  }
}


class RouteQualityRating extends StatefulWidget {
  final double initialValue;

  const RouteQualityRating({Key key, this.initialValue}): super(key: key);

  @override
  RouteQualityRatingState createState() => RouteQualityRatingState();
}

class RouteQualityRatingState extends State<RouteQualityRating> {
  double _value;

  double get value => (_value == 0) ? null : _value;

  @override
  void initState() {
    super.initState();

    _value = (widget.initialValue == null) ? 0 : widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return decorateLogWidget(context, RatingBar(
      initialRating: _value,
      minRating: 0,
      itemCount: 3,
      ratingWidget: ratingStar(context),
      onRatingUpdate: (double value) => setState(() {
        _value = value;
      }),
    ));
  }
}


class RouteName extends StatefulWidget {
  const RouteName({Key key}) : super(key: key);

  @override
  RouteNameState createState() => RouteNameState();
}

class RouteNameState extends State<RouteName> {
  String _value;

  String get value => (_value == "") ? null : _value;

  @override
  Widget build(BuildContext context) {
    return decorateLogWidget(context, TextField(
      decoration: InputDecoration(
        labelText: "Give this route a witty name",
      ),
      maxLength: 64,
      textCapitalization: TextCapitalization.words,
      onChanged: (String value) {
        setState(() {
          _value = value;
        });
      },
    ));
  }
}
