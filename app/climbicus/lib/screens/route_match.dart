import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/models/app/route_user_meta.dart';
import 'package:climbicus/style.dart';
import 'package:climbicus/widgets/route_image.dart';
import 'package:climbicus/widgets/route_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RouteMatchPage extends StatefulWidget {
  final int? selectedRouteId;
  final Widget selectedImage;
  final int takenRouteImageId;
  final RouteImageWidget takenImage;

  RouteMatchPage({
    this.selectedRouteId,
    required this.selectedImage,
    required this.takenRouteImageId,
    required this.takenImage,
  });

  @override
  State<StatefulWidget> createState() => _RouteMatchPageState();
}

class _RouteMatchPageState extends State<RouteMatchPage> {
  static const double columnSize = 200.0;

  // TODO: use callbacks instead
  final checkboxSentKey = GlobalKey<CheckboxWithTitleState>();
  final numberAttemptsKey = GlobalKey<NumberAttemptsState>();
  final routeQualityKey = GlobalKey<RouteQualityRatingState>();
  final routeDifficultyKey = GlobalKey<RouteDifficultyRatingState>();

  late RouteImagesBloc _routeImagesBloc;
  late GymRoutesBloc _gymRoutesBloc;

  @override
  void initState() {
    super.initState();

    _routeImagesBloc = BlocProvider.of<RouteImagesBloc>(context);
    _gymRoutesBloc = BlocProvider.of<GymRoutesBloc>(context);

    _routeImagesBloc.add(UpdateRouteImage(
      routeId: widget.selectedRouteId!,
      routeImageId: widget.takenRouteImageId,
    ));
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
        child: Text('Add'),
        onPressed: _logAndNavigateBack,
      ),
    ];

    var appBar = AppBar(
      title: const Text('Your ascent'),
    );

    return Scaffold(
      appBar: appBar,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: availableHeight(context, appBar)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: tiles,
          ),
        ),
      ),
    );
  }

  void _logAndNavigateBack() {
    _gymRoutesBloc.add(AddNewUserRouteLog(
      routeId: widget.selectedRouteId!,
      completed: checkboxSentKey.currentState!.value,
      numAttempts: numberAttemptsKey.currentState!.value,
    ));

    _gymRoutesBloc.add(AddOrUpdateUserRouteVotes(
      routeId: widget.selectedRouteId!,
      userRouteVotesData: UserRouteVotesData(
        routeQualityKey.currentState!.value,
        routeDifficultyKey.currentState!.value,
      ),
    ));

    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
