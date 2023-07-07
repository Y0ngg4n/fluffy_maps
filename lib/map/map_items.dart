import 'dart:async';
import 'dart:math';

import 'package:fluffy_maps/map/views/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_floating_map_marker_titles_core/model/floating_marker_title_info.dart';
import 'api/overpass.dart';
import 'api/poi_manager.dart';
import 'map_settings.dart';
import 'package:flutter_map_directions/flutter_map_directions.dart'
    as directions;

class MapItems {
  static List<Marker> getPoiMarker(
      BuildContext context, WidgetRef ref, Stream<Position>? stream) {
    List<Poi> pois = ref.read(poiProvider.notifier).getState();
    Poi? selectedPoi = ref.read(selectedPoiProvider.notifier).getState();
    List<OpenRouteServiceRoute> routes =
        ref.read(openRouteServiceRoutesRouteProvider.notifier).getState();
    List<Marker> marker = pois
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
                  PoiManager.showPoiDetails(e, context, ref, stream);
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
    List<LatLng> edgepointMarkerLocations = [];
    for (OpenRouteServiceRoute route in routes) {
      for(int z = 0; z < route.route.length; z++) {
        for (int i = 0; i < route.route[z].steps!.length - 1; i++) {
          var current = route.route[z].steps![i];
          var next = route.route[z].steps![i + 1];
          edgepointMarkerLocations.add(current.waypoints!.first);
          marker.add(Marker(
            point: current.waypoints!.first,
            builder: (context) {
              return Transform.rotate(
                  angle: calculateAngle(current.waypoints!.first,
                      next.waypoints!.first),
                  child: const Icon(Icons.arrow_circle_up_outlined,
                      color: Colors.black));
            },
          ));
        }
      }
      if (route.breadCrumbs.isNotEmpty) {
        for (int i = 0; i < route.breadCrumbs.length - 1; i++) {
          LatLng current = route.breadCrumbs[i];
          LatLng next = route.breadCrumbs[i + 1];
          
          if (edgepointMarkerLocations.contains(current)) continue;
          marker.add(Marker(
            point: current,
            builder: (context) {
              return Transform.rotate(
                  angle: calculateAngle(current, next),
                  child: const Icon(Icons.arrow_drop_up, color: Colors.blue));
            },
          ));
        }
      }
      if (route.route.isNotEmpty) {
        marker.add(Marker(
          point: route.route.last.steps!.last.waypoints!.last,
          builder: (context) => const Icon(Icons.flag),
          anchorPos: AnchorPos.exactly(Anchor(21, 5)),
        ));
      }
    }
    return marker;
  }

  static List<Polyline> getPolylines(BuildContext context, WidgetRef ref) {
    List<OpenRouteServiceRoute> routes =
        ref.read(openRouteServiceRoutesRouteProvider.notifier).getState();
    List<Polyline> polylines = [];
    for (OpenRouteServiceRoute route in routes) {
      Polyline polyline = Polyline(
          points: route.breadCrumbs,
          color: Color.fromRGBO(
              Colors.blue.red, Colors.blue.green, Colors.blue.blue, 0.5),
          strokeWidth: 10,
          strokeJoin: StrokeJoin.bevel);
      polylines.add(polyline);
    }
    return polylines;
  }

  static List<directions.LatLng> getDirections(WidgetRef ref) {
    OSRMRoute route = ref.read(osrmRouteProvider.notifier).getState();
    if (route.route.isEmpty) return [];
    return route.route
        .map((e) => directions.LatLng(e.latitude, e.longitude))
        .toList();
  }

  static List<Polygon> getPolygons(BuildContext context, WidgetRef ref) {
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
    return polys;
  }

  static List<FloatingMarkerTitleInfo> getTitles(
      BuildContext context, WidgetRef ref) {
    List<Poi>? pois = ref.read(poiProvider.notifier).getState();
    Poi? selectedPoi = ref.read(selectedPoiProvider.notifier).getState();
    if (pois == null) return [];
    List<FloatingMarkerTitleInfo> titles = [];
    for (int i = 0; i < pois.length; i++) {
      var currentElement = pois[i];
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

  static double calculateAngle(LatLng point1, LatLng point2) {
    final double deltaLon = point2.longitude - point1.longitude;
    final double y = sin(deltaLon * pi / 180) * cos(point2.latitude * pi / 180);
    final double x =
        cos(point1.latitude * pi / 180) * sin(point2.latitude * pi / 180) -
            sin(point1.latitude * pi / 180) *
                cos(point2.latitude * pi / 180) *
                cos(deltaLon * pi / 180);
    final double angleInRadians = atan2(y, x);
    // final double angleInDegrees = angleInRadians * (180 / pi);
    return angleInRadians;
  }
}
