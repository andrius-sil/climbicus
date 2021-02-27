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

const MAX_ROUTES_VISIBLE = 100;
const ROUTE_LIST_ITEM_HEIGHT = 80.0;

class RouteListItem {
  RouteWithUserMeta routeWithUserMeta;
  Widget image;
  bool isExpanded;
  RouteListItem({
    this.routeWithUserMeta,
    this.image,
    this.isExpanded: false
  });
}

class HeaderListItem extends StatelessWidget {
  final RouteWithUserMeta routeWithUserMeta;
  final Widget image;

  const HeaderListItem({this.routeWithUserMeta, this.image});

  @override
  Widget build(BuildContext context) {
    UserRouteLog mostRecentLog = routeWithUserMeta.mostRecentLog();

    Widget routeNameText;
    if (this.routeWithUserMeta.route.name != null) {
      routeNameText = Text(this.routeWithUserMeta.route.name, style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic));
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
              AscentWidget(mostRecentLog),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (BuildContext context) {
                        return RouteDetailedPage(routeWithUserMeta: this.routeWithUserMeta);
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
                child: gradeAndDifficulty(this.routeWithUserMeta,
                    ROUTE_LIST_ITEM_HEIGHT),
              ),
              Expanded(
                child: qualityAndAscents(context, this.routeWithUserMeta,
                    ROUTE_LIST_ITEM_HEIGHT),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class BodyListItem extends StatefulWidget {
  final RouteWithUserMeta routeWithUserMeta;
  final GymRoutesBloc gymRoutesBloc;
  final VoidCallback onAdd;

  const BodyListItem({this.routeWithUserMeta, this.gymRoutesBloc, this.onAdd});

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
    return Column(
      children: [
        Row(
          children: <Widget>[
            Expanded(child: CheckboxSent(key: checkboxSentKey)),
            Expanded(child: NumberAttempts(key: numberAttemptsKey)),
          ],
        ),
        Row(
          children: <Widget>[
            Expanded(child: RouteDifficultyRating(key: routeDifficultyKey)),
            Expanded(child: RouteQualityRating(key: routeQualityKey)),
          ],
        ),
        RaisedButton(
          child: Text("Add"),
          onPressed: _onAddButtonPressed,
        ),
      ],
    );
  }

  void _onAddButtonPressed() {
    widget.onAdd();

    widget.gymRoutesBloc.add(AddNewUserRouteLog(
      routeId: widget.routeWithUserMeta.route.id,
      completed: checkboxSentKey.currentState.value,
      numAttempts: numberAttemptsKey.currentState.value,
    ));

    widget.gymRoutesBloc.add(AddOrUpdateUserRouteVotes(
      routeId: widget.routeWithUserMeta.route.id,
      userRouteVotesData: UserRouteVotesData(
        routeQualityKey.currentState.value,
        routeDifficultyKey.currentState.value,
      ),
    ));

    // Clear the fields.
    checkboxSentKey.currentState.resetState();
    numberAttemptsKey.currentState.resetState();
    routeQualityKey.currentState.resetState();
    routeDifficultyKey.currentState.resetState();
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

  Widget _buildLogbookGridWithRefresh(RoutesWithUserMeta entries) {
    return RefreshIndicator(
      onRefresh: onRefreshView,
      child: _buildLogbookGrid(entries),
    );
  }

  Widget _buildLogbookGrid(RoutesWithUserMeta entries) {
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
    _items.forEach((item) => isExpandedPrevious[item.routeWithUserMeta.route.id] = item.isExpanded);
    _items.clear();

    var i = 0;
    (_sortEntriesByLogDate(entries.allRoutes(widget.routeCategory))).forEach((routeId, routeWithUserMeta) {
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
          routeWithUserMeta: routeWithUserMeta,
          image: imageWidget,
          isExpanded: isExpanded,
      ));
    });

    // Using AlwaysScrollableScrollPhysics to ensure that RefreshIndicator
    // appears always.
    var scrollController = ScrollController();
    return Scrollbar(
      controller: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
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
                  routeWithUserMeta: item.routeWithUserMeta,
                  image: item.image,
                );
              },
              body: BodyListItem(
                routeWithUserMeta: item.routeWithUserMeta,
                gymRoutesBloc: _gymRoutesBloc,
                onAdd: () {
                  _items[idx].isExpanded = false;

                  // using 0.5 as per https://github.com/flutter/flutter/issues/26833
                  scrollController.animateTo(
                    0.5,
                    curve: Curves.easeOut,
                    duration: const Duration(milliseconds: 100),
                  );
                }
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
  Map<int, RouteWithUserMeta> _sortEntriesByLogDate(Map<int, RouteWithUserMeta> entries) {
    var sortedKeys = entries.keys.toList(growable: false)
      ..sort((k1, k2) => entries[k2].mostRecentCreatedAt().compareTo(entries[k1].mostRecentCreatedAt()));

    return LinkedHashMap.fromIterable(sortedKeys,
        key: (k) => k, value: (k) => entries[k]);
  }

  @override
  bool get wantKeepAlive => true;
}
