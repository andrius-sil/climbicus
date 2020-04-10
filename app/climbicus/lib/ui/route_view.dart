import 'dart:collection';
import 'dart:convert';

import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/ui/route_detailed.dart';
import 'package:climbicus/ui/route_predictions.dart';
import 'package:climbicus/utils/route_image_picker.dart';
import 'package:climbicus/utils/settings.dart';
import 'package:climbicus/utils/time.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RouteListItem {
  RouteWithLogs routeWithLogs;
  int routeId;
  Widget image;
  String headerTitle;
  String bodyTitle;
  String bodySubtitle;
  int imageId;
  String grade;
  DateTime createdAt;
  String username;
  bool isExpanded;
  RouteListItem({
    this.routeWithLogs,
    this.routeId,
    this.image,
    this.headerTitle,
    this.bodyTitle,
    this.bodySubtitle,
    this.imageId,
    this.grade,
    this.createdAt,
    this.username,
    this.isExpanded: false
  });
}

class HeaderListItem extends StatelessWidget {
  final RouteWithLogs routeWithLogs;
  final Widget image;
  final String title;
  final int routeId;
  final int imageId;
  final String grade;

  const HeaderListItem({this.routeWithLogs, this.image, this.title, this.routeId, this.imageId, this.grade});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (BuildContext context) {
                    return RouteDetailedPage(routeWithLogs: this.routeWithLogs);
                  },
                ));
              },
              child: Container(
                height: 80,
                child: Stack(
                  children: <Widget>[
                    this.image,
  //                  Align(
  //                    alignment: Alignment.bottomLeft,
  //                    child: Text("route_id: $routeId, image_id: $imageId"),
  //                  ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(this.title),
          ),
        ],
      ),
    );
  }

}

class RouteViewPage extends StatefulWidget {
  final RouteImagePicker imagePicker = RouteImagePicker();
  final Settings settings = Settings();

  RouteViewPage();

  @override
  State<StatefulWidget> createState() => _RouteViewPageState();
}

class _RouteViewPageState extends State<RouteViewPage> {
  RouteImagesBloc _routeImagesBloc;
  GymRoutesBloc _gymRoutesBloc;

  List<RouteListItem> _items = [];

  @override
  void initState() {
    super.initState();

    _routeImagesBloc = BlocProvider.of<RouteImagesBloc>(context);
    _gymRoutesBloc = BlocProvider.of<GymRoutesBloc>(context);

    _gymRoutesBloc.add(FetchGymRoutes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<GymRoutesBloc, GymRoutesState>(
        builder: (context, state) {
          if (state is GymRoutesLoadedWithImages) {
            return _buildLogbookGrid(state.entries, withImages: true);
          } else if (state is GymRoutesLoaded) {
            return _buildLogbookGrid(state.entries, withImages: false);
          } else if (state is GymRoutesError) {
            return ErrorWidget.builder(state.errorDetails);
          }

          return CircularProgressIndicator();
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: _buildImagePicker(),
      ),
    );
  }

  List<Widget> _buildImagePicker() {
    List<Widget> widgets = [];

    widget.settings.imagePickerSource.forEach((imageSource) {
      widgets.add(FloatingActionButton(
        onPressed: () async {
          var image = await widget.imagePicker.pickImage(imageSource, _routeImagesBloc);
          if (image == null) {
            return;
          }

          Navigator.push(context, MaterialPageRoute(
            builder: (BuildContext context) {
              return RoutePredictionsPage(image: image);
            },
          ));
        },
        tooltip: IMAGE_SOURCES[imageSource]["tooltip"],
        child: Icon(IMAGE_SOURCES[imageSource]["icon"]),
        heroTag: IMAGE_SOURCES[imageSource]["heroTag"],
      ));

      if (imageSource != widget.settings.imagePickerSource.last) {
        widgets.add(SizedBox(height: 16.0));
      }
    });

    return widgets;
  }

  Widget _buildLogbookGrid(RoutesWithLogs entries, {bool withImages: true}) {
    Map<int, bool> isExpandedPrevious = Map.fromIterable(
      _items,
      key: (item) => item.routeId,
      value: (item) => item.isExpanded,
    );
    _items.clear();

    (_sortEntriesByLogDate(entries.allRoutes())).forEach((routeId, routeWithLogs) {
      var routeImage = _routeImagesBloc.images.defaultImage(routeId);
      var imageWidget;
      var imageId;
      if (!withImages) {
        imageWidget = Container(width: 0, height: 0);
      } else if (routeImage != null) {
        imageWidget = Image.memory(base64.decode(routeImage.b64Image));
        imageId = routeImage.id;
      } else {
        imageWidget = Image.asset("images/no_image.png");
        imageId = -1;
      }

      bool isExpanded = isExpandedPrevious.containsKey(routeId) ?
          isExpandedPrevious[routeId] :
          false;
      _items.add(RouteListItem(
          routeWithLogs: routeWithLogs,
          routeId: routeId,
          image: imageWidget,
          headerTitle: routeWithLogs.route.grade,
          bodyTitle: "${dateToString(routeWithLogs.route.createdAt)}",
          bodySubtitle: "added by usr '${routeWithLogs.route.userId.toString()}'",
          imageId: imageId,
          grade: routeWithLogs.route.grade,
          createdAt: routeWithLogs.route.createdAt,
          username: routeWithLogs.route.userId.toString(),
          isExpanded: isExpanded,
      ));
    });

    return SingleChildScrollView(
      child: ExpansionPanelList(
        expansionCallback: (int i, bool isExpanded) {
          setState(() {
            _items[i].isExpanded = !isExpanded;
          });
        },
        children: _items.map<ExpansionPanel>((RouteListItem item) {
          return ExpansionPanel(
            headerBuilder: (BuildContext context, bool isExpanded) {
              return HeaderListItem(
                routeWithLogs: item.routeWithLogs,
                image: item.image,
                title: item.headerTitle,
                routeId: item.routeId,
                imageId: item.imageId,
                grade: item.grade,
              );
            },
            body: ListTile(
              title: item.bodyTitle != null ? Text(item.bodyTitle): null,
              subtitle: Text(item.bodySubtitle),
//              trailing: Icon(Icons.delete),
            ),
            isExpanded: item.isExpanded,
          );
        }).toList(),
      ),
    );
  }

  LinkedHashMap _sortEntriesByLogDate(Map<int, RouteWithLogs> entries) {
    var sortedKeys = entries.keys.toList(growable: false)
      ..sort((k1, k2) => entries[k2].route.createdAt.compareTo(entries[k1].route.createdAt));

    return LinkedHashMap.fromIterable(sortedKeys,
        key: (k) => k, value: (k) => entries[k]);
  }
}
