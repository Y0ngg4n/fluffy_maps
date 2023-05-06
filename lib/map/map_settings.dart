import 'package:fluffy_maps/map/poi_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_floating_marker_titles/flutter_map_floating_marker_titles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_floating_marker_titles/flutter_map_floating_marker_titles.dart';
import 'package:flutter_floating_map_marker_titles_core/controller/fmto_controller.dart';
import 'package:flutter_floating_map_marker_titles_core/model/floating_marker_title_info.dart';

import 'location_manager.dart';

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

  static getMapOptions(WidgetRef ref) {
    return MapOptions(maxZoom: 19, minZoom: 0, onPointerUp: (event, point) {
      ref.read(poiProvider.notifier).getPois();
    },);
  }
}

class Poi {
  PoiElement poiElement;
  FloatingMarkerTitleInfo title;
  List<String> images;

  Poi(this.poiElement, this.title, this.images);
}

class PoiNotifier extends StateNotifier<List<Poi>> {
  PoiNotifier() : super([]);
  PoiManager poiManager = PoiManager();

  void init(){
    state = [];
  }

  Future<void> getPois() async {
    if(MapSettings.mapController.zoom < 18) {
      state = [];
      return;
    }
    var position = await LocationManager().determinePosition();
    OverpassResponse? overpassResponse = await poiManager.getAllPoiInBounds(
        MapSettings.mapController.bounds, LatLng(position.latitude, position.longitude));
    if (overpassResponse != null) {
      List<Poi> pois = [];
      int titleId = 0;
      for (PoiElement element in overpassResponse.elements.where((element) =>
          element.tags != null && element.tags!.containsKey("name"))) {
        List<String> images = await poiManager.getImages(element.tags!);
        pois.add(Poi(
            element,
            FloatingMarkerTitleInfo(
                id: titleId, title: element.tags!["name"] ?? "",
                latLng: LatLng(element.lat, element.lon), color: Colors.black
            ),
            images));
        titleId++;
      }
      state = pois;
    }
  }
}

class SelectedPoiNotifier extends StateNotifier<Poi?> {
  SelectedPoiNotifier() : super(null);

  set(Poi? poi){
    state = poi;
  }
}

final poiProvider = StateNotifierProvider<PoiNotifier, List<Poi>>((ref) {
  return PoiNotifier();
});

final selectedPoiProvider = StateNotifierProvider<SelectedPoiNotifier, Poi?>((ref) => SelectedPoiNotifier());
