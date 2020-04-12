import 'package:carousel_slider/carousel_slider.dart';
import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/utils/time.dart';
import 'package:climbicus/widgets/b64image.dart';
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

  int _current = 0;

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
                return _buildImageCarousel(state.images);
              } else if (state is RouteImagesError) {
                return ErrorWidget.builder(state.errorDetails);
              }

              return CircularProgressIndicator();
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

  Widget _buildImageCarousel(Images images) {
    var allImages = images.allImages(widget.routeWithLogs.route.id);
    if (allImages == null) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: B64Image(null),
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
                child: B64Image(img),
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
