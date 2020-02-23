import 'package:climbicus/utils/api.dart';
import 'package:climbicus/utils/auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  final Auth auth = Auth();
  final VoidCallback loginCallback;
  final AppBar appBar;

  LoginPage({this.appBar, this.loginCallback});

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
      appBar: widget.appBar,
      body: Container(
        child: Form(
          key: formKey,
          child: ListView(
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
        validator: (value) => value.isEmpty ? "Email can't be empty" : null,
        onSaved: (value) => _email = value,
      ),
      TextFormField(
        key: Key('password'),
        obscureText: true,
        decoration: InputDecoration(labelText: 'Password'),
        validator: (value) => value.isEmpty ? "Password can't be empty" : null,
        onSaved: (value) => _password = value,
      ),
    ];
  }

  List<Widget> buildSubmitButtons() {
    return <Widget>[
      Builder(
          builder: (BuildContext context) => RaisedButton(
                key: Key('logIn'),
                child: Text('Log in'),
                onPressed: () => validateAndLogin(context),
              ))
    ];
  }

  Future<void> validateAndLogin(BuildContext context) async {
    final FormState form = formKey.currentState;
    if (!form.validate()) {
      return;
    }

    form.save();

    var errorMsg;

    try {
      await widget.auth.login(_email, _password);
      widget.loginCallback();
    } on UnauthorizedApiException {
      errorMsg = "Incorrect email and password. Please try again.";
    } on Exception {
      errorMsg = "Ooops.. an error has occured";
    }

    if (errorMsg != null) {
      final snackBar = SnackBar(
        backgroundColor: Colors.deepOrange,
        content: Text(errorMsg),
      );
      Scaffold.of(context).showSnackBar(snackBar);
    }
  }
}
