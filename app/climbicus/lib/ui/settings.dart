
import 'package:climbicus/utils/auth.dart';
import 'package:climbicus/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';


class SettingsPage extends StatefulWidget {
  final Auth auth = Auth();
  final Settings settings = Settings();
  final VoidCallback logoutCallback;

  SettingsPage({this.logoutCallback});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double displayPredictionsNum;

  @override
  void initState() {
    super.initState();

    displayPredictionsNum = widget.settings.displayPredictionsNum.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            Text("${widget.auth.email}"),
            RaisedButton(
              child: Text('Log Out'),
              onPressed: logout,
            ),
            Text("Dev settings:"),
          ] +
          _buildServerSelection() + _buildImagePickerSelection() + _buildDisplayPredictionsNumSelection(),
        ),
      ),
    );
  }

  Future<void> logout() async {
    debugPrint("user logging out");

    await widget.auth.logout();
    widget.logoutCallback();

    Navigator.pop(context);
  }

  List<Widget> _buildServerSelection() {
    List<Widget> widgets = [
      Text("Server"),
    ];
    Settings.serverUrls.forEach((server, serverUrl) {
      widgets.add(
        RadioListTile(
          title: Text(server),
          value: server,
          groupValue: widget.settings.server,
          onChanged: (String val) =>
              setState(() => widget.settings.server = val),
        ),
      );
    });
    return widgets;
  }

  List<Widget> _buildImagePickerSelection() {
    List<Widget> widgets = [
      Text("Image Picker"),
    ];
    Settings.imagePickers.forEach((sourceName, source) {
      widgets.add(
        RadioListTile(
          title: Text(sourceName),
          value: sourceName,
          groupValue: widget.settings.imagePicker,
          onChanged: (String val) =>
              setState(() => widget.settings.imagePicker = val),
        ),
      );
    });
    return widgets;
  }

  List<Widget> _buildDisplayPredictionsNumSelection() {
    return [
      Text("Display number of predictions (${displayPredictionsNum.toInt()})"),
      Slider(
        value: displayPredictionsNum,
        min: 1.0,
        max: 100.0,
        divisions: 99,
        label: "${displayPredictionsNum.toInt()}",
        onChanged: (double val) => setState(() {
          displayPredictionsNum = val;
        }),
        onChangeEnd: (double val) {
          widget.settings.displayPredictionsNum = val.toInt();
        },
      ),
    ];
  }
}
