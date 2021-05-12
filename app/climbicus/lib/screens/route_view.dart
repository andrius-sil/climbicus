import 'dart:collection';

import 'package:climbicus/blocs/gym_areas_bloc.dart';
import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/models/app/area_route_list_items.dart';
import 'package:climbicus/models/app/route_user_meta.dart';
import 'package:climbicus/models/area.dart';
import 'package:climbicus/models/gym.dart';
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
import 'package:photo_view/photo_view.dart';

const GROUP_BY_AREAS = true;

const MAX_ROUTES_VISIBLE = 100;
const ROUTE_LIST_ITEM_HEIGHT = 80.0;


class HeaderListItem extends StatelessWidget {
  final RouteWithUserMeta routeWithUserMeta;
  final Widget image;

  const HeaderListItem({required this.routeWithUserMeta, required this.image});

  @override
  Widget build(BuildContext context) {
    UserRouteLog? mostRecentLog = routeWithUserMeta.mostRecentLog();

    Widget? routeNameText;
    if (this.routeWithUserMeta.route.name != null) {
      routeNameText = Text(this.routeWithUserMeta.route.name!, style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic));
    }
    Widget routeName = Container(
      padding: const EdgeInsets.only(left: 8.0),
      child: routeNameText,
    );

    return Padding(
      padding: const EdgeInsets.all(2),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Navigator.pushNamed(context, RouteDetailedPage.routeName,
            arguments: RouteDetailedArgs(this.routeWithUserMeta),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            routeName,
            Row(
              children: <Widget>[
                AscentWidget(mostRecentLog),
                Expanded(
                  child: Container(
                    height: ROUTE_LIST_ITEM_HEIGHT,
                    child: this.image,
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
      ),
    );
  }
}


class BodyListItem extends StatefulWidget {
  final RouteWithUserMeta routeWithUserMeta;
  final GymRoutesBloc gymRoutesBloc;
  final VoidCallback onAdd;

  const BodyListItem({required this.routeWithUserMeta, required this.gymRoutesBloc, required this.onAdd});

  @override
  _BodyListItemState createState() => _BodyListItemState();
}

class _BodyListItemState extends State<BodyListItem> {
  // TODO: use callbacks instead
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
      completed: checkboxSentKey.currentState!.value,
      numAttempts: numberAttemptsKey.currentState!.value,
    ));

    widget.gymRoutesBloc.add(AddOrUpdateUserRouteVotes(
      routeId: widget.routeWithUserMeta.route.id,
      userRouteVotesData: UserRouteVotesData(
        routeQualityKey.currentState!.value,
        routeDifficultyKey.currentState!.value,
      ),
    ));

    // Clear the fields.
    checkboxSentKey.currentState!.resetState();
    numberAttemptsKey.currentState!.resetState();
    routeQualityKey.currentState!.resetState();
    routeDifficultyKey.currentState!.resetState();
  }
}


class RouteViewPage extends StatefulWidget {
  final String routeCategory;
  final Gym gym;

  RouteViewPage({required this.routeCategory, required this.gym}) :
        super(key: ValueKey("${gym.id}-$routeCategory"));

  @override
  State<StatefulWidget> createState() => _RouteViewPageState();
}

class _RouteViewPageState extends State<RouteViewPage> with AutomaticKeepAliveClientMixin {
  // TODO: use callbacks instead
  final checkboxHideSentKey = GlobalKey<CheckboxWithTitleState>();
  final checkboxHideAttemptedKey = GlobalKey<CheckboxWithTitleState>();
  final sliderRouteGradesKey = GlobalKey<SliderRouteGradesState>();

  late RouteImagesBloc _routeImagesBloc;
  late GymAreasBloc _gymAreasBloc;
  late GymRoutesBloc _gymRoutesBloc;

  AreaItems _areaItems = AreaItems();

  @override
  void initState() {
    super.initState();

    _routeImagesBloc = BlocProvider.of<RouteImagesBloc>(context);
    _gymAreasBloc = BlocProvider.of<GymAreasBloc>(context);
    _gymRoutesBloc = BlocProvider.of<GymRoutesBloc>(context);

    _gymAreasBloc.add(FetchGymAreas());
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
              builder: (context, routesState) {
                if (routesState is GymRoutesLoaded) {
                  return BlocBuilder<GymAreasBloc, GymAreasState>(
                    builder: (context, areasState) {
                      if (areasState is GymAreasLoaded) {
                        return _buildLogbookGridWithRefresh(
                          areasState.areas,
                          routesState.entriesFiltered,
                        );
                      } else if (areasState is GymAreasError) {
                        return ErrorWidget.builder(areasState.errorDetails);
                      }
                      return Center(child: CircularProgressIndicator());
                    }
                  );
                } else if (routesState is GymRoutesError) {
                  return ErrorWidget.builder(routesState.errorDetails);
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
        final dynamic imageFile = await Navigator.pushNamed(
          context,
          CameraCustom.routeName,
        );
        if (imageFile == null) {
          return;
        }

        Navigator.pushNamed(context, RoutePredictionsPage.routeName,
          arguments: RoutePredictionsArgs(imageFile, widget.routeCategory),
        );
      },
      tooltip: "Add a new route",
      child: Icon(Icons.add_a_photo),
      heroTag: "camera-new-route-${widget.routeCategory}",
    );
  }

