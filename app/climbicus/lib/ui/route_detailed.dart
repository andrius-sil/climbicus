import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RouteDetailedPage extends StatefulWidget {
  final int routeId;

  const RouteDetailedPage({@required this.routeId});

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

    _routeImagesBloc.add(FetchRouteImagesAll(
      routeId: widget.routeId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('a route'),
      ),
      body: BlocBuilder<RouteImagesBloc, RouteImagesState>(
        builder: (context, state) {
          if (state is RouteImagesLoaded) {
            return _buildImageCarousel(state.images);
          } else if (state is RouteImagesError) {
            return ErrorWidget.builder(state.errorDetails);
          }

          return CircularProgressIndicator();
        },
      ),
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
}
