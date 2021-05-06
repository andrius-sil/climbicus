
import 'package:bloc/bloc.dart';
import 'package:climbicus/blocs/authentication_bloc.dart';
import 'package:climbicus/repositories/api_repository.dart';
import 'package:climbicus/repositories/user_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

abstract class RegisterEvent {
  const RegisterEvent();
}

class RegisterButtonPressed extends RegisterEvent {
  final String name;
  final String email;
  final String password;

  const RegisterButtonPressed({
    required this.name,
    required this.email,
    required this.password,
  });
}


abstract class RegisterState {}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {}

class RegisterUserAlreadyExists extends RegisterState {}

class RegisterError extends RegisterState {
  FlutterErrorDetails errorDetails;

  RegisterError({required Object exception, StackTrace? stackTrace}):
        errorDetails = FlutterErrorDetails(exception: exception, stack: stackTrace) {
    FlutterError.reportError(errorDetails);
  }
}


class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final getIt = GetIt.instance;

  final AuthenticationBloc authenticationBloc;

  RegisterBloc({required this.authenticationBloc}) : super(RegisterInitial());

  @override
  Stream<RegisterState> mapEventToState(RegisterEvent event) async* {
    if (event is RegisterButtonPressed) {
      yield RegisterLoading();

      try {
        await getIt<UserRepository>().register(
          name: event.name,
          email: event.email,
          password: event.password,
        );

        final userAuth = await getIt<UserRepository>().authenticate(
          email: event.email,
          password: event.password,
        );

        authenticationBloc.add(LoggedIn(
          email: event.email,
          userAuth: userAuth,
        ));

        yield RegisterSuccess();
      } on ConflictingResourceApiException {
        yield RegisterUserAlreadyExists();
      } catch (e, st) {
        yield RegisterError(exception: e, stackTrace: st);
      }
    }
  }

}