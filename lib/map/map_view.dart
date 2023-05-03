import 'package:fluffy_maps/map/map_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  MapOptions mapOptions = MapOptions();
  MapController mapController = MapController();
  FollowOnLocationUpdate followOnLocationUpdate = FollowOnLocationUpdate.always;
  TurnOnHeadingUpdate turnOnHeadingUpdate = TurnOnHeadingUpdate.always;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: mapOptions,
      mapController: mapController,
      children: [
        MapSettings.getTileLayerWidget(),
        CurrentLocationLayer(
          followOnLocationUpdate: followOnLocationUpdate,
          turnOnHeadingUpdate: turnOnHeadingUpdate,
        )
      ],
    );
  }
}
