
import 'package:climbicus/utils/auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  final Auth auth;
  final VoidCallback loginCallback;

  const LoginPage({this.auth, this.loginCallback});

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String _email;
  String _password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Form(
          key: formKey,
          child: new ListView(
            children: buildInputs() + buildSubmitButtons(),
          ),
        ),
      ),
    );
  }

  List<Widget> buildInputs() {
    return <Widget>[
      TextFormField(
        key: Key('email'),
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(labelText: 'Email'),
        validator: (value) => value.isEmpty ? "Email can't be empty": null,
        onSaved: (value) => _email = value,
      ),
      TextFormField(
        key: Key('password'),
        obscureText: true,
        decoration: InputDecoration(labelText: 'Password'),
        validator: (value) => value.isEmpty ? "Password can't be empty": null,
        onSaved: (value) => _password = value,
      ),
    ];
  }

  List<Widget> buildSubmitButtons() {
    return <Widget>[
      RaisedButton(
        key: Key('logIn'),
        child: Text('Log in'),
        onPressed: validateAndLogin,
      )
    ];
  }

  Future<void> validateAndLogin() async {
    final FormState form = formKey.currentState;
    if (!form.validate()) {
      return;
    }

    form.save();

    try {
      widget.auth.login(_email, _password);
    } catch (e) {
      print('Error: $e');
    }

    widget.loginCallback();
  }
}
