import 'dart:collection';

import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/models/user_route_log.dart';
import 'package:climbicus/screens/route_detailed.dart';
import 'package:climbicus/screens/route_predictions.dart';
import 'package:climbicus/widgets/camera_custom.dart';
import 'package:climbicus/widgets/route_image.dart';
import 'package:climbicus/widgets/route_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const MAX_ROUTES_VISIBLE = 100;

class RouteListItem {
  RouteWithLogs routeWithLogs;
  Widget image;
  String headerTitle;
  bool isExpanded;
  RouteListItem({
    this.routeWithLogs,
    this.image,
    this.headerTitle,
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
    UserRouteLog mostRecentLog = routeWithLogs.mostRecentLog();
    var ascentDecoration;
    var ascentStatus;
    if (mostRecentLog != null) {
      var boxColor = (mostRecentLog.completed) ?
          Theme.of(context).accentColor :
          null;

      ascentDecoration = BoxDecoration(
        border: Border.all(
          color: Theme.of(context).accentColor,
          width: 2,
        ),
        color: boxColor,
        borderRadius: BorderRadius.circular(12),
      );

      var numAttemptsStr = mostRecentLog.numAttempts != null ?
          mostRecentLog.numAttempts.toString() :
          " — ";
      ascentStatus = Center(
        child: (mostRecentLog.numAttempts == 1) ?
            Icon(Icons.flash_on, color: Theme.of(context).textTheme.title.color) :
            Text(numAttemptsStr, style: TextStyle(fontSize: 18)),
      );
    }

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
            child: Text(this.title, style: TextStyle(fontSize: 18)),
          ),
          Container(
            height: 60,
            width: 60,
            decoration: ascentDecoration,
            child: ascentStatus,
          ),
        ],
      ),
    );
  }
}


class BodyListItem extends StatefulWidget {
  final RouteWithLogs routeWithLogs;
  final GymRoutesBloc gymRoutesBloc;

  const BodyListItem({this.routeWithLogs, this.gymRoutesBloc});

  @override
  _BodyListItemState createState() => _BodyListItemState();
}

class _BodyListItemState extends State<BodyListItem> {
  final checkboxSentKey = GlobalKey<CheckboxWithTitleState>();
  final sliderAttemptsKey = GlobalKey<SliderAttemptsState>();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: <Widget>[
          CheckboxSent(key: checkboxSentKey),
          Expanded(
            child: SliderAttempts(key: sliderAttemptsKey),
          ),
        ],
      ),
      trailing: RaisedButton(
        child: Text("Add"),
        onPressed: _onAddButtonPressed,
      ),
    );
  }

  void _onAddButtonPressed() {
    widget.gymRoutesBloc.add(AddNewUserRouteLog(
      routeId: widget.routeWithLogs.route.id,
      completed: checkboxSentKey.currentState.value,
      numAttempts: sliderAttemptsKey.currentState.value,
    ));
  }
}

class RouteViewPage extends StatefulWidget {
  final String routeCategory;
  final int gymId;

  RouteViewPage({@required this.routeCategory, @required this.gymId}) :
        super(key: ValueKey("$gymId-$routeCategory"));

  @override
  State<StatefulWidget> createState() => _RouteViewPageState();
}

class _RouteViewPageState extends State<RouteViewPage> with AutomaticKeepAliveClientMixin {
  final checkboxHideSentKey = GlobalKey<CheckboxWithTitleState>();
  final checkboxHideAttemptedKey = GlobalKey<CheckboxWithTitleState>();
  final sliderRouteGradesKey = GlobalKey<SliderRouteGradesState>();

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
      body: Column(
        children: <Widget>[
          _buildRouteFilterTile(),
          Expanded(
            child: BlocBuilder<GymRoutesBloc, GymRoutesState>(
              builder: (context, state) {
                if (state is GymRoutesLoaded) {
                  return _buildLogbookGrid(state.entriesFiltered);
                } else if (state is GymRoutesError) {
                  return ErrorWidget.builder(state.errorDetails);
                }

                return Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildImagePicker(),
    );
  }

  Widget _buildImagePicker() {
    return FloatingActionButton(
      onPressed: () async {
        final imageFile = await Navigator.push(context, MaterialPageRoute(
          builder: (BuildContext context) {
            return CameraCustom();
          },
        ));
        if (imageFile == null) {
          return;
        }

        Navigator.push(context, MaterialPageRoute(
          builder: (BuildContext context) {
            return RoutePredictionsPage(image: imageFile, routeCategory: widget.routeCategory);
          },
        ));
      },
      tooltip: "Add a new route",
      child: Icon(Icons.add_a_photo),
      heroTag: "camera-new-route-${widget.routeCategory}",
    );
  }

  Widget _buildRouteFilterTile() {
    return ExpansionTile(
      leading: const Icon(Icons.filter_list),
      title: Text(""),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: CheckboxWithTitle(
                key: checkboxHideSentKey,
                title: "Hide sent",
                titleAbove: false,
                onTicked: () => _gymRoutesBloc.add(
                    FilterSentGymRoutes(
                      enabled: checkboxHideSentKey.currentState.value,
                      category: widget.routeCategory,
                    )
                ),
              ),
            ),
            Expanded(
              child: CheckboxWithTitle(
                key: checkboxHideAttemptedKey,
                title: "Hide attempted",
                titleAbove: false,
                onTicked: () => _gymRoutesBloc.add(
                    FilterAttemptedGymRoutes(
                      enabled: checkboxHideAttemptedKey.currentState.value,
                      category: widget.routeCategory,
                    )
                ),
              ),
            ),
          ],
        ),
        SliderRouteGrades(
          key: sliderRouteGradesKey,
          routeCategory: widget.routeCategory,
          onChangeEnd: () => _gymRoutesBloc.add(
            FilterGradesGymRoutes(
              gradeValues: sliderRouteGradesKey.currentState.values,
              category: widget.routeCategory,
            )
          ),
        ),
      ],
    );
  }

  Widget _buildLogbookGrid(RoutesWithLogs entries) {
    if (entries.isEmpty(widget.routeCategory)) {
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

    var i = 0;
    (_sortEntriesByLogDate(entries.allRoutes(widget.routeCategory))).forEach((routeId, routeWithLogs) {
      if (++i > MAX_ROUTES_VISIBLE) {
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

      _items.add(RouteListItem(
          routeWithLogs: routeWithLogs,
          image: imageWidget,
          headerTitle: routeWithLogs.route.grade,
          isExpanded: isExpanded,
      ));
    });

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
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
              body: BodyListItem(
                routeWithLogs: item.routeWithLogs,
                gymRoutesBloc: _gymRoutesBloc
              ),
              isExpanded: item.isExpanded,
            );
          }).toList(),
        ),
      ),
    );
  }

  // TODO: move elsewhere
  Map<int, RouteWithLogs> _sortEntriesByLogDate(Map<int, RouteWithLogs> entries) {
    var sortedKeys = entries.keys.toList(growable: false)
      ..sort((k1, k2) => entries[k2].route.createdAt.compareTo(entries[k1].route.createdAt));

    return LinkedHashMap.fromIterable(sortedKeys,
        key: (k) => k, value: (k) => entries[k]);
  }

  @override
  bool get wantKeepAlive => true;
}
