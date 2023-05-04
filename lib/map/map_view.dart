import 'package:fluffy_maps/map/map_settings.dart';
import 'package:fluffy_maps/map/poi_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_floating_marker_titles/flutter_map_floating_marker_titles.dart';
import 'package:flutter_floating_map_marker_titles_core/controller/fmto_controller.dart';
import 'package:flutter_floating_map_marker_titles_core/model/floating_marker_title_info.dart';
import 'location_manager.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  FMTOMapController mapController = FMTOMapController();
  FollowOnLocationUpdate followOnLocationUpdate = FollowOnLocationUpdate.once;
  TurnOnHeadingUpdate turnOnHeadingUpdate = TurnOnHeadingUpdate.once;
  LocationManager locationManager = LocationManager();
  PoiManager poiManager = PoiManager();
  List<PoiElement> poiElements = [];
  final List<FloatingMarkerTitleInfo> floatingTitles = [];

  @override
  void initState() {
    super.initState();
    LocationManager().determinePosition();
    getPois();
  }

  void getPois() async {
    var position = await LocationManager().determinePosition();
    OverpassResponse? overpassResponse = await poiManager.getAllPoiInRadius(100, LatLng(position.latitude, position.longitude));
    if (overpassResponse != null) {
      setState(() {
        poiElements = overpassResponse.elements
            .where((element) =>
                element.tags != null && element.tags!.containsKey("name"))
            .toList();
      });
    }
  }

  List<Marker> getPoiMarker() {
    return poiElements
        .map((e) => Marker(
              // Experimentation
              anchorPos: AnchorPos.exactly(Anchor(40, 30)),
              point: LatLng(e.lat, e.lon),
              width: 80,
              height: 80,
              builder: (ctx) => GestureDetector(
                onTap: () {
                  poiManager.showPoiDetails(e, context);
                },
                child: Icon(
                  Icons.location_pin,
                  size: 25,
                ),
              ),
            ))
        .toList();
  }

  List<FloatingMarkerTitleInfo> getTitles() {
    List<FloatingMarkerTitleInfo> titles = [];
    for (int i = 0; i < poiElements.length; i++) {
      var currentElement = poiElements[i];
      if (currentElement.tags != null &&
          currentElement.tags!.containsKey("name") &&
          currentElement.tags!["name"] != null) {
        titles.add(FloatingMarkerTitleInfo(
            id: i,
            latLng: LatLng(currentElement.lat, currentElement.lon),
            title: currentElement.tags!["name"],
            color: Colors.black));
      }
    }
    return titles;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMapWithFMTO(
          floatingTitles: getTitles(),
          options: MapSettings.getMapOptions(),
          mapController: mapController,
          fmtoOptions: FMTOOptions(),
          children: [
            MapSettings.getTileLayerWidget(),
            CurrentLocationLayer(
              followOnLocationUpdate: followOnLocationUpdate,
              turnOnHeadingUpdate: turnOnHeadingUpdate,
            ),
            MarkerLayer(
              markers: getPoiMarker(),
            )
          ],
        ),
        Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton(
              child: const Icon(Icons.my_location),
              onPressed: () async {
                var position = await locationManager.determinePosition();
                mapController.move(
                    LatLng(position.latitude, position.longitude),
                    mapController.zoom);
              },
            ))
      ],
    );
  }
}

class PoiSliverAppBar extends SliverPersistentHeaderDelegate {
  PoiElement poiElement;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.red,
      child: Column(
        children: [Text(poiElement.tags!["name"])],
      ),
    );
  }

  @override
  double get maxExtent => 150;

  @override
  double get minExtent => 100;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;

  PoiSliverAppBar({required this.poiElement});
}
