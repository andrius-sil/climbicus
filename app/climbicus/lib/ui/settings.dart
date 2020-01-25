
import 'package:climbicus/utils/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SettingsPage extends StatefulWidget {
  final Auth auth;
  final VoidCallback logoutCallback;

  const SettingsPage({this.auth, this.logoutCallback});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Container(
        child: Form(
          key: formKey,
          child: new ListView(
            children: <Widget>[
              RaisedButton(
                // TODO: display email
                child: Text('Log Out'),
                onPressed: logout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> logout() async {
    await widget.auth.logout();
    widget.logoutCallback();

    Navigator.pop(context);
  }
}
