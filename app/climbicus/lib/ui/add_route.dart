
import 'package:climbicus/blocs/gym_route_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddRoutePage extends StatefulWidget {
  final Image takenImage;

  AddRoutePage({this.takenImage});

  @override
  State<StatefulWidget> createState() => _AddRoutePageState();
}

class _AddRoutePageState extends State<AddRoutePage> {
  static const NOT_SELECTED = "not selected";

  GymRouteBloc _gymRouteBloc;
  String _selectedGrade = NOT_SELECTED;

  @override
  void initState() {
    super.initState();

    _gymRouteBloc = BlocProvider.of<GymRouteBloc>(context);
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
            child: widget.takenImage,
          ),
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
          RaisedButton(
            child: Text('Add'),
            onPressed: (_selectedGrade == NOT_SELECTED) ? null : uploadAndNavigateBack,
          ),
        ]),
      ),
    );
  }

  Future<void> uploadAndNavigateBack() async {
    _gymRouteBloc.add(AppendGymRoute(
      grade: _selectedGrade,
    ));

    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
