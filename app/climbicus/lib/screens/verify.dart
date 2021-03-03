import 'package:climbicus/blocs/authentication_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class VerifyPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  AuthenticationBloc _authenticationBloc;

  @override
  void initState() {
    super.initState();

    _authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Waiting on approval", style: TextStyle(fontSize: 20.0)),
                  SizedBox(height: 10.0),
                  RaisedButton(
                    child: Text('Refresh'),
                    onPressed: refresh,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlineButton(
              child: Text('Log Out'),
              onPressed: logout,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> refresh() async {
    _authenticationBloc.add(AppStarted());
  }

  Future<void> logout() async {
    debugPrint("user logging out");
    _authenticationBloc.add(LoggedOut());
  }
}
