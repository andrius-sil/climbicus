import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/utils/time.dart';
import 'package:climbicus/widgets/route_image_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RouteDetailedPage extends StatefulWidget {
  final RouteWithLogs routeWithLogs;

  const RouteDetailedPage({@required this.routeWithLogs});

  @override
  State<StatefulWidget> createState() => _RouteDetailedPage();
}

class _RouteDetailedPage extends State<RouteDetailedPage> {
  RouteImagesBloc _routeImagesBloc;

  @override
  void initState() {
    super.initState();

    _routeImagesBloc = BlocProvider.of<RouteImagesBloc>(context);
    _routeImagesBloc.add(FetchRouteImagesAll(routeId: widget.routeWithLogs.route.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.routeWithLogs.route.grade} route'),
      ),
      body: Column(
        children: <Widget>[
          BlocBuilder<RouteImagesBloc, RouteImagesState>(
            builder: (context, state) {
              if (state is RouteImagesLoaded) {
                return RouteImageCarousel(
                  images: state.images.allImages(widget.routeWithLogs.route.id),
                );
              } else if (state is RouteImagesError) {
                return ErrorWidget.builder(state.errorDetails);
              }

              return Center(child: CircularProgressIndicator());
            },
          ),
          _buildRouteDetails(),
          Text(widget.routeWithLogs.route.category),
          Text("Your ascents:"),
          _buildRouteAscents(),
        ],
      )
    );
  }

  Widget _buildRouteDetails() {
    return Text("added by 'user ${widget.routeWithLogs.route.userId.toString()}' (${dateToString(widget.routeWithLogs.route.createdAt)})");
  }

  Widget _buildRouteAscents() {
    List<Widget> ascents = [];
    for (var userRouteLog in widget.routeWithLogs.userRouteLogs.values) {
      var status = (userRouteLog.completed) ? "sent" : "attempted";
      var tries = (userRouteLog.numAttempts == null) ? "" : "(${userRouteLog.numAttempts} tries)";
      ascents.add(Text("$status $tries - ${dateToString(userRouteLog.createdAt)}"));
    }

    if (ascents.isEmpty) {
      return Text("no ascents yet..");
    }

    return Column(
      children: ascents,
    );
  }
}
