import 'dart:collection';
import 'dart:convert';

import 'package:climbicus/blocs/route_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/ui/route_detailed.dart';
import 'package:climbicus/ui/route_predictions.dart';
import 'package:climbicus/utils/api.dart';
import 'package:climbicus/utils/route_image_picker.dart';
import 'package:climbicus/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RouteListItem {
  int entryId;
  Widget image;
  String headerTitle;
  String bodyTitle;
  String bodySubtitle;
  int routeId;
  int imageId;
  String grade;
  DateTime createdAt;
  String username;
  bool isExpanded;
  RouteListItem({
    this.entryId,
    this.image,
    this.headerTitle,
    this.bodyTitle,
    this.bodySubtitle,
    this.routeId,
    this.imageId,
    this.grade,
    this.createdAt,
    this.username,
    this.isExpanded: false
  });
}

class HeaderListItem extends StatelessWidget {
  final Widget image;
  final String title;
  final int routeId;
  final int imageId;
  final String grade;

  const HeaderListItem({this.image, this.title, this.routeId, this.imageId, this.grade});

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
                    return RouteDetailedPage(
                        routeId: this.routeId,
                        routeGrade: this.grade,
                    );
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

class RouteViewPage<T extends RouteBloc> extends StatefulWidget {
  final ApiProvider api = ApiProvider();
  final RouteImagePicker imagePicker = RouteImagePicker();
  final Settings settings = Settings();

  RouteViewPage();

  @override
  State<StatefulWidget> createState() => _RouteViewPageState<T>();
}

class _RouteViewPageState<T extends RouteBloc> extends State<RouteViewPage<T>> {
  RouteImagesBloc _routeImagesBloc;
  RouteBloc _routeBloc;

  List<RouteListItem> _items = [];

  @override
  void initState() {
    super.initState();

    _routeImagesBloc = BlocProvider.of<RouteImagesBloc>(context);
    _routeBloc = BlocProvider.of<T>(context);
    _routeBloc.fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<T, RouteState>(
        builder: (context, state) {
          if (state is RouteLoadedWithImages) {
            return _buildLogbookGrid(state.entries, withImages: true);
          } else if (state is RouteLoaded) {
            return _buildLogbookGrid(state.entries, withImages: false);
          } else if (state is RouteError) {
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

  Widget _buildLogbookGrid(Map entries, {bool withImages: true}) {
    Map<int, bool> isExpandedPrevious = Map.fromIterable(
      _items,
      key: (item) => item.entryId,
      value: (item) => item.isExpanded,
    );
    _items.clear();

    (_sortEntriesByLogDate(entries)).forEach((entryId, fields) {
      var routeId = _routeBloc.routeId(entryId, fields);
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

      bool isExpanded = isExpandedPrevious.containsKey(entryId) ?
          isExpandedPrevious[entryId] :
          false;
      _items.add(RouteListItem(
          entryId: entryId,
          image: imageWidget,
          headerTitle: _routeBloc.headerTitle(fields),
          bodyTitle: _routeBloc.bodyTitle(fields),
          bodySubtitle: _routeBloc.bodySubtitle(fields),
          routeId: routeId,
          imageId: imageId,
          grade: fields.grade,
          createdAt: fields.createdAt,
          username: fields.userId.toString(),
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

  LinkedHashMap _sortEntriesByLogDate(Map entries) {
    var sortedKeys = entries.keys.toList(growable: false)
      ..sort(
          (k1, k2) => entries[k2].createdAt.compareTo(entries[k1].createdAt));

    return LinkedHashMap.fromIterable(sortedKeys,
        key: (k) => k, value: (k) => entries[k]);
  }
}
