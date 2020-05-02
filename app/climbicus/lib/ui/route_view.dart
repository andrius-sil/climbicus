import 'dart:collection';

import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/blocs/settings_bloc.dart';
import 'package:climbicus/ui/route_detailed.dart';
import 'package:climbicus/ui/route_predictions.dart';
import 'package:climbicus/utils/route_image_picker.dart';
import 'package:climbicus/utils/time.dart';
import 'package:climbicus/widgets/route_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class RouteListItem {
  RouteWithLogs routeWithLogs;
  Widget image;
  String headerTitle;
  String bodyTitle;
  String bodySubtitle;
  bool isExpanded;
  RouteListItem({
    this.routeWithLogs,
    this.image,
    this.headerTitle,
    this.bodyTitle,
    this.bodySubtitle,
    this.isExpanded: false
  });
}

class HeaderListItem extends StatelessWidget {
  final RouteWithLogs routeWithLogs;
  final Widget image;
  final String title;

  const HeaderListItem({this.routeWithLogs, this.image, this.title});

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
                child: this.image,
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

  final String routeCategory;
  final int gymId;

  RouteViewPage({@required this.routeCategory, @required this.gymId}) :
        super(key: ValueKey("$gymId-$routeCategory"));

  @override
  State<StatefulWidget> createState() => _RouteViewPageState();
}

class _RouteViewPageState extends State<RouteViewPage> with AutomaticKeepAliveClientMixin {
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
    super.build(context);
    return Scaffold(
      body: BlocBuilder<GymRoutesBloc, GymRoutesState>(
        builder: (context, state) {
          if (state is GymRoutesLoaded) {
            return _buildLogbookGrid(state.entries);
          } else if (state is GymRoutesError) {
            return ErrorWidget.builder(state.errorDetails);
          }

          return Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildImagePicker(state.imagePickerSources),
          );
        }
      ),
    );
  }

  List<Widget> _buildImagePicker(List<ImageSource> imagePickerSources) {
    List<Widget> widgets = [];

    imagePickerSources.forEach((imageSource) {
      widgets.add(FloatingActionButton(
        onPressed: () async {
          var image = await widget.imagePicker.pickImage(imageSource);
          if (image == null) {
            return;
          }

          Navigator.push(context, MaterialPageRoute(
            builder: (BuildContext context) {
              return RoutePredictionsPage(image: image, routeCategory: widget.routeCategory);
            },
          ));
        },
        tooltip: IMAGE_SOURCES[imageSource]["tooltip"],
        child: Icon(IMAGE_SOURCES[imageSource]["icon"]),
        heroTag: "${IMAGE_SOURCES[imageSource]["heroTag"]}-${widget.routeCategory}",
      ));

      if (imageSource != imagePickerSources.last) {
        widgets.add(SizedBox(height: 16.0));
      }
    });

    return widgets;
  }

  Widget _buildLogbookGrid(RoutesWithLogs entries) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          "No routes in this gym yet..",
          textAlign: TextAlign.center,
        ),
      );
    }

    Map<int, bool> isExpandedPrevious = {};
    _items.forEach((item) => isExpandedPrevious[item.routeWithLogs.route.id] = item.isExpanded);
    _items.clear();

    (_sortEntriesByLogDate(entries.allRoutes())).forEach((routeId, routeWithLogs) {
      if (routeWithLogs.route.category != widget.routeCategory) {
        return;
      }

      var imageWidget = BlocBuilder<RouteImagesBloc, RouteImagesState>(
        builder: (context, state) {
          if (state is RouteImagesLoaded) {
            var routeImage = _routeImagesBloc.images.defaultImage(routeId);
            return RouteImageWidget(routeImage);
          } else {
            return Container(width: 0, height: 0);
          }
        },
      );

      bool isExpanded = isExpandedPrevious.containsKey(routeId) ?
          isExpandedPrevious[routeId] :
          false;

      var logTitle = routeWithLogs.userRouteLogs.isEmpty ?
          "" :
          " - climbed";
      _items.add(RouteListItem(
          routeWithLogs: routeWithLogs,
          image: imageWidget,
          headerTitle: routeWithLogs.route.grade + logTitle,
          bodyTitle: "${dateToString(routeWithLogs.route.createdAt)}",
          bodySubtitle: "added by user '${routeWithLogs.route.userId.toString()}'",
          isExpanded: isExpanded,
      ));
    });

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 160),
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
      ),
    );
  }

  Map<int, RouteWithLogs> _sortEntriesByLogDate(Map<int, RouteWithLogs> entries) {
    var sortedKeys = entries.keys.toList(growable: false)
      ..sort((k1, k2) => entries[k2].route.createdAt.compareTo(entries[k1].route.createdAt));

    return LinkedHashMap.fromIterable(sortedKeys,
        key: (k) => k, value: (k) => entries[k]);
  }

  @override
  bool get wantKeepAlive => true;
}
