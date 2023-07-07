import 'dart:convert';

import 'package:fluffy_maps/map/views/navigation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import 'osrm.dart';

enum RoutingProfile {
  drivingCar,
  drivingHGV,
  cyclingRegular,
  cyclingRoad,
  cyclingMountain,
  cyclingSafety,
  cyclingTour,
  pedestrian,
  wheelchair,
}

extension RoutingProfileExtension on RoutingProfile {
  String get profileString {
    switch (this) {
      case RoutingProfile.drivingCar:
        return 'driving-car';
      case RoutingProfile.drivingHGV:
        return 'driving-hgv';
      case RoutingProfile.cyclingRegular:
        return 'cycling-regular';
      case RoutingProfile.cyclingRoad:
        return 'cycling-road';
      case RoutingProfile.cyclingMountain:
        return 'cycling-mountain';
      case RoutingProfile.cyclingSafety:
        return 'cycling-safety';
      case RoutingProfile.cyclingTour:
        return 'cycling-tour';
      case RoutingProfile.pedestrian:
        return 'foot-walking';
      case RoutingProfile.wheelchair:
        return 'wheelchair';
      default:
        return '';
    }
  }
}

class OpenRouteService {
  static const String API_URL =
      'https://api.openrouteservice.org/v2/directions';

  static Future<List<OpenRouteServiceRoute>?> route(
      List<LatLng> waypoints, RoutingProfile routingProfile) async {
    String API_KEY = dotenv.get("OPENROUTESERVICE_TOKEN");

    List<List<double>> coordinates = waypoints.map((waypoint) {
      return List<double>.of([waypoint.longitude, waypoint.latitude]);
    }).toList();

    Map<String, dynamic> requestBody = {
      'coordinates': coordinates,
    };

    // Send POST request to the API
    final response = await http.post(
      Uri.parse(
          '$API_URL/${routingProfile.profileString}/geojson?api_key=$API_KEY'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      GeoJSONFeatureCollection geoJSONFeatureCollection =
          GeoJSONFeatureCollection.fromJSON(response.body);
      List<OpenRouteServiceRoute> routes = [];
      List<LatLng> waypoints = [];
      for (GeoJSONFeature? geoJSONFeature
          in geoJSONFeatureCollection.features) {
        if (geoJSONFeature == null ||
            geoJSONFeature.geometry.toMap()["coordinates"] == null) {
          continue;
        }
        for (dynamic waypoint
            in geoJSONFeature.geometry.toMap()["coordinates"]) {
          waypoints.add(LatLng(waypoint[1], waypoint[0]));
        }
      }
      for (GeoJSONFeature? geoJSONFeature
          in geoJSONFeatureCollection.features) {
        if (geoJSONFeature == null || geoJSONFeature.properties == null) {
          continue;
        }
        int? transfers = geoJSONFeature.properties!["transfers"];
        int? fare = geoJSONFeature.properties!["fare"];
        List<Segment> segments = [];
        List<LatLng> route = [];
        for (dynamic segment in geoJSONFeature.properties!["segments"]) {
          double distance = segment["distance"];
          double duration = segment["distance"];
          List<Step> steps = [];
          for (dynamic step in segment["steps"]) {
            Step newStep = Step();
            double stepDistance = step["distance"];
            double stepDuration = step["distance"];
            int type = step["type"];
            String instruction = step["instruction"];
            String name = step["name"];
            List<int> waypointsIndexes = List<int>.from(step["way_points"]);
            List<LatLng> newWaypoints =
                waypointsIndexes.map((e) => waypoints[e]).toList();
            for (LatLng latLng in newWaypoints) {
              route.add(latLng);
            }
            newStep
              ..distance = stepDistance
              ..duration = stepDuration
              ..type = type
              ..name = name
              ..instruction = instruction
              ..waypoints = newWaypoints;
            steps.add(newStep);
          }
          Segment newSegment = Segment()
            ..duration = duration
            ..distance = distance
            ..steps = steps;
          segments.add(newSegment);
        }
        routes.add(OpenRouteServiceRoute(
            route: segments,
            breadCrumbs: increasePointDensity(route, routePointDensity),
            navigationDistancePoints:
                increasePointDensity(route, routePointDensity)));
      }
      return routes;
    }
    // Return an null if there was an error or no route found
    return null;
  }
}
