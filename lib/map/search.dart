import 'dart:convert';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:fluffy_maps/map/map_settings.dart';
import 'package:fluffy_maps/map/poi_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'location_manager.dart';

class SearchElement {
  int place_id;
  String licence;
  String osm_type;
  int osm_id;
  List<dynamic> boundingbox;
  String lat;
  String lon;
  String diplay_name;
  int place_rank;
  String category;
  String type;
  double importance;
  String? icon;
  double? distanceInMeter;

  SearchElement(
      {required this.place_id,
      required this.licence,
      required this.osm_type,
      required this.osm_id,
      required this.boundingbox,
      required this.lat,
      required this.lon,
      required this.diplay_name,
      required this.place_rank,
      required this.category,
      required this.type,
      required this.importance,
      required this.icon});

  factory SearchElement.fromJson(Map<String, dynamic> json) {
    return SearchElement(
      place_id: json['place_id'],
      licence: json['licence'],
      osm_type: json['osm_type'],
      osm_id: json['osm_id'],
      boundingbox: json['boundingbox'],
      lat: json['lat'],
      lon: json['lon'],
      diplay_name: json['display_name'],
      place_rank: json['place_rank'],
      category: json['category'],
      type: json['type'],
      importance: json['importance'],
      icon: json['icon'],
    );
  }
}

class NomatimResponse {
  List<SearchElement> elements;

  NomatimResponse({required this.elements});

  factory NomatimResponse.fromJson(List<dynamic> json) {
    return NomatimResponse(
        elements: json
            .map((e) => SearchElement.fromJson(e))
            .toList()
            .cast<SearchElement>());
  }
}

class SearchView extends ConsumerStatefulWidget {
  const SearchView({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  TextEditingController textEditingController = TextEditingController();
  NomatimResponse? searchList;

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
                          Position position =
                              await LocationManager().determinePosition();
                          NomatimResponse? response = await searchNomatim(
                              position, textEditingController.text);
                          setState(() {
                            searchList = response;
                          });
                        },
                      );
                    });
                  });
                },
              ),
            ),
            searchList == null && textEditingController.text.isNotEmpty
                ? CircularProgressIndicator()
                : (searchList == null || textEditingController.text.isEmpty
                    ? Container()
                    : Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (SearchElement element in searchList!.elements)
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
                                  PoiManager().showPoiDetails(
                                      matchedPoi.poiElement, context);
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

  Future<NomatimResponse?> searchNomatim(Position position, searchText) async {
    print("Search");
    http.Response response = await http.get(
        Uri.parse(
          "https://nominatim.openstreetmap.org/search.php?q=$searchText&format=jsonv2",
        ),
        headers: {"charset": "utf-8"});
    if (response.statusCode == 200) {
      NomatimResponse nomatimResponse =
          NomatimResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      if (nomatimResponse.elements.length > 1) {
        nomatimResponse.elements.sort(
          (a, b) {
            Distance distance = Distance();
            double ma = distance.as(
                LengthUnit.Meter,
                LatLng(position.latitude, position.longitude),
                LatLng(double.parse(a.lat), double.parse(a.lon)));
            a.distanceInMeter = ma;
            double mb = distance.as(
                LengthUnit.Meter,
                LatLng(position.latitude, position.longitude),
                LatLng(double.parse(b.lat), double.parse(b.lon)));
            b.distanceInMeter = mb;
            return ma.compareTo(mb);
          },
        );
      } else {
        Distance distance = Distance();
        SearchElement searchElement = nomatimResponse.elements.first;
        double ma = distance.as(
            LengthUnit.Meter,
            LatLng(position.latitude, position.longitude),
            LatLng(double.parse(searchElement.lat),
                double.parse(searchElement.lon)));
        searchElement.distanceInMeter = ma;
      }
      return nomatimResponse;
    } else {
      return null;
    }
  }
}
