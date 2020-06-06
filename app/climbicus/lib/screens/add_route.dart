import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/blocs/route_predictions_bloc.dart';
import 'package:climbicus/style.dart';
import 'package:climbicus/utils/route_grades.dart';
import 'package:climbicus/widgets/route_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddRoutePage extends StatefulWidget {
  final ImagePickerData imgPickerData;

  AddRoutePage({this.imgPickerData});

  @override
  State<StatefulWidget> createState() => _AddRoutePageState();
}

class _AddRoutePageState extends State<AddRoutePage> {
  static const NOT_SELECTED = "not selected";

  final checkboxSentKey = new GlobalKey<CheckboxSentState>();
  final sliderAttemptsKey = new GlobalKey<SliderAttemptsState>();

  Image _takenImage;

  GymRoutesBloc _gymRoutesBloc;
  RouteImagesBloc _routeImagesBloc;

  String _selectedCategory = NOT_SELECTED;
  String _selectedGrade = NOT_SELECTED;
  String _selectedGradeSystem = NOT_SELECTED;

  @override
  void initState() {
    super.initState();

    _takenImage = Image.file(widget.imgPickerData.image);
    _gymRoutesBloc = BlocProvider.of<GymRoutesBloc>(context);
    _routeImagesBloc = BlocProvider.of<RouteImagesBloc>(context);

    _routeImagesBloc.add(UpdateRouteImage(
      routeImageId: widget.imgPickerData.routeImage.id,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add new route'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Column(
              children: <Widget>[
                Text("Your image:"),
                SizedBox(height: COLUMN_PADDING),
                Container(
                  height: 200.0,
                  width: 200.0,
                  child: _takenImage,
                ),
              ],
            ),
            Column(
              children: <Widget>[
                _buildSelectCategory(),
                _buildSelectGrade(),
                CheckboxSent(key: checkboxSentKey),
                SliderAttempts(key: sliderAttemptsKey),
              ],
            ),
            RaisedButton(
              child: Text('Add'),
              onPressed: (_selectedCategory == NOT_SELECTED ||
                          _selectedGrade == NOT_SELECTED) ?
                null :
                uploadAndNavigateBack,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectGrade() {
    return Column(
      children: <Widget>[
        Text("Select grade"),
        DropdownButton<String>(
          value: _selectedGrade,
          items: ([NOT_SELECTED] + _gradeSystems())
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String value) {
            setState(() {
              _selectedGrade = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSelectCategory() {
    return Column(
      children: <Widget>[
        Text("Select category"),
        DropdownButton<String>(
          value: _selectedCategory,
          items: <String>[
            NOT_SELECTED,
            "sport",
            "bouldering",
          ].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String value) {
            setState(() {
              _selectedCategory = value;
              _selectedGradeSystem = DEFAULT_GRADE_SYSTEM[value];
            });
          },
        ),
      ],
    );
  }

  List<String> _gradeSystems() {
    if (_selectedCategory == NOT_SELECTED) {
      return [];
    }

    return GRADE_SYSTEMS[_selectedGradeSystem];
  }

  void uploadAndNavigateBack() {
    _gymRoutesBloc.add(AddNewGymRouteWithUserLog(
      category: _selectedCategory,
      grade: "${_selectedGradeSystem}_$_selectedGrade",
      completed: checkboxSentKey.currentState.value,
      numAttempts: sliderAttemptsKey.currentState.value,
      routeImage: widget.imgPickerData.routeImage,
    ));

    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
