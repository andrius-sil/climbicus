import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/blocs/route_predictions_bloc.dart';
import 'package:climbicus/constants.dart';
import 'package:climbicus/models/route_image.dart';
import 'package:climbicus/style.dart';
import 'package:climbicus/utils/route_grades.dart';
import 'package:climbicus/widgets/camera_custom.dart';
import 'package:climbicus/widgets/route_image_carousel.dart';
import 'package:climbicus/widgets/route_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddRoutePage extends StatefulWidget {
  final ImagePickerData imgPickerData;
  final String routeCategory;

  AddRoutePage({this.imgPickerData, this.routeCategory});

  @override
  State<StatefulWidget> createState() => _AddRoutePageState();
}

class _AddRoutePageState extends State<AddRoutePage> {
  static const NOT_SELECTED = "not selected";

  final checkboxSentKey = GlobalKey<CheckboxWithTitleState>();
  final numberAttemptsKey = GlobalKey<NumberAttemptsState>();
  final routeDifficultyKey = GlobalKey<RouteDifficultyRatingState>();
  final routeQualityKey = GlobalKey<RouteQualityRatingState>();
  final routeNameKey = GlobalKey<RouteNameState>();

  Map<int, RouteImage> _takenImages = {};

  GymRoutesBloc _gymRoutesBloc;
  RouteImagesBloc _routeImagesBloc;
  RoutePredictionBloc _routePredictionBloc;

  String _selectedCategory = NOT_SELECTED;
  String _selectedGrade = NOT_SELECTED;
  String _selectedGradeSystem = NOT_SELECTED;

  @override
  void initState() {
    super.initState();

    _selectedCategory = widget.routeCategory;
    _selectedGradeSystem = DEFAULT_GRADE_SYSTEM[widget.routeCategory];

    _gymRoutesBloc = BlocProvider.of<GymRoutesBloc>(context);
    _routeImagesBloc = BlocProvider.of<RouteImagesBloc>(context);
    _routePredictionBloc = BlocProvider.of<RoutePredictionBloc>(context);

    _routeImagesBloc.add(UpdateRouteImage(
      routeImageId: widget.imgPickerData.routeImage.id,
    ));
  }

  @override
  Widget build(BuildContext context) {
    var appBar = AppBar(
      title: const Text('Add new route'),
    );

    return Scaffold(
      appBar: appBar,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: availableHeight(context, appBar)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Text("Your route:"),
                  SizedBox(height: COLUMN_PADDING),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: BlocBuilder<RoutePredictionBloc, RoutePredictionState>(
                          builder: (context, state) {
                            if (state is RoutePredictionLoaded) {
                              var routeImage = state.imgPickerData.routeImage;
                              _takenImages[routeImage.id] = routeImage;
                              return RouteImageCarousel(images: _takenImages);
                            } else if (state is RoutePredictionError) {
                              return ErrorWidget.builder(state.errorDetails);
                            }

                            return Center(child: CircularProgressIndicator());
                          },
                        ),
                      ),
                      _buildImagePicker(),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child:  _buildSelectCategory()),
                  Expanded(child: _buildSelectGrade()),
                ],
              ),
              Row(
                children: [
                  Expanded(child: CheckboxSent(key: checkboxSentKey)),
                  Expanded(child: NumberAttempts(key: numberAttemptsKey)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: RouteDifficultyRating(key: routeDifficultyKey)),
                  Expanded(child: RouteQualityRating(key: routeQualityKey)),
                ],
              ),
              Container(
                child: RouteName(key: routeNameKey),
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
      ),
    );
  }

  TextStyle _dropdownValueStyle(String value) {
    return TextStyle(
      fontSize: headingSize5or6(context),
      color: (value == NOT_SELECTED) ? Theme.of(context).accentColor : textColor,
      fontStyle: (value == NOT_SELECTED) ? FontStyle.italic : FontStyle.normal,
    );
  }

  Widget _buildSelectGrade() {
    var systemGrades = _systemGrades();
    if (!systemGrades.contains(_selectedGrade)) {
      // Reset selected grade in case category changed.
      _selectedGrade = NOT_SELECTED;
    }

    return decorateLogWidget(context, Column(
      children: <Widget>[
        Text("Select grade", style: TextStyle(fontSize: headingSize5or6(context))),
        DropdownButton<String>(
          value: _selectedGrade,
          items: ([NOT_SELECTED] + _systemGrades())
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: _dropdownValueStyle(value)),
            );
          }).toList(),
          onChanged: (String value) {
            setState(() {
              _selectedGrade = value;
            });
          },
        ),
      ],
    ));
  }

  Widget _buildSelectCategory() {
    return decorateLogWidget(context, Column(
      children: <Widget>[
        Text("Select category", style: TextStyle(fontSize: headingSize5or6(context))),
        DropdownButton<String>(
          value: _selectedCategory,
          items: <String>[
            NOT_SELECTED,
            SPORT_CATEGORY,
            BOULDERING_CATEGORY,
          ].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: _dropdownValueStyle(value)),
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
    ));
  }

  Widget _buildImagePicker() {
    return IconButton(
      icon: const Icon(Icons.add_a_photo),
      onPressed: () async {
        final imageFile = await Navigator.push(context, MaterialPageRoute(
          builder: (BuildContext context) {
            return CameraCustom();
          },
        ));
        if (imageFile == null) {
          return;
        }

        _routePredictionBloc.add(FetchRoutePrediction(
          image: imageFile,
          routeCategory: widget.routeCategory,
        ));
      },
      iconSize: 48,
    );
  }

  List<String> _systemGrades() {
    if (_selectedCategory == NOT_SELECTED) {
      return [];
    }

    return GRADE_SYSTEMS[_selectedGradeSystem];
  }

  void uploadAndNavigateBack() {
    _gymRoutesBloc.add(AddNewGymRouteWithUserLog(
      category: _selectedCategory,
      grade: "${_selectedGradeSystem}_$_selectedGrade",
      name: routeNameKey.currentState.value,
      completed: checkboxSentKey.currentState.value,
      numAttempts: numberAttemptsKey.currentState.value,
      routeImages: _takenImages.values.toList(),
      userRouteVotesData: UserRouteVotesData(
        routeQualityKey.currentState.value,
        routeDifficultyKey.currentState.value,
      ),
    ));

    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
