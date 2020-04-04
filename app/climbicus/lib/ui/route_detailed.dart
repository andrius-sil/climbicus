import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:climbicus/blocs/gym_route_bloc.dart';
import 'package:climbicus/blocs/user_route_log_bloc.dart';
import 'package:climbicus/json/route.dart' as jsonmdl;
import 'package:climbicus/blocs/route_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/json/user_route_log_entry.dart';
import 'package:climbicus/utils/time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RouteDetailedPage extends StatefulWidget {
  final int routeId;
  final String routeGrade;

  const RouteDetailedPage({@required this.routeId, @required this.routeGrade});

  @override
  State<StatefulWidget> createState() => _RouteDetailedPage();
}

class _RouteDetailedPage extends State<RouteDetailedPage> {
  RouteImagesBloc _routeImagesBloc;
  GymRouteBloc _gymRouteBloc;
  UserRouteLogBloc _userRouteLogBloc;

  int _current = 0;

  @override
  void initState() {
    super.initState();

    _routeImagesBloc = BlocProvider.of<RouteImagesBloc>(context);
    _gymRouteBloc = BlocProvider.of<GymRouteBloc>(context);
    _userRouteLogBloc = BlocProvider.of<UserRouteLogBloc>(context);

    _routeImagesBloc.add(FetchRouteImagesAll(routeId: widget.routeId,));
    _gymRouteBloc.add(FetchGymRoutes(routeId: widget.routeId));
    _userRouteLogBloc.add(FetchUserRouteLog(routeId: widget.routeId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.routeGrade} route'),
      ),
      body: Column(
        children: <Widget>[
          BlocBuilder<RouteImagesBloc, RouteImagesState>(
            builder: (context, state) {
              if (state is RouteImagesLoaded) {
                return _buildImageCarousel(state.images);
              } else if (state is RouteImagesError) {
                return ErrorWidget.builder(state.errorDetails);
              }

              return CircularProgressIndicator();
            },
          ),
          BlocBuilder<GymRouteBloc, RouteState>(
            builder: (context, state) {
              if (state is RouteLoaded) {
                return _buildRouteDetails(state.entries);
              } else if (state is RouteError) {
                return ErrorWidget.builder(state.errorDetails);
              }

              return CircularProgressIndicator();
            },
          ),
          Text("Your ascents:"),
          BlocBuilder<UserRouteLogBloc, RouteState>(
            builder: (context, state) {
              if (state is RouteLoaded) {
                return _buildRouteAscents(state.entries);
              } else if (state is RouteError) {
                return ErrorWidget.builder(state.errorDetails);
              }

              return CircularProgressIndicator();
            },
          ),
        ],
      )
    );
  }

  Widget _buildImageCarousel(Images images) {
    var allImages = images.allImages(widget.routeId);
    if (allImages == null) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Image.asset("images/no_image.png"),
      );
    }

    return Stack(children: [
      CarouselSlider(
        height: 200,
        viewportFraction: 0.5,
        enlargeCenterPage: true,
        enableInfiniteScroll: false,
        items: allImages.values.map((img) {
          return Builder(
            builder: (BuildContext context) {
              return Container(
                child: Image.memory(base64.decode(img.b64Image)),
              );
            }
          );
        }).toList(),
        onPageChanged: (index) {
          setState(() {
            _current = index;
          });
        },
      ),
      Positioned(
        top: 0.0,
        left: 0.0,
        right: 0.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: allImages.values.toList().asMap().map((index, i) {
            return MapEntry(index, Container(
              width: 8.0,
              height: 8.0,
              margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _current == index
                      ? Color.fromRGBO(0, 0, 0, 0.9)
                      : Color.fromRGBO(0, 0, 0, 0.4)
              ),
            ));
          }).values.toList(),
        ),
      ),
    ]);
  }

  Widget _buildRouteDetails(Map<int, jsonmdl.Route> entries) {
    var currentRoute = entries[widget.routeId];

    return Text("added by 'user ${currentRoute.userId.toString()}' (${dateToString(currentRoute.createdAt)})");
  }

  Widget _buildRouteAscents(Map<int, UserRouteLogEntry> entries) {
    List<Widget> ascents = [];
    for (UserRouteLogEntry entry in entries.values) {
      if (entry.routeId != widget.routeId) {
        continue;
      }

      ascents.add(Text("${entry.status} - ${dateToString(entry.createdAt)}"));
    }

    if (ascents.isEmpty) {
      return Text("no ascents yet..");
    }

    return Column(
      children: ascents,
    );
  }
}
