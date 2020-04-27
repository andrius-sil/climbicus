import 'package:climbicus/blocs/login_bloc.dart';
import 'package:climbicus/ui/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  LoginBloc _loginBloc;

  String _email;
  String _password;

  @override
  void initState() {
    super.initState();

    _loginBloc = BlocProvider.of<LoginBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
      ),
      body: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          var errorMsg = null;
          if (state is LoginError) {
            errorMsg = "Ooops.. an error has occured";
          } else if (state is LoginUnauthorized) {
            errorMsg = "Incorrect email and password. Please try again.";
          }
          if (errorMsg != null) {
            final snackBar = SnackBar(
              backgroundColor: Colors.deepOrange,
              content: Text(errorMsg),
            );
            Scaffold.of(context).showSnackBar(snackBar);
          }
        },
        child: BlocBuilder<LoginBloc, LoginState>(
          builder: (context, state) {
            return Container(
              child: Form(
                key: formKey,
                child: ListView(
                  children: _buildInputs() + _buildSubmitButtons(state),
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  List<Widget> _buildInputs() {
    return <Widget>[
      ListTile(
        title: TextFormField(
          key: Key('email'),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: 'Email'),
          validator: (value) => value.isEmpty ? "Email can't be empty" : null,
          onSaved: (value) => _email = value,
        ),
      ),
      ListTile(
        title: TextFormField(
          key: Key('password'),
          obscureText: true,
          decoration: InputDecoration(labelText: 'Password'),
          validator: (value) => value.isEmpty ? "Password can't be empty" : null,
          onSaved: (value) => _password = value,
        ),
      ),
    ];
  }

  List<Widget> _buildSubmitButtons(LoginState state) {
    return <Widget>[
      Builder(
        builder: (BuildContext context) => ListTile(
          title: RaisedButton(
            key: Key('logIn'),
            child: Text('Log in'),
            onPressed: state is LoginLoading ? null : () => validateAndLogin(context),
          ),
        ),
      ),
      ListTile(
        title: Row(
          children: <Widget>[
            Text("New user?"),
            FlatButton(
              textColor: Colors.blue,
              child: Text(
                "Register",
                style: TextStyle(fontSize: 18),
              ),
              onPressed: navigateRegister,
            ),
          ],
          mainAxisAlignment: MainAxisAlignment.center,
        ),
      ),
    ];
  }

  void validateAndLogin(BuildContext context) {
    final FormState form = formKey.currentState;
    if (!form.validate()) {
      return;
    }
    form.save();

    _loginBloc.add(LoginButtonPressed(
      email: _email,
      password: _password,
    ));
  }

  void navigateRegister() {
    Navigator.push(context, MaterialPageRoute(
      builder: (BuildContext context) {
        return RegisterPage();
      },
    ));
  }
}
