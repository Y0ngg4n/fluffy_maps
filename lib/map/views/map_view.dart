import 'package:fluffy_maps/map/map_settings.dart';
import 'package:fluffy_maps/map/api/poi_manager.dart';
import 'package:fluffy_maps/map/views/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_floating_marker_titles/flutter_map_floating_marker_titles.dart';
import 'package:flutter_floating_map_marker_titles_core/controller/fmto_controller.dart';
import 'package:flutter_floating_map_marker_titles_core/model/floating_marker_title_info.dart';
import '../api/location_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/overpass.dart';

class MapView extends ConsumerStatefulWidget {
  MapView({Key? key}) : super(key: key);

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  FollowOnLocationUpdate followOnLocationUpdate = FollowOnLocationUpdate.once;
  TurnOnHeadingUpdate turnOnHeadingUpdate = TurnOnHeadingUpdate.never;
  LocationManager locationManager = LocationManager();
  List<Polygon> polygons = [];

  @override
  void initState() {
    super.initState();
    LocationManager().determinePosition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MapSettings.mapController.move(MapSettings.mapController.center, 19);
      ref.read(poiProvider.notifier).getPois();
      ref.read(buildingProvider.notifier).getBuildingBoundaries();
      ref.read(poiProvider.notifier).set(Overpass.mapBuildingsToPoi(
          ref.read(buildingProvider.notifier).getState(),
          ref.read(poiProvider.notifier).getState()));
    });
  }

  List<Marker> getPoiMarker(List<Poi> elements) {
    Poi? selectedPoi = ref.read(selectedPoiProvider.notifier).getState();
    return elements
        .map((e) => Marker(
              // Experimentation
              anchorPos: AnchorPos.exactly(Anchor(40, 30)),
              point: LatLng(e.poiElement.lat!, e.poiElement.lon!),
              width: 80,
              height: 80,
              builder: (ctx) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  ref.read(selectedPoiProvider.notifier).set(e);
                  getPolygons();
                  PoiManager.showPoiDetails(e, context);
                },
                child: Icon(
                  Icons.location_pin,
                  size: selectedPoi != null &&
                          e.poiElement.id == selectedPoi.poiElement.id
                      ? 40
                      : 25,
                  color: selectedPoi != null &&
                          e.poiElement.id == selectedPoi.poiElement.id
                      ? Colors.red
                      : Colors.black,
                ),
              ),
            ))
        .toList();
  }

  List<Polyline> getPolylines() {
    List<Polyline> polylines = [];
    return polylines;
  }

  getPolygons() {
    Poi? selectedPoi = ref.read(selectedPoiProvider.notifier).getState();
    List<Building> buildings = ref.read(buildingProvider.notifier).getState();
    List<Polygon> polys = [];
    for (Building building in buildings) {
      bool isSelected = selectedPoi != null &&
          selectedPoi.building != null &&
          selectedPoi.building!.id == building.id;
      polys.add(Polygon(
          points: building.boundaries,
          isFilled: isSelected,
          color: Color.fromRGBO(Colors.orangeAccent.red,
              Colors.orangeAccent.green, Colors.orangeAccent.blue, 0.25),
          borderColor: Colors.orange,
          borderStrokeWidth: isSelected ? 2 : 0));
    }
    setState(() {
      polygons = polys;
    });
  }

  List<FloatingMarkerTitleInfo> getTitles(List<Poi> elements) {
    Poi? selectedPoi = ref.read(selectedPoiProvider.notifier).getState();
    List<FloatingMarkerTitleInfo> titles = [];
    for (int i = 0; i < elements.length; i++) {
      var currentElement = elements[i];
      if (currentElement.poiElement.tags != null &&
          currentElement.poiElement.tags!.containsKey("name") &&
          currentElement.poiElement.tags!["name"] != null) {
        titles.add(FloatingMarkerTitleInfo(
            id: i,
            latLng: LatLng(
                currentElement.poiElement.lat!, currentElement.poiElement.lon!),
            title: currentElement.poiElement.tags!["name"]!,
            color: (selectedPoi != null &&
                    selectedPoi.poiElement.id == currentElement.poiElement.id)
                ? Colors.red
                : Colors.black));
      }
    }
    return titles;
  }

  @override
  Widget build(BuildContext context) {
    List<Poi> pois = ref.watch(poiProvider);
    return Stack(
      children: [
        FlutterMapWithFMTO(
          floatingTitles: getTitles(pois),
          options: MapSettings.getMapOptions(ref),
          mapController: MapSettings.mapController,
          fmtoOptions: FMTOOptions(),
          children: [
            MapSettings.getTileLayerWidget(),
            CurrentLocationLayer(
              followOnLocationUpdate: followOnLocationUpdate,
              turnOnHeadingUpdate: turnOnHeadingUpdate,
            ),
            PolygonLayer(
              polygons: polygons,
            ),
            MarkerLayer(
              markers: getPoiMarker(pois),
            ),
            PolylineLayer(
              polylines: getPolylines(),
              polylineCulling: true,
            )
          ],
        ),
        Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton(
              heroTag: "myLocation",
              child: const Icon(Icons.my_location),
              onPressed: () async {
                Position? position = await locationManager.determinePosition();
                if (position == null) return;
                MapSettings.mapController.move(
                    LatLng(position.latitude, position.longitude),
                    MapSettings.mapController.zoom);
              },
            )),
        Positioned(
            top: 10,
            left: 10,
            child: FloatingActionButton(
              heroTag: "Search",
              child: const Icon(Icons.search),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SearchView(),
                ));
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
        children: [Text(poiElement.tags!["name"]!)],
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
