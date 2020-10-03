
import 'dart:collection';

import 'package:climbicus/blocs/gyms_bloc.dart';
import 'package:climbicus/blocs/settings_bloc.dart';
import 'package:climbicus/models/gym.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GymsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _GymsPageState();

}

class _GymsPageState extends State<GymsPage> {
  GymsBloc _gymsBloc;
  SettingsBloc _settingsBloc;

  @override
  void initState() {
    super.initState();

    _gymsBloc = BlocProvider.of<GymsBloc>(context);
    _settingsBloc = BlocProvider.of<SettingsBloc>(context);

    _gymsBloc.add(FetchGyms());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select your gym'),
      ),
      body: BlocBuilder<GymsBloc, GymsState>(
        builder: (context, state) {
          if (state is GymsLoaded) {
            return _buildGymsList(state.gyms);
          } else if (state is GymsError) {
            return ErrorWidget.builder(state.errorDetails);
          }

          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildGymsList(Map<int, Gym> gyms) {
    List<Widget> gymTiles = [];
    _sortGymsByName(gyms).forEach((int gymId, Gym gym) {
      gymTiles.add(
        GestureDetector(
          child: ListTile(title: Text(gym.name)),
          onTap: () {
            _settingsBloc.add(GymChanged(gymId: gym.id));

            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        )
      );
    });

    return Scrollbar(
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: gymTiles.length,
        itemBuilder: (context, index) => gymTiles[index],
        separatorBuilder: (context, index) => Divider(),
      )
    );
  }

  Map<int, Gym> _sortGymsByName(Map<int, Gym> gyms) {
    var sortedKeys = gyms.keys.toList(growable: false)
      ..sort((k1, k2) => gyms[k1].name.compareTo(gyms[k2].name));

    return LinkedHashMap.fromIterable(sortedKeys,
        key: (k) => k, value: (k) => gyms[k]);
  }
}