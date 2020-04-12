import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/blocs/route_predictions_bloc.dart';
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

  Image _takenImage;

  GymRoutesBloc _gymRoutesBloc;
  RouteImagesBloc _routeImagesBloc;

  String _selectedCategory = NOT_SELECTED;
  String _selectedGrade = NOT_SELECTED;
  String _selectedStatus = NOT_SELECTED;

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
        title: const Text('Add a route'),
      ),
      body: Center(
        child: Column(children: <Widget>[
          Text("Your photo:"),
          Container(
            height: 200.0,
            width: 200.0,
            child: _takenImage,
          ),
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
              });
            },
          ),
          Text("Select grade"),
          DropdownButton<String>(
            value: _selectedGrade,
            items: <String>[
              NOT_SELECTED,
              "6a",
              "7a",
              "8a",
            ].map<DropdownMenuItem<String>>((String value) {
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
          Text("Select status"),
          DropdownButton<String>(
            value: _selectedStatus,
            items: <String>[
              NOT_SELECTED,
              "flash",
              "red-point",
              "did not finish"
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String value) {
              setState(() {
                _selectedStatus = value;
              });
            },
          ),
          RaisedButton(
            child: Text('Add'),
            onPressed: (_selectedCategory == NOT_SELECTED ||
                        _selectedGrade == NOT_SELECTED ||
                        _selectedStatus == NOT_SELECTED) ?
              null :
              uploadAndNavigateBack,
          ),
        ]),
      ),
    );
  }

  void uploadAndNavigateBack() {
    _gymRoutesBloc.add(AddNewGymRouteWithUserLog(
      category: _selectedCategory,
      grade: _selectedGrade,
      status: _selectedStatus,
      routeImage: widget.imgPickerData.routeImage,
    ));

    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
