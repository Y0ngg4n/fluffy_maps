import 'package:fluffy_maps/map/map_settings.dart';
import 'package:fluffy_maps/map/poi_manager.dart';
import 'package:fluffy_maps/map/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_floating_marker_titles/flutter_map_floating_marker_titles.dart';
import 'package:flutter_floating_map_marker_titles_core/controller/fmto_controller.dart';
import 'package:flutter_floating_map_marker_titles_core/model/floating_marker_title_info.dart';
import 'location_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapView extends ConsumerStatefulWidget {
  MapView({Key? key}) : super(key: key);

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  FollowOnLocationUpdate followOnLocationUpdate = FollowOnLocationUpdate.once;
  TurnOnHeadingUpdate turnOnHeadingUpdate = TurnOnHeadingUpdate.never;
  LocationManager locationManager = LocationManager();
  PoiManager poiManager = PoiManager();

  @override
  void initState() {
    super.initState();
    LocationManager().determinePosition();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => ref.read(poiProvider.notifier).getPois());
  }

  List<Marker> getPoiMarker(List<Poi> elements) {
    Poi? selectedPoi = ref.read(selectedPoiProvider.notifier).state;
    print(selectedPoi);
    return elements
        .map((e) => Marker(
              // Experimentation
              anchorPos: AnchorPos.exactly(Anchor(40, 30)),
              point: LatLng(e.poiElement.lat, e.poiElement.lon),
              width: 80,
              height: 80,
              builder: (ctx) => GestureDetector(
                onTap: () {
                  poiManager.showPoiDetails(e.poiElement, context);
                },
                child: Icon(
                  Icons.location_pin,
                  size: selectedPoi != null &&
                          e.poiElement.id == selectedPoi.poiElement.id
                      ? 40
                      : 25,
                  color: selectedPoi != null && e.poiElement.id == selectedPoi.poiElement.id
                      ? Colors.red
                      : Colors.black,
                ),
              ),
            ))
        .toList();
  }

  List<FloatingMarkerTitleInfo> getTitles(List<Poi> elements) {
    List<FloatingMarkerTitleInfo> titles = [];
    for (int i = 0; i < elements.length; i++) {
      var currentElement = elements[i];
      if (currentElement.poiElement.tags != null &&
          currentElement.poiElement.tags!.containsKey("name") &&
          currentElement.poiElement.tags!["name"] != null) {
        titles.add(FloatingMarkerTitleInfo(
            id: i,
            latLng: LatLng(
                currentElement.poiElement.lat, currentElement.poiElement.lon),
            title: currentElement.poiElement.tags!["name"],
            color: Colors.black));
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
            MarkerLayer(
              markers: getPoiMarker(pois),
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
                var position = await locationManager.determinePosition();
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
