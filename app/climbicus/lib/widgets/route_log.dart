
import 'package:climbicus/constants.dart';
import 'package:climbicus/models/area.dart';
import 'package:climbicus/style.dart';
import 'package:climbicus/utils/route_grades.dart';
import 'package:climbicus/widgets/rating_star.dart';
import 'package:climbicus/widgets/route_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_touch_spin/flutter_touch_spin.dart';
import 'package:select_dialog/select_dialog.dart';
import 'package:toggle_switch/toggle_switch.dart';


const NOT_SELECTED = "not selected";
const NOT_SELECTED_AREA = 0;


Widget decorateLogWidget(BuildContext context, Widget logWidget,
    {double? height = 80.0, double padding = 4.0}) {
  return Container(
    padding: EdgeInsets.all(padding),
    margin: const EdgeInsets.all(4),
    height: height,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: primaryColorLight,
      borderRadius: BorderRadius.circular(6),
    ),
    child: logWidget,
  );
}


TextStyle dropdownValueStyle(String value, BuildContext context) {
  return TextStyle(
    fontSize: headingSize5or6(context),
    color: (value == NOT_SELECTED) ? Theme.of(context).accentColor : textColor,
    fontStyle: (value == NOT_SELECTED) ? FontStyle.italic : FontStyle.normal,
  );
}


class CheckboxSent extends CheckboxWithTitle {
  const CheckboxSent({required Key key}) : super(key: key, title: "Sent?");
}

class CheckboxWithTitle extends StatefulWidget {
  final String title;
  final VoidCallback? onTicked;
  final bool titleAbove;

  const CheckboxWithTitle({required Key key, required this.title, this.onTicked, this.titleAbove = true}) : super(key: key);

  @override
  CheckboxWithTitleState createState() => CheckboxWithTitleState();
}

class CheckboxWithTitleState extends State<CheckboxWithTitle> {
  bool _value;

  bool get value => _value;

  bool _initialValue() => false;

  void resetState() {
    setState(() {
      _value = _initialValue();
    });
  }

  @override
  void initState() {
    super.initState();
    _value = _initialValue();
  }

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
              widget.onTicked!();
            }
          });
        } as void Function(bool?)?,
      ),
    );

    var titledCheckbox;
    if (widget.titleAbove) {
      titledCheckbox = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(widget.title, style: TextStyle(fontSize: headingSize5or6(context))),
          checkbox,
        ],
      );
    } else {
      titledCheckbox = Row(
        children: <Widget>[
          checkbox,
          Text(widget.title, style: TextStyle(fontSize: headingSize5or6(context))),
        ],
      );
    }

    return decorateLogWidget(context, titledCheckbox);
  }
}


class NumberAttempts extends StatefulWidget {
  const NumberAttempts({required Key/*!*/ key}) : super(key: key);

  @override
  NumberAttemptsState createState() => NumberAttemptsState();
}

class NumberAttemptsState extends State<NumberAttempts> {
  var _touchSpinKey = UniqueKey();

  int _value;

  int? get value => (_value == 0) ? null : _value;

  int _initialValue() => 0;

  void resetState() {
    setState(() {
      _value = _initialValue();
      _touchSpinKey = UniqueKey();
    });
  }

  @override
  void initState() {
    super.initState();
    _value = _initialValue();
  }

