
import 'package:climbicus/style.dart';
import 'package:climbicus/utils/route_grades.dart';
import 'package:flutter/material.dart';

class CheckboxSent extends CheckboxWithTitle {
  const CheckboxSent({Key key}) : super(key: key, title: "SENT!");
}

class CheckboxWithTitle extends StatefulWidget {
  final String title;
  final bool titleAbove;

  const CheckboxWithTitle({Key key, this.title, this.titleAbove = true}) : super(key: key);

  @override
  CheckboxWithTitleState createState() => CheckboxWithTitleState();
}

class CheckboxWithTitleState extends State<CheckboxWithTitle> {
  bool _value = false;

  bool get value => _value;

  @override
  Widget build(BuildContext context) {
    var checkbox = Checkbox(
      value: _value,
      onChanged: (bool value) {
        setState(() {
          _value = value;
        });
      },
    );

    if (widget.titleAbove) {
      return Column(
        children: <Widget>[
          Text(widget.title),
          checkbox,
        ],
      );
    }

    return Row(
      children: <Widget>[
        checkbox,
        Text(widget.title),
      ],
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
    "--" :
    "${_value.toInt()}";
  }
}


class SliderRouteGrades extends StatefulWidget {
  final String routeCategory;
  final List<String> gradeSystem;

  SliderRouteGrades({Key key, this.routeCategory}) :
    gradeSystem = GRADE_SYSTEMS[DEFAULT_GRADE_SYSTEM[routeCategory]],
    super(key: key);

  @override
  SliderRouteGradesState createState() => SliderRouteGradesState();
}

class SliderRouteGradesState extends State<SliderRouteGrades> {
  RangeValues _values;

  RangeValues get values => _values;

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
