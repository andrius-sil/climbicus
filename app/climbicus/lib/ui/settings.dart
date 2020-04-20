import 'package:climbicus/blocs/gyms_bloc.dart';
import 'package:climbicus/blocs/settings_bloc.dart';
import 'package:climbicus/env.dart';
import 'package:climbicus/ui/gyms.dart';
import 'package:climbicus/utils/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info/package_info.dart';

class SettingsPage extends StatefulWidget {
  final Auth auth = Auth();

  final Environment env;
  final VoidCallback logoutCallback;

  SettingsPage({@required this.env, @required this.logoutCallback});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsBloc _settingsBloc;

  double displayPredictionsNum;

  @override
  void initState() {
    super.initState();

    _settingsBloc = BlocProvider.of<SettingsBloc>(context);

    displayPredictionsNum = _settingsBloc.displayPredictionsNum.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Container(child:
        BlocBuilder<SettingsBloc, SettingsState>(builder: (context, state) {
          return ListView(
            children: <Widget>[
              ListTile(
                title: _buildGymTitle(_settingsBloc.gymId),
                trailing: RaisedButton(
                  child: Text('Switch'),
                  onPressed: openGymsPage,
                ),
              ),
              ListTile(
                title: Text("Logged in as ${widget.auth.email}"),
                trailing: RaisedButton(
                  child: Text('Log Out'),
                  onPressed: logout,
                ),
              ),
              ListTile(
                title: Text("Version"),
                subtitle: Text(_versionString(state.packageInfo)),
              ),
            ] + _buildDevSettings(state.imagePicker)
          );
      })),
    );
  }

  Widget _buildGymTitle(int gymId) {
    return BlocBuilder<GymsBloc, GymsState>(
      builder: (context, state) {
        if (state is GymsLoaded) {
          return Text("Your gym: ${state.gyms[gymId].name}");
        }

        return Text("");
      }
    );
  }


  void openGymsPage() {
    // Close the drawer first.
    Navigator.pop(context);

    Navigator.push(context, MaterialPageRoute(
      builder: (BuildContext context) {
        return GymsPage();
      },
    ));
  }

  Future<void> logout() async {
    debugPrint("user logging out");

    await widget.auth.logout();
    widget.logoutCallback();

    Navigator.pop(context);
  }

  String _versionString(PackageInfo packageInfo) {
    String version = packageInfo.version;
    if (widget.env != Environment.dev) {
      return version;
    }

    return "$version (${packageInfo.buildNumber}) ${widget.env}";
  }

  List<Widget> _buildImagePickerSelection(String selectedImagePicker) {
    List<Widget> widgets = [
      ListTile(
        title: Text("Image Picker"),
      )
    ];
    IMAGE_PICKERS.forEach((sourceName, source) {
      widgets.add(
        RadioListTile(
          title: Text(sourceName),
          value: sourceName,
          groupValue: selectedImagePicker,
          onChanged: (String val) =>
              _settingsBloc.add(ImagePickerChanged(imagePicker: val))
        ),
      );
    });
    return widgets;
  }

  List<Widget> _buildDisplayPredictionsNumSelection() {
    return [
      ListTile(
        title: Text("Display number of predictions (${displayPredictionsNum.toInt()})")
      ),
      Slider(
        value: displayPredictionsNum,
        min: 1.0,
        max: 100.0,
        divisions: 99,
        label: "${displayPredictionsNum.toInt()}",
        onChanged: (double val) => setState(() {
          displayPredictionsNum = val;
        }),
        onChangeEnd: (double val) =>
          _settingsBloc.displayPredictionsNum = val.toInt(),
      ),
    ];
  }

  List<Widget> _buildDevSettings(String imagePicker) {
    if (widget.env != Environment.dev) {
      return [];
    }

    return _buildImagePickerSelection(imagePicker) +
        _buildDisplayPredictionsNumSelection();
  }
}
