import 'package:fluffy_maps/map/api/metadata_manager.dart';
import 'package:fluffy_maps/map/api/openrouteservice.dart';
import 'package:fluffy_maps/map/api/poi_manager.dart';
import 'package:fluffy_maps/map/views/map_view.dart';
import 'package:fluffy_maps/map/views/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_floating_marker_titles/flutter_map_floating_marker_titles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:georouter/georouter.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_floating_marker_titles/flutter_map_floating_marker_titles.dart';
import 'package:flutter_floating_map_marker_titles_core/controller/fmto_controller.dart';
import 'package:flutter_floating_map_marker_titles_core/model/floating_marker_title_info.dart';

import 'api/location_manager.dart';
import 'api/nomatim.dart';
import 'api/overpass.dart';

class MapSettings {
  static FMTOMapController mapController = FMTOMapController();

  static getTileLayerWidget() {
    return TileLayer(
      maxZoom: 19,
      minZoom: 0,
      userAgentPackageName: "pro.obco.fluffy_maps",
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c'],
    );
  }
}

class PoiNotifier extends StateNotifier<List<Poi>> {
  PoiNotifier() : super([]);

  void init() {
    state = [];
  }

  Future<void> getPois() async {
    if (MapSettings.mapController.zoom < 18) {
      state = [];
      return;
    }
    var position = await LocationManager().determinePosition();
    if (position == null) return;
    OverpassResponse? overpassResponse = await Overpass.getAmenityPoiInBounds(
        MapSettings.mapController.bounds,
        LatLng(position.latitude, position.longitude));
    if (overpassResponse != null) {
      List<Poi> pois = [];
      List<int> osmIds = [];
      int titleId = 0;
      for (PoiElement element in overpassResponse.elements.where((element) =>
          element.tags != null && element.tags!.containsKey("name"))) {
        List<String> images = await MetadataManager.getImages(element.tags!);
        pois.add(Poi(
            element,
            FloatingMarkerTitleInfo(
                id: titleId,
                title: element.tags!["name"] ?? "",
                latLng: LatLng(element.lat!, element.lon!),
                color: Colors.black),
            images));
        osmIds.add(element.id);
        titleId++;
      }
      state = pois;
    }
  }

  void set(List<Poi> pois) {
    state = pois;
  }

  getState() => state;
}

class OSRMRouteNotifier extends StateNotifier<OSRMRoute> {
  OSRMRouteNotifier()
      : super(OSRMRoute(
            route: [], breadCrumbs: [], navigationDistancePoints: []));

  void init() {
    state = OSRMRoute(route: [], breadCrumbs: [], navigationDistancePoints: []);
  }

  void set(OSRMRoute osrmRoute) {
    state = osrmRoute;
  }

  getState() => state;
}

class OpenRouteServiceRouteNotifier
    extends StateNotifier<List<OpenRouteServiceRoute>> {
  OpenRouteServiceRouteNotifier() : super([]);

  void init() {
    state = [];
  }

  void set(List<OpenRouteServiceRoute> openRouteServiceRoutes) {
    state = openRouteServiceRoutes;
  }

  getState() => state;
}

class BuildingNotifier extends StateNotifier<List<Building>> {
  BuildingNotifier() : super([]);
  PoiManager poiManager = PoiManager();

  void init() {
    state = [];
  }

  Future<void> getBuildingBoundaries() async {
    if (MapSettings.mapController.zoom < 18) {
      state = [];
      return;
    }
    var position = await LocationManager().determinePosition();
    if (position == null) return;
    OverpassResponse? overpassResponse =
        await Overpass.getBuildingBoundariesInBounds(
            MapSettings.mapController.bounds,
            LatLng(position.latitude, position.longitude));
    if (overpassResponse != null) {
      List<Building> buildings = [];
      for (PoiElement building in overpassResponse.elements
          .where((element) => element.type == "way")) {
        List<LatLng> bounds = [];
        if (building.nodes != null) {
          for (int node in building.nodes!) {
            bounds.addAll(overpassResponse.elements
                .where((element) => element.id == node)
                .map((e) => LatLng(e.lat!, e.lon!))
                .toList());
          }
        }
        buildings.add(Building(building.id, bounds));
      }
      state = buildings;
    }
  }

  getState() => state;
}

class SelectedPoiNotifier extends StateNotifier<Poi?> {
  SelectedPoiNotifier() : super(null);

  set(Poi? poi) {
    state = poi;
  }

  getState() => state;
}

class TravelModeNotifier extends StateNotifier<TravelMode> {
  TravelModeNotifier() : super(TravelMode.walking);

  set(TravelMode travelMode) {
    state = travelMode;
  }

  getState() => state;
}

class RoutingProfileNotifier extends StateNotifier<RoutingProfile> {
  RoutingProfileNotifier() : super(RoutingProfile.pedestrian);

  set(RoutingProfile routingProfile) {
    state = routingProfile;
  }

  getState() => state;
}

final poiProvider = StateNotifierProvider<PoiNotifier, List<Poi>>((ref) {
  return PoiNotifier();
});

final osrmRouteProvider =
    StateNotifierProvider<OSRMRouteNotifier, OSRMRoute>((ref) {
  return OSRMRouteNotifier();
});

final openRouteServiceRoutesRouteProvider = StateNotifierProvider<
    OpenRouteServiceRouteNotifier, List<OpenRouteServiceRoute>>((ref) {
  return OpenRouteServiceRouteNotifier();
});

final buildingProvider =
    StateNotifierProvider<BuildingNotifier, List<Building>>((ref) {
  return BuildingNotifier();
});

final selectedPoiProvider = StateNotifierProvider<SelectedPoiNotifier, Poi?>(
    (ref) => SelectedPoiNotifier());

final travelModeProvider =
    StateNotifierProvider<TravelModeNotifier, TravelMode>(
        (ref) => TravelModeNotifier());

final routingProfileProvider =
    StateNotifierProvider<RoutingProfileNotifier, RoutingProfile>(
        (ref) => RoutingProfileNotifier());
