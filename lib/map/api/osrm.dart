import 'dart:math';

import 'package:georouter/georouter.dart';
import 'package:latlong2/latlong.dart';
import '../map_settings.dart';
import '../views/navigation.dart';

double routePointDensity = 5;
double navigationPointDensity = 1;

class OSRM {
  static Future<OSRMRoute?> route(
      TravelMode travelMode, LatLng start, LatLng end) async {
    final georouter = GeoRouter(mode: travelMode);
    List<PolylinePoint> coordinates = [
      PolylinePoint(latitude: start.latitude, longitude: start.longitude),
      PolylinePoint(latitude: end.latitude, longitude: end.longitude)
    ];
    try {
      List<PolylinePoint> directions =
          await georouter.getDirectionsBetweenPoints(coordinates);
      print("Got route!");
      List<LatLng> route =
          directions.map((e) => LatLng(e.latitude, e.longitude)).toList();
      return OSRMRoute(
          start: start,
          end: end,
          route: route,
          breadCrumbs: increasePointDensity(route, routePointDensity),
          navigationDistancePoints:
              increasePointDensity(route, navigationPointDensity));
    } on GeoRouterException catch (e) {
      print("Cant route to this point");
    } on HttpException catch (e) {
      print("Cant request osrm");
    }
    return null;
  }

  static List<LatLng> increasePointDensity(
      List<LatLng> originalPoints, double distanceInterval) {
    List<LatLng> increasedPoints = [];

    for (var i = 0; i < originalPoints.length - 1; i++) {
      LatLng startPoint = originalPoints[i];
      LatLng endPoint = originalPoints[i + 1];

      double distance =
          const Distance().as(LengthUnit.Meter, startPoint, endPoint);
      int numPointsToAdd = (distance / distanceInterval).floor();

      increasedPoints.add(startPoint);

      double latStep =
          (endPoint.latitude - startPoint.latitude) / numPointsToAdd;
      double lonStep =
          (endPoint.longitude - startPoint.longitude) / numPointsToAdd;

      for (var j = 1; j <= numPointsToAdd; j++) {
        double interpolatedLat = startPoint.latitude + (latStep * j);
        double interpolatedLon = startPoint.longitude + (lonStep * j);
        LatLng interpolatedPoint = LatLng(interpolatedLat, interpolatedLon);
        increasedPoints.add(interpolatedPoint);
      }
    }

    increasedPoints.add(originalPoints.last);

    return increasedPoints;
  }

  static double getDistanceOfRoute(LengthUnit unit, List<LatLng> points) {
    double distance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      distance += const Distance().as(unit, points[i], points[i + 1]);
    }
    return distance;
  }
}
