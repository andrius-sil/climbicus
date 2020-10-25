import 'dart:collection';

import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/models/user_route_log.dart';
import 'package:climbicus/screens/route_detailed.dart';
import 'package:climbicus/screens/route_predictions.dart';
import 'package:climbicus/widgets/camera_custom.dart';
import 'package:climbicus/widgets/rating_star.dart';
import 'package:climbicus/widgets/route_image.dart';
import 'package:climbicus/widgets/route_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

const MAX_ROUTES_VISIBLE = 100;
const ROUTE_LIST_ITEM_HEIGHT = 80.0;

class RouteListItem {
  RouteWithLogs routeWithLogs;
  Widget image;
  bool isExpanded;
  RouteListItem({
    this.routeWithLogs,
    this.image,
    this.isExpanded: false
  });
}

class HeaderListItem extends StatelessWidget {
  final RouteWithLogs routeWithLogs;
  final Widget image;

  const HeaderListItem({this.routeWithLogs, this.image});

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
        child: (mostRecentLog.completed && mostRecentLog.numAttempts == 1) ?
            Icon(Icons.flash_on, color: Theme.of(context).textTheme.headline6.color) :
            Text(numAttemptsStr, style: TextStyle(fontSize: 18)),
      );
    }

    Widget ratingBarIndicator = Container();
    if (this.routeWithLogs.route.avgQuality != null) {
      ratingBarIndicator = RatingBar(
        itemSize: 20.0,
        initialRating: this.routeWithLogs.route.avgQuality,
        itemCount: 3,
        ratingWidget: ratingStar(),
        onRatingUpdate: (_) => {},
      );
    }

    Widget routeNameText;
    if (this.routeWithLogs.route.name != null) {
      routeNameText = Text(this.routeWithLogs.route.name, style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic));
    }
    Widget routeName = Container(
      padding: const EdgeInsets.only(left: 8.0),
      child: routeNameText,
    );

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          routeName,
          Row(
            children: <Widget>[
              Container(
                height: 60,
                width: 60,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: ascentDecoration,
                child: ascentStatus,
              ),
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
                    height: ROUTE_LIST_ITEM_HEIGHT,
                    child: this.image,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: ROUTE_LIST_ITEM_HEIGHT,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(this.routeWithLogs.route.grade, style: TextStyle(fontSize: 18)),
                      Text(
                        this.routeWithLogs.route.avgDifficulty == null ?
                          "" : this.routeWithLogs.route.avgDifficulty,
                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: ROUTE_LIST_ITEM_HEIGHT,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ratingBarIndicator,
                      Text(
                        "${this.routeWithLogs.numAttempts().toString()} ascents",
                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class BodyListItem extends StatefulWidget {
  final RouteWithLogs routeWithLogs;
  final GymRoutesBloc gymRoutesBloc;
  final VoidCallback onAdd;

  const BodyListItem({this.routeWithLogs, this.gymRoutesBloc, this.onAdd});

  @override
  _BodyListItemState createState() => _BodyListItemState();
}

class _BodyListItemState extends State<BodyListItem> {
  final checkboxSentKey = GlobalKey<CheckboxWithTitleState>();
  final numberAttemptsKey = GlobalKey<NumberAttemptsState>();
  final routeDifficultyKey = GlobalKey<RouteDifficultyRatingState>();
  final routeQualityKey = GlobalKey<RouteQualityRatingState>();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: <Widget>[
              Expanded(
                child: CheckboxSent(key: checkboxSentKey),
              ),
              Expanded(
                child: NumberAttempts(key: numberAttemptsKey),
              ),
            ],
          ),
          RouteDifficultyRating(key: routeDifficultyKey),
          RouteQualityRating(key: routeQualityKey),
          RaisedButton(
            child: Text("Add"),
            onPressed: _onAddButtonPressed,
          ),
        ],
      ),
    );
  }

  void _onAddButtonPressed() {
    widget.onAdd();

    widget.gymRoutesBloc.add(AddNewUserRouteLog(
      routeId: widget.routeWithLogs.route.id,
      completed: checkboxSentKey.currentState.value,
      numAttempts: numberAttemptsKey.currentState.value,
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
                  return _buildLogbookGridWithRefresh(state.entriesFiltered);
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

  Widget _buildLogbookGridWithRefresh(RoutesWithLogs entries) {
    return RefreshIndicator(
      onRefresh: onRefreshView,
      child: _buildLogbookGrid(entries),
    );
  }

  Widget _buildLogbookGrid(RoutesWithLogs entries) {
    if (entries.isEmpty(widget.routeCategory)) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Text(
            "No routes found..",
            textAlign: TextAlign.center,
          ),
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
          isExpanded: isExpanded,
      ));
    });

    // Using AlwaysScrollableScrollPhysics to ensure that RefreshIndicator
    // appears always.
    return Scrollbar(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: ROUTE_LIST_ITEM_HEIGHT),
        child: ExpansionPanelList(
          expansionCallback: (int i, bool isExpanded) {
            setState(() {
              _items[i].isExpanded = !isExpanded;
            });
          },
          children: _items.asMap().entries.map((entry) {
            int idx = entry.key;
            RouteListItem item = entry.value;

            return ExpansionPanel(
              headerBuilder: (BuildContext context, bool isExpanded) {
                return HeaderListItem(
                  routeWithLogs: item.routeWithLogs,
                  image: item.image,
                );
              },
              body: BodyListItem(
                routeWithLogs: item.routeWithLogs,
                gymRoutesBloc: _gymRoutesBloc,
                onAdd: () => _items[idx].isExpanded = false,
              ),
              isExpanded: item.isExpanded,
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> onRefreshView() async {
    _gymRoutesBloc.add(FetchGymRoutes());
  }

  // TODO: move elsewhere
  Map<int, RouteWithLogs> _sortEntriesByLogDate(Map<int, RouteWithLogs> entries) {
    var sortedKeys = entries.keys.toList(growable: false)
      ..sort((k1, k2) => entries[k2].mostRecentCreatedAt().compareTo(entries[k1].mostRecentCreatedAt()));

    return LinkedHashMap.fromIterable(sortedKeys,
        key: (k) => k, value: (k) => entries[k]);
  }

  @override
  bool get wantKeepAlive => true;
}
