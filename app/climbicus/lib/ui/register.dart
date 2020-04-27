
import 'package:climbicus/blocs/register_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  RegisterBloc _registerBloc;

  String _email;
  String _password;

  @override
  void initState() {
    super.initState();

    _registerBloc = BlocProvider.of<RegisterBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register"),
      ),
      body: BlocListener<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state is RegisterSuccess) {
            Navigator.pop(context);
          } else if (state is RegisterUserAlreadyExists) {
            final snackBar = SnackBar(
              backgroundColor: Colors.deepOrange,
              content: Text("Email already exists. Try again."),
            );
            Scaffold.of(context).showSnackBar(snackBar);
          }
        },
        child: BlocBuilder<RegisterBloc, RegisterState>(
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

  List<Widget> _buildSubmitButtons(RegisterState state) {
    return <Widget>[
      Builder(
        builder: (BuildContext context) => ListTile(
          title: RaisedButton(
            key: Key('register'),
            child: Text('Register'),
            onPressed: state is RegisterLoading ? null : () => validateAndRegister(context),
          ),
        ),
      ),
    ];
  }

  void validateAndRegister(BuildContext context) {
    final FormState form = formKey.currentState;
    if (!form.validate()) {
      return;
    }
    form.save();

    _registerBloc.add(RegisterButtonPressed(
      email: _email,
      password: _password,
    ));
  }
}