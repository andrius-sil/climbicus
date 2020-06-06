
import 'package:flutter/material.dart';

class CheckboxSent extends StatefulWidget {
  const CheckboxSent({Key key}) : super(key: key);

  @override
  CheckboxSentState createState() => CheckboxSentState();
}

class CheckboxSentState extends State<CheckboxSent> {
  bool _value = false;

  bool get value => _value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text("SENT!"),
        Checkbox(
          value: _value,
          onChanged: (bool value) {
            setState(() {
              _value = value;
            });
          },
        ),
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
