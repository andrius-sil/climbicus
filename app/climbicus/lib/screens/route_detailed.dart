import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/blocs/user_route_log_bloc.dart';
import 'package:climbicus/blocs/users_bloc.dart';
import 'package:climbicus/models/user.dart';
import 'package:climbicus/models/user_route_log.dart';
import 'package:climbicus/repositories/user_repository.dart';
import 'package:climbicus/utils/time.dart';
import 'package:climbicus/widgets/rating_star.dart';
import 'package:climbicus/widgets/route_image_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../style.dart';

class RouteDetailedPage extends StatefulWidget {
  final getIt = GetIt.instance;

  final RouteWithUserMeta routeWithUserMeta;

  RouteDetailedPage({@required this.routeWithUserMeta});

  @override
  State<StatefulWidget> createState() => _RouteDetailedPage();
}

class _RouteDetailedPage extends State<RouteDetailedPage> {
  RouteImagesBloc _routeImagesBloc;
  UserRouteLogBloc _userRouteLogBloc;

  @override
  void initState() {
    super.initState();

    _routeImagesBloc = BlocProvider.of<RouteImagesBloc>(context);
    _routeImagesBloc.add(FetchRouteImagesAll(routeId: widget.routeWithUserMeta.route.id));

    _userRouteLogBloc = BlocProvider.of<UserRouteLogBloc>(context);
    _userRouteLogBloc.add(FetchUserRouteLog(routeId: widget.routeWithUserMeta.route.id));
  }

  @override
  Widget build(BuildContext context) {
    var routeTitleName = widget.routeWithUserMeta.route.name ??
        '${widget.routeWithUserMeta.route.grade} route';

    return Scaffold(
      appBar: AppBar(
        title: Text(routeTitleName),
      ),
      body: Column(
        children: <Widget>[
          Container(
            height: 300.0,
            child: BlocBuilder<RouteImagesBloc, RouteImagesState>(
              builder: (context, state) {
                if (state is RouteImagesLoaded) {
                  return RouteImageCarousel(
                    images: state.images.allImages(widget.routeWithUserMeta.route.id),
                  );
                } else if (state is RouteImagesError) {
                  return ErrorWidget.builder(state.errorDetails);
                }

                return Center(child: CircularProgressIndicator());
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: gradeAndDifficulty(widget.routeWithUserMeta, 80.0)
                ),
                Expanded(
                  child: qualityAndAscents(context, widget.routeWithUserMeta, 80.0)
                ),
              ],
            )
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildRouteDetails(),
                Text(
                  "Category: ${widget.routeWithUserMeta.route.category}",
                  style: TextStyle(fontSize: HEADING_SIZE_3),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    "Activity:",
                    style: TextStyle(fontSize: HEADING_SIZE_3),
                  ),
                  Expanded(
                    child: _buildRouteAscents(),
                  ),
                ],
              ),
            ),
          ),
        ],
      )
    );
  }

  Widget _buildRouteDetails() {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        if (state is UsersLoaded) {
          var userName = state.users[widget.routeWithUserMeta.route.userId].name;
          return Text(
              "Added by: $userName - ${dateToString(widget.routeWithUserMeta.route.createdAt)}",
              style: TextStyle(fontSize: HEADING_SIZE_3),
          );
        } else if (state is UsersError) {
          return ErrorWidget.builder(state.errorDetails);
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildRouteAscents() {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, usersState) {
        if (usersState is UsersLoaded) {
          return BlocBuilder<UserRouteLogBloc, UserRouteLogState>(
            builder: (context, userRouteLogState) {
              if (userRouteLogState is UserRouteLogLoaded) {
                return _buildRouteAscentsWithUsers(
                  usersState.users,
                  userRouteLogState.userRouteLogs[widget.routeWithUserMeta.route.id],
                );
              } else if (userRouteLogState is UserRouteLogError) {
                return ErrorWidget.builder(userRouteLogState.errorDetails);
              }

              return Center(child: CircularProgressIndicator());
            },
          );
        } else if (usersState is UsersError) {
          return ErrorWidget.builder(usersState.errorDetails);
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildDeleteButton(UserRouteLog userRouteLog) {
    if (widget.getIt<UserRepository>().userId != userRouteLog.userId) {
      return null;
    }

    return IconButton(
      icon: const Icon(Icons.delete_outline),
      onPressed: () async {
        // TODO:
      },
    );
  }

  Widget _buildRouteAscentsWithUsers(Map<int, User> users,
      Map<int, UserRouteLog> userRouteLogs) {
    List<Widget> ascents = [];
    for (var userRouteLog in userRouteLogs.values) {
      var user = users[userRouteLog.userId].name;
      ascents.add(
        ListTile(
          leading: AscentWidget(userRouteLog),
          title: Text(user),
          subtitle: Text(dateToString(userRouteLog.createdAt)),
          trailing: _buildDeleteButton(userRouteLog),
        )
      );
    }

    if (ascents.isEmpty) {
      ascents.add(
          ListTile(title: Text(
            "No ascents yet..",
            style: TextStyle(fontSize: HEADING_SIZE_3),
          ))
      );
    }

    var scrollController = ScrollController();
    return Scrollbar(
      isAlwaysShown: true,
      controller: scrollController,
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: ascents.length,
        itemBuilder: (context, index) => ascents[index],
        separatorBuilder: (context, index) => Divider(),
      ),
    );
  }
}