  @override
  Widget build(BuildContext context) {
    return decorateLogWidget(
      context,
      Column(
        children: <Widget>[
          Text("Attempts?", style: TextStyle(fontSize: headingSize5or6(context))),
          Container(
            child: TouchSpin(
              key: _touchSpinKey,
              value: _value,
              min: 0,
              max: 30,
              step: 1,
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
  const SliderAttempts({required Key key}) : super(key: key);

  @override
  SliderAttemptsState createState() => SliderAttemptsState();
}

class SliderAttemptsState extends State<SliderAttempts> {
  double? _value;

  int? get value => (_value == null) ? null : _value!.toInt();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text("How many attempts?\t${_numAttemptsLabel()}"),
        Slider(
          value: (_value == null) ? 0.0 : _value!,
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
    "${_value!.toInt()}";
  }
}


class SliderRouteGrades extends StatefulWidget {
  final String routeCategory;
  final List<String> gradeSystem;
  final VoidCallback onChangeEnd;

  SliderRouteGrades({required Key key, required this.routeCategory, required this.onChangeEnd}) :
    gradeSystem = GRADE_SYSTEMS[DEFAULT_GRADE_SYSTEM[routeCategory]!]!,
    super(key: key);

  @override
  SliderRouteGradesState createState() => SliderRouteGradesState();
}

class SliderRouteGradesState extends State<SliderRouteGrades> {
  late RangeValues _values;

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
  final String? initialValue;

  const RouteDifficultyRating({required Key key, this.initialValue}) : super(key: key);

  @override
  RouteDifficultyRatingState createState() => RouteDifficultyRatingState();
}

class RouteDifficultyRatingState extends State<RouteDifficultyRating> {
  final _labels = [DIFFICULTY_NAME_SOFT, DIFFICULTY_NAME_FAIR, DIFFICULTY_NAME_HARD];
  final _values = [DIFFICULTY_SOFT, DIFFICULTY_FAIR, DIFFICULTY_HARD];

  int _index;

  String? get value => (_index == -1) ? null : _values[_index];

  int _initialValue() => (widget.initialValue == null) ? -1 : _values.indexOf(widget.initialValue);

  void resetState() {
    setState(() {
      _index = _initialValue();
    });
  }

  @override
  void initState() {
    super.initState();

    _index = _initialValue();
  }

  @override
  Widget build(BuildContext context) {
    return decorateLogWidget(context, ToggleSwitch(
      activeBgColor: Theme.of(context).accentColor,
      inactiveBgColor: primaryColorLight,
      cornerRadius: 0.0,
      initialLabelIndex: _index,
      labels: _labels,
      onToggle: (index) => _index = index,
      minWidth: _minWidth(context),
      fontSize: headingSize5or6(context),
    ));
  }

  double _minWidth(BuildContext context) {
    double halfScreenWidth = MediaQuery.of(context).size.width / 2;
    return halfScreenWidth / _labels.length * 0.88;
  }

}


class RouteQualityRating extends StatefulWidget {
  final double? initialValue;

  const RouteQualityRating({required Key key, this.initialValue}): super(key: key);

  @override
  RouteQualityRatingState createState() => RouteQualityRatingState();
}

class RouteQualityRatingState extends State<RouteQualityRating> {
  double _value;

  double? get value => (_value == 0) ? null : _value;

  double _initialValue() => (widget.initialValue == null) ? 0 : widget.initialValue!;

  void resetState() {
    setState(() {
      _value = _initialValue();
    });
  }

  @override
  void initState() {
    super.initState();

    _value = _initialValue();
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
  const RouteName({required Key key}) : super(key: key);

  @override
  RouteNameState createState() => RouteNameState();
}

class RouteNameState extends State<RouteName> {
  String _value;

  String? get value => (_value == "") ? null : _value;

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


class DropdownArea extends StatefulWidget {
  final Map<int, Area> areas;
  final void Function(Area) onChangeCallback;

  const DropdownArea({required this.areas, required this.onChangeCallback});

  @override
  DropdownAreaState createState() => DropdownAreaState();
}


class DropdownAreaState extends State<DropdownArea> {
  static Area notSelectedValue = Area(NOT_SELECTED_AREA, 0, 0, NOT_SELECTED, "", "", DateTime.now());
  Area _value = notSelectedValue;

  @override
  Widget build(BuildContext context) {
    return decorateLogWidget(context, Column(
      children: <Widget>[
        Text("Select area", style: TextStyle(fontSize: headingSize5or6(context))),
        _buildButton(),
      ],
    ));
  }

  Widget _buildButton() {
    return Stack(
      children: [
        FlatButton(
          padding: const EdgeInsets.all(0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_value.name, style: dropdownValueStyle(_value.name, context)),
              Icon(Icons.unfold_more_outlined),
            ],
          ),
          onPressed: _openDialog,
        ),
        // Copied from lib/src/material/dropdown.dart
        Positioned(
          left: 0.0,
          right: 0.0,
          bottom: 8.0,
          child: Container(
            height: 1.0,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFBDBDBD),
                  width: 0.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openDialog() {
    SelectDialog.showModal<Area>(
      context,
      showSearchBox: false,
      label: "Select area",
      selectedValue: _value,
      items: widget.areas.values.toList(),
      itemBuilder: (BuildContext context, Area area, bool isSelected) {
        return _buildArea(area);
      },
      onChange: (Area value) {
        widget.onChangeCallback(value);
        setState(() {
          _value = value;
        });
      },
    );
  }

  Widget _buildArea(Area area) {
    var name = Text(area.name);
    if (area.id == NOT_SELECTED_AREA) {
      return name;
    }

    bool isLast = widget.areas.values.last == area;

    var borderSide = BorderSide(
      color: accentColor!,
      width: 2.0,
    );

    return Container(
      height: 100.0,
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        border: Border(
          top: borderSide,
          bottom: isLast ? borderSide : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: RouteImageWidget.fromPath(area.thumbnailImagePath, boxFit: BoxFit.contain),
          ),
          Expanded(
            flex: 1,
            child: Center(child: name),
          ),
        ],
      ),
    );
  }
}
