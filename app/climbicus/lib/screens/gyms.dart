
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
    gyms.forEach((int gymId, Gym gym) {
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

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: gymTiles.length,
      itemBuilder: (context, index) => gymTiles[index],
      separatorBuilder: (context, index) => Divider(
      ),
    );
  }

}