import 'package:easy_debounce/easy_debounce.dart';
import 'package:fluffy_maps/map/api/nomatim.dart';
import 'package:fluffy_maps/map/map_settings.dart';
import 'package:fluffy_maps/map/api/poi_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../api/location_manager.dart';
import '../api/overpass.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  TextEditingController textEditingController = TextEditingController();
  NomatimResponse? nomatimSearch;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Search"),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                decoration: new InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(50))),
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search ...',
                ),
                controller: textEditingController,
                onEditingComplete: () {
                  setState(() {
                    EasyDebounce.debounce("search", Duration(seconds: 1), () {
                      Future.delayed(
                        const Duration(seconds: 1),
                        () async {
                          Position? position =
                              await LocationManager().determinePosition();
                          NomatimResponse? response =
                              await Nomatim.searchNomatim(
                                  position, textEditingController.text);
                          setState(() {
                            nomatimSearch = response;
                          });
                        },
                      );
                    });
                  });
                },
              ),
            ),
            nomatimSearch == null && textEditingController.text.isNotEmpty
                ? CircularProgressIndicator()
                : (nomatimSearch == null || textEditingController.text.isEmpty
                    ? Container()
                    : Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (SearchElement element
                                in nomatimSearch!.elements)
                              ListTile(
                                leading: element.icon != null
                                    ? Image.network(element.icon!)
                                    : Text(""),
                                title: Text(element.diplay_name),
                                subtitle: Text(element.type),
                                trailing: Text(element.distanceInMeter == null
                                    ? ""
                                    : (element.distanceInMeter! > 1000
                                        ? "${round(element.distanceInMeter! / 1000, decimals: 2)} km"
                                        : "${round(element.distanceInMeter!)} m")),
                                onTap: () async {
                                  MapSettings.mapController.moveAndRotate(
                                      LatLng(double.parse(element.lat),
                                          double.parse(element.lon)),
                                      19,
                                      0);
                                  await ref
                                      .read(poiProvider.notifier)
                                      .getPois();
                                  Poi matchedPoi = ref
                                      .read(poiProvider.notifier)
                                      .state
                                      .where((e) =>
                                          e.poiElement.id == element.osm_id)
                                      .first;
                                  ref
                                      .read(selectedPoiProvider.notifier)
                                      .set(matchedPoi);
                                  Navigator.pop(context);
                                  PoiManager.showPoiDetails(
                                      matchedPoi, context);
                                },
                              )
                          ],
                        ),
                      ))
          ],
        ),
      ),
    );
  }
}
