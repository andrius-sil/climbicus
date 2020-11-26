import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/style.dart';
import 'package:climbicus/widgets/route_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RouteMatchPage extends StatefulWidget {
  final int selectedRouteId;
  final Widget selectedImage;
  final int takenRouteImageId;
  final Image takenImage;

  RouteMatchPage({
    this.selectedRouteId,
    this.selectedImage,
    this.takenRouteImageId,
    this.takenImage,
  });

  @override
  State<StatefulWidget> createState() => _RouteMatchPageState();
}

class _RouteMatchPageState extends State<RouteMatchPage> {
  static const double columnSize = 200.0;

  final checkboxSentKey = GlobalKey<CheckboxWithTitleState>();
  final numberAttemptsKey = GlobalKey<NumberAttemptsState>();
  final routeQualityKey = GlobalKey<RouteQualityRatingState>();
  final routeDifficultyKey = GlobalKey<RouteDifficultyRatingState>();

  RouteImagesBloc _routeImagesBloc;
  GymRoutesBloc _gymRoutesBloc;

  RouteWithUserMeta _routeWithUserMeta;

  @override
  void initState() {
    super.initState();

    _routeImagesBloc = BlocProvider.of<RouteImagesBloc>(context);
    _gymRoutesBloc = BlocProvider.of<GymRoutesBloc>(context);

    _routeImagesBloc.add(UpdateRouteImage(
      routeId: widget.selectedRouteId,
      routeImageId: widget.takenRouteImageId,
    ));

    _routeWithUserMeta = _gymRoutesBloc.getGymRoute(widget.selectedRouteId);
  }

  @override
  Widget build(BuildContext context) {
    var tiles = [
      Row(
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                Text("Your route:"),
                SizedBox(height: COLUMN_PADDING),
                Container(
                  height: columnSize,
                  width: columnSize,
                  child: widget.takenImage,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                Text("Selected route:"),
                SizedBox(height: COLUMN_PADDING),
                Container(
                  height: columnSize,
                  width: columnSize,
                  child: widget.selectedImage,
                ),
              ],
            ),
          ),
        ],
      ),
      Row(
        children: [
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
        child: Text('Add'),
        onPressed: _logAndNavigateBack,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your ascent'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tiles,
      ),
    );
  }

  void _logAndNavigateBack() {
    _gymRoutesBloc.add(AddNewUserRouteLog(
      routeId: widget.selectedRouteId,
      completed: checkboxSentKey.currentState.value,
      numAttempts: numberAttemptsKey.currentState.value,
    ));

    _gymRoutesBloc.add(AddOrUpdateUserRouteVotes(
      routeId: widget.selectedRouteId,
      userRouteVotesData: UserRouteVotesData(
        routeQualityKey.currentState.value,
        routeDifficultyKey.currentState.value,
      ),
    ));

    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