  Widget _buildRouteFilterTile() {
    return ExpansionTile(
      maintainState: true,
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
                      enabled: checkboxHideSentKey.currentState!.value,
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
                      enabled: checkboxHideAttemptedKey.currentState!.value,
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
              gradeValues: sliderRouteGradesKey.currentState!.values,
              category: widget.routeCategory,
            )
          ),
        ),
      ],
    );
  }

  Widget _buildLogbookGridWithRefresh(Map<int, Area> areas, RoutesWithUserMeta routes) {
    return RefreshIndicator(
      onRefresh: onRefreshView,
      child: _buildLogbookGrid(areas, routes),
    );
  }

  Widget _buildLogbookGrid(Map<int, Area> areas, RoutesWithUserMeta routes) {
    if (routes.isEmpty(widget.routeCategory)) {
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

    _areaItems.reset(areas);

    var categoryRoutes = routes.allRoutes(widget.routeCategory)!;

    var i = 0;
    (_sortEntriesByLogDate(categoryRoutes)).forEach((routeId, routeWithUserMeta) {
      if (++i > MAX_ROUTES_VISIBLE) {
        return;
      }

      var imageWidget = BlocBuilder<RouteImagesBloc, RouteImagesState>(
        builder: (context, state) {
          if (state is RouteImagesLoaded) {
            var routeImage = _routeImagesBloc.images.defaultImage(routeId);
            return RouteImageWidget(routeImage, thumbnail: true);
          } else {
            return Container(width: 0, height: 0);
          }
        },
      );

      var item = RouteListItem(
        routeWithUserMeta: routeWithUserMeta,
        image: imageWidget,
        isExpanded: _areaItems.isExpanded(routeId),
      );
      _areaItems.add(routeWithUserMeta.route.areaId, item);
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
        child: GROUP_BY_AREAS ?
            _areasExpansionList(scrollController) :
            _routesExpansionList(_areaItems.items, scrollController),
      ),
    );
  }

  Widget _areasExpansionList(ScrollController scrollController) {
    return ExpansionPanelList(
      expansionCallback: (int i, bool isExpanded) {
        setState(() {
          _areaItems.expand(i, isExpanded);
        });
      },
      children: _areaItems.itemsByArea.map((entry) {
        AreaItem areaItem = entry.value;

        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return _areaHeaderItem(areaItem);
          },
          body: _routesExpansionList(areaItem.routeItems, scrollController),
          isExpanded: areaItem.isExpanded,
          canTapOnHeader: true,
        );
      }).toList(),
    );
  }

  Widget _areaHeaderItem(AreaItem areaItem) {
    return Container(
      height: 100.0,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _areaImagePreview(areaItem),
          ),
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(4.0),
              child: Text(
                areaItem.area.name,
                style: TextStyle(fontSize: 18.0),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _areaImagePreview(AreaItem areaItem) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Container(
              alignment: Alignment.center,
              child: PhotoView(
                imageProvider: networkImageFromPath(areaItem.area.imagePath),
                tightMode: true,
                maxScale: 1.0,
              ),
            );
          },
        );
      },
      child: RouteImageWidget.fromPath(areaItem.area.thumbnailImagePath),
    );
  }

  Widget _routesExpansionList(List<RouteListItem> items, ScrollController scrollController) {
    return ExpansionPanelList(
      expansionCallback: (int i, bool isExpanded) {
        setState(() {
          items[i].isExpanded = !isExpanded;
        });
      },
      children: items.asMap().entries.map((entry) {
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
                items[idx].isExpanded = false;

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
    );
  }

  Future<void> onRefreshView() async {
    _gymAreasBloc.add(FetchGymAreas());
    _gymRoutesBloc.add(FetchGymRoutes());
  }

  // TODO: move elsewhere
  Map<int, RouteWithUserMeta> _sortEntriesByLogDate(Map<int, RouteWithUserMeta> routes) {
    var sortedKeys = routes.keys.toList(growable: false)
      ..sort((k1, k2) => routes[k2]!.mostRecentCreatedAt().compareTo(routes[k1]!.mostRecentCreatedAt()));

    return LinkedHashMap.fromIterable(sortedKeys, key: ((k) => k), value: ((k) => routes[k]!));
  }

  @override
  bool get wantKeepAlive => true;
}
