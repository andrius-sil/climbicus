import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/blocs/users_bloc.dart';
import 'package:climbicus/utils/time.dart';
import 'package:climbicus/widgets/route_image_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../style.dart';

class RouteDetailedPage extends StatefulWidget {
  final RouteWithUserMeta routeWithUserMeta;

  const RouteDetailedPage({@required this.routeWithUserMeta});

  @override
  State<StatefulWidget> createState() => _RouteDetailedPage();
}

class _RouteDetailedPage extends State<RouteDetailedPage> {
  RouteImagesBloc _routeImagesBloc;
  UsersBloc _usersBloc;

  @override
  void initState() {
    super.initState();

    _routeImagesBloc = BlocProvider.of<RouteImagesBloc>(context);
    _routeImagesBloc.add(FetchRouteImagesAll(routeId: widget.routeWithUserMeta.route.id));

    _usersBloc = BlocProvider.of<UsersBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.routeWithUserMeta.route.grade} route'),
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
                    height: 300.0,
                  );
                } else if (state is RouteImagesError) {
                  return ErrorWidget.builder(state.errorDetails);
                }

                return Center(child: CircularProgressIndicator());
              },
            ),
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
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  "Your ascents:",
                  style: TextStyle(fontSize: HEADING_SIZE_3),
                ),
                Container(
                  height: 200,
                  child: _buildRouteAscents(),
                ),
              ],
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
    List<Widget> ascents = [];
    for (var userRouteLog in widget.routeWithUserMeta.userRouteLogs.values) {
      var status = (userRouteLog.completed) ? "Sent!" : "Attempted";
      var tries = (userRouteLog.numAttempts == null) ? "" : "(${userRouteLog.numAttempts} tries)";
      ascents.add(
          ListTile(title: Text(
            "$status $tries - ${dateToString(userRouteLog.createdAt)}",
            style: TextStyle(fontSize: HEADING_SIZE_3),
          ))
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

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: ascents.length,
      itemBuilder: (context, index) => ascents[index],
      separatorBuilder: (context, index) => Divider(),
    );
  }
}
