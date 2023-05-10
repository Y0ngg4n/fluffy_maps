import 'dart:convert';

import 'package:fluffy_maps/map/api/nomatim.dart';
import 'package:fluffy_maps/map/api/poi_manager.dart';
import 'package:fluffy_maps/map/map_settings.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:point_in_polygon/point_in_polygon.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map_floating_marker_titles/flutter_map_floating_marker_titles.dart';
import 'package:flutter_floating_map_marker_titles_core/model/floating_marker_title_info.dart';


String overpassUrl = "https://overpass-api.de/api/interpreter";

class Overpass {

  static List<Poi> mapBuildingsToPoi(List<Building> buildings, List<Poi> pois) {
    for (Building building in buildings) {
      List<Point> bounds = building.boundaries
          .map((e) => Point(y: e.latitude, x: e.longitude))
          .toList();
      for (Poi poi in pois) {
        if (Poly.isPointInPolygon(
            Point(y: poi.poiElement.lat!, x: poi.poiElement.lon!), bounds)) {
          poi.building = building;
        }
      }
    }
    return pois;
  }

  static Future<OverpassResponse?> getAllPoiInRadius(
      int radius, LatLng position) async {
    String body = "[out:json][timeout:20][maxsize:536870912];";
    body += "node(around:$radius,${position.latitude}, ${position.longitude});";
    body += "out;";
    http.Response response = await http.post(Uri.parse(overpassUrl),
        headers: {"charset": "utf-8"}, body: body);
    if (response.statusCode == 200) {
      return OverpassResponse.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      return null;
    }
  }

  static Future<OverpassResponse?> getAmenityPoiInBounds(
      LatLngBounds? latLngBounds, LatLng position) async {
    if (latLngBounds == null) return null;
    String body = "[out:json][timeout:20][maxsize:536870912];";
    body +=
        "node[\"amenity\"](${latLngBounds.south}, ${latLngBounds.west},${latLngBounds.north}, ${latLngBounds.east});";
    body += "out;";
    http.Response response = await http.post(Uri.parse(overpassUrl),
        headers: {"charset": "utf-8"}, body: body);
    if (response.statusCode == 200) {
      return OverpassResponse.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      return null;
    }
  }

  static Future<OverpassResponse?> getBuildingBoundariesInBounds(
      LatLngBounds? latLngBounds, LatLng position) async {
    if (latLngBounds == null) return null;
    String body = "[out:json][timeout:20][maxsize:536870912];\n";
    body +=
        "way[\"building\"](${latLngBounds.south}, ${latLngBounds.west},${latLngBounds.north}, ${latLngBounds.east});";
    body += "(._;>;);out body;";
    http.Response response = await http.post(Uri.parse(overpassUrl),
        headers: {"charset": "utf-8"}, body: body);
    if (response.statusCode == 200) {
      return OverpassResponse.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      return null;
    }
  }
}

class Poi {
  PoiElement poiElement;
  FloatingMarkerTitleInfo title;
  List<String> images;
  NomatimLookupElement? nomatimLookupElement;
  Building? building;

  Poi(this.poiElement, this.title, this.images);
}

class Building {
  int id;
  List<LatLng> boundaries;

  Building(this.id, this.boundaries);
}

class OverpassResponse {
  double version;
  String generator;
  Map<String, dynamic> osm3s;
  List<PoiElement> elements;

  OverpassResponse(
      {required this.version,
      required this.generator,
      required this.osm3s,
      required this.elements});

  factory OverpassResponse.fromJson(Map<String, dynamic> json) {
    return OverpassResponse(
        version: json['version'],
        generator: json['generator'],
        osm3s: json['osm3s'],
        elements: json['elements']
            .map((e) => PoiElement.fromJson(e))
            .toList()
            .cast<PoiElement>());
  }
}