
import 'package:carousel_slider/carousel_slider.dart';
import 'package:climbicus/models/route_image.dart';
import 'package:climbicus/widgets/route_image.dart';
import 'package:flutter/material.dart';

class RouteImageCarousel extends StatefulWidget {
  final Map<int, RouteImage> images;

  const RouteImageCarousel({this.images});

  @override
  _RouteImageCarouselState createState() => _RouteImageCarouselState();
}

class _RouteImageCarouselState extends State<RouteImageCarousel> {
  int _current = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images == null) {
      return Container(
        alignment: Alignment.center,
        child: RouteImageWidget(null),
      );
    }

    return Stack(children: [
      CarouselSlider(
        viewportFraction: 0.5,
        enlargeCenterPage: true,
        enableInfiniteScroll: false,
        items: widget.images.values.map((img) {
          return Builder(
              builder: (BuildContext context) {
                return RouteImageWidget(img);
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
          children: widget.images.values.toList().asMap().map((index, i) {
            return MapEntry(index, Container(
              width: 8.0,
              height: 8.0,
              margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _current == index
                      ? Theme.of(context).accentColor
                      : Theme.of(context).unselectedWidgetColor
              ),
            ));
          }).values.toList(),
        ),
      ),
    ]);
  }
}
