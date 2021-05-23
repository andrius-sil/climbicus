
import 'package:bloc/bloc.dart';
import 'package:climbicus/repositories/api_repository.dart';
import 'package:climbicus/repositories/user_repository.dart';
import 'package:get_it/get_it.dart';

abstract class AuthenticationEvent {
  const AuthenticationEvent();
}

class AppStarted extends AuthenticationEvent {}

class LoggedIn extends AuthenticationEvent {
  final String email;
  final Map userAuth;

  const LoggedIn({required this.email, required this.userAuth});
}

class LoggedOut extends AuthenticationEvent {}


abstract class AuthenticationState {}

class AuthenticationUninitialized extends AuthenticationState {}

class AuthenticationAuthenticated extends AuthenticationState {}

class AuthenticationUnauthenticated extends AuthenticationState {}

class AuthenticationUnverified extends AuthenticationState {}

class AuthenticationLoading extends AuthenticationState {}

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  final getIt = GetIt.instance;

  AuthenticationBloc() : super(AuthenticationUninitialized()) {
    add(AppStarted());
  }

  @override
  Stream<AuthenticationState> mapEventToState(AuthenticationEvent event) async* {
    if (event is AppStarted) {
      final hasAuthenticated = await getIt<UserRepository>().hasAuthenticated();
      if (hasAuthenticated) {
        // Verify that auth token is still valid upon logging back in.
        // If not, clear auth details and go back to log in page.
        try {
          await getIt<ApiRepository>().fetchGyms();
        } on SignatureVerificationApiException {
          add(LoggedOut());
          return;
        }

        yield AuthenticationAuthenticated();
      } else {
        yield AuthenticationUnauthenticated();
      }
    } else if (event is LoggedIn) {
      yield AuthenticationLoading();

      await getIt<UserRepository>().persistAuth(
        email: event.email,
        userAuth: event.userAuth,
      );

      yield AuthenticationAuthenticated();
    } else if (event is LoggedOut) {
      yield AuthenticationLoading();

      await getIt<UserRepository>().deauthenticate();

      yield AuthenticationUnauthenticated();
    }
  }

}