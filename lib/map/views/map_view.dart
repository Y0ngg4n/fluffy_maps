import 'dart:async';

import 'package:fluffy_maps/map/api/osrm.dart';
import 'package:fluffy_maps/map/map_items.dart';
import 'package:fluffy_maps/map/map_settings.dart';
import 'package:fluffy_maps/map/api/poi_manager.dart';
import 'package:fluffy_maps/map/views/navigation.dart';
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
import 'package:flutter_map_directions/flutter_map_directions.dart' as directions;

import '../api/overpass.dart';

GlobalKey<MapViewState> mapKey = GlobalKey();

class MapView extends ConsumerStatefulWidget {
  MapView({Key? key}) : super(key: key);

  @override
  ConsumerState<MapView> createState() => MapViewState();
}

class MapViewState extends ConsumerState<MapView> {
  FollowOnLocationUpdate followOnLocationUpdate = FollowOnLocationUpdate.once;
  TurnOnHeadingUpdate turnOnHeadingUpdate = TurnOnHeadingUpdate.never;
  LocationManager locationManager = LocationManager();

  Stream<Position> positionStream = Geolocator.getPositionStream(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.bestForNavigation));
  StreamSubscription<Position>? positionStreamSubscribtion = null;
  bool showNavigationStart = false;

  @override
  void initState() {
    super.initState();
    LocationManager().determinePosition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(poiProvider.notifier).getPois();
      ref.read(buildingProvider.notifier).getBuildingBoundaries();
      ref.read(poiProvider.notifier).set(Overpass.mapBuildingsToPoi(
          ref.read(buildingProvider.notifier).getState(),
          ref.read(poiProvider.notifier).getState()));
    });
  }

  void setShowNavigationStart(bool value) {
    setState(() {
      showNavigationStart = value;
    });
  }

  void startListeningForLocationChange() {
    if (positionStreamSubscribtion != null &&
        !positionStreamSubscribtion!.isPaused) return;
    setState(() {
      positionStreamSubscribtion = positionStream.listen((event) {
        OSRMRoute route = ref.read(routeProvider.notifier).getState();
        List<LatLng> newRoute = List.from(route.route);
        List<LatLng> newBreadCrumbs = List.from(route.breadCrumbs);
        List<LatLng> newNavigationDistancePoints =
            List.from(route.navigationDistancePoints);
        if (route.route.isNotEmpty) {
          for (int i = 0; i < route.route.length; i++) {
            double distance = const Distance().as(LengthUnit.Meter,
                LatLng(event.latitude, event.longitude), route.route[i]);
            if (distance < routePointDensity) {
              newRoute.removeRange(0, i + 1);
            }
          }
        }
        if (route.breadCrumbs.isNotEmpty) {
          for (int i = 0; i < route.breadCrumbs.length; i++) {
            double distance = const Distance().as(LengthUnit.Meter,
                LatLng(event.latitude, event.longitude), route.breadCrumbs[i]);
            if (distance < routePointDensity) {
              newBreadCrumbs.removeRange(0, i + 1);
            }
          }
        }
        if (route.navigationDistancePoints.isNotEmpty) {
          for (int i = 0; i < route.navigationDistancePoints.length; i++) {
            double distance = const Distance().as(
                LengthUnit.Meter,
                LatLng(event.latitude, event.longitude),
                route.navigationDistancePoints[i]);
            if (distance < navigationPointDensity) {
              newNavigationDistancePoints.removeRange(0, i + 1);
            }
          }
        }
        ref.read(routeProvider.notifier).set(OSRMRoute(
            start: route.start,
            end: route.end,
            route: newRoute,
            breadCrumbs: newBreadCrumbs,
            navigationDistancePoints: newNavigationDistancePoints));
        setState(() {});
      });
    });
  }

  void update() {
    ref.read(poiProvider.notifier).getPois();
    ref.read(buildingProvider.notifier).getBuildingBoundaries();
    ref.read(poiProvider.notifier).set(Overpass.mapBuildingsToPoi(
        ref.read(buildingProvider.notifier).getState(),
        ref.read(poiProvider.notifier).getState()));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              FlutterMapWithFMTO(
                floatingTitles: MapItems.getTitles(context, ref),
                options: MapOptions(
                  maxZoom: 19,
                  minZoom: 0,
                  onMapReady: () {
                    MapSettings.mapController
                        .move(MapSettings.mapController.center, 19);
                    update();
                  },
                  onPointerUp: (event, point) => update(),
                ),
                mapController: MapSettings.mapController,
                fmtoOptions: FMTOOptions(),
                children: [
                  MapSettings.getTileLayerWidget(),
                  CurrentLocationLayer(
                    followOnLocationUpdate: followOnLocationUpdate,
                    turnOnHeadingUpdate: turnOnHeadingUpdate,
                  ),
                  PolygonLayer(
                    polygons: MapItems.getPolygons(context, ref),
                  ),
                  PolylineLayer(
                    polylines: MapItems.getPolylines(context, ref),
                  ),
                  directions.DirectionsLayer(coordinates: [directions.LatLng(0, 0), directions.LatLng(10, 10)], strokeWidth: 100, onCompleted: (isRouteAvailable) {
                    print("Route available");
                  },),
                  MarkerLayer(
                    markers:
                        MapItems.getPoiMarker(context, ref, positionStream),
                  ),
                ],
              ),
              Positioned(
                  bottom: 10,
                  right: 10,
                  child: FloatingActionButton(
                    heroTag: "myLocation",
                    child: const Icon(Icons.my_location),
                    onPressed: () async {
                      Position? position =
                          await locationManager.determinePosition();
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
                        builder: (context) => SearchView(
                          stream: positionStream,
                        ),
                      ));
                    },
                  ))
            ],
          ),
        ),
        Visibility(
            visible: showNavigationStart,
            child: Expanded(
                flex: 1,
                child: NavigationStart(positionStream: positionStream)))
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
