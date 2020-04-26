
import 'package:bloc/bloc.dart';
import 'package:climbicus/blocs/authentication_bloc.dart';
import 'package:climbicus/repositories/api_repository.dart';
import 'package:climbicus/repositories/user_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

abstract class LoginEvent {
  const LoginEvent();
}

class LoginButtonPressed extends LoginEvent {
  final String email;
  final String password;

  const LoginButtonPressed({@required this.email, @required this.password});
}


abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginUnauthorized extends LoginState {}

class LoginError extends LoginState {
  FlutterErrorDetails errorDetails;

  LoginError({Object exception, StackTrace stackTrace}):
        errorDetails = FlutterErrorDetails(exception: exception, stack: stackTrace) {
    FlutterError.dumpErrorToConsole(errorDetails);
  }
}


class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final getIt = GetIt.instance;

  final AuthenticationBloc authenticationBloc;

  LoginBloc({@required this.authenticationBloc});

  @override
  LoginState get initialState => LoginInitial();

  @override
  Stream<LoginState> mapEventToState(LoginEvent event) async* {
    if (event is LoginButtonPressed) {
      yield LoginLoading();

      try {
        final userAuth = await getIt<UserRepository>().authenticate(
          email: event.email,
          password: event.password,
        );

        authenticationBloc.add(LoggedIn(
          email: event.email,
          userAuth: userAuth,
        ));

        yield LoginInitial();
      } on UnauthorizedApiException {
        yield LoginUnauthorized();
      } catch (e, st) {
        yield LoginError(exception: e, stackTrace: st);
      }
    }
  }

}