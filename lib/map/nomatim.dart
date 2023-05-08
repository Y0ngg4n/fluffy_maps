import 'dart:convert';
import 'package:http/http.dart' as http;

import 'map_settings.dart';

class NomatimLookupElementAddress {
  String tourism;
  String road;
  String suburb;
  String city;
  String state;
  String postcode;
  String country;
  String countryCode;

  NomatimLookupElementAddress({
    required this.tourism,
    required this.road,
    required this.suburb,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
    required this.countryCode,
  });

  factory NomatimLookupElementAddress.fromJson(Map<String, dynamic> json) {
    return NomatimLookupElementAddress(
      tourism: json['tourism'],
      road: json['road'],
      suburb: json['suburb'],
      city: json['city'],
      state: json['state'],
      postcode: json['postcode'],
      country: json['country'],
      countryCode: json['country_code'],
    );
  }
}

class NomatimLookupElement {
  int placeId;
  String licence;
  String osmType;
  int osmId;
  List<double> boundingbox;
  double lat;
  double lon;
  String displayName;
  String classValue;
  String type;
  double importance;
  Map<String, String> address;

  NomatimLookupElement({
    required this.placeId,
    required this.licence,
    required this.osmType,
    required this.osmId,
    required this.boundingbox,
    required this.lat,
    required this.lon,
    required this.displayName,
    required this.classValue,
    required this.type,
    required this.importance,
    required this.address,
  });

  factory NomatimLookupElement.fromJson(Map<String, dynamic> json) {
    return NomatimLookupElement(
      placeId: json['place_id'],
      licence: json['licence'],
      osmType: json['osm_type'],
      osmId: json['osm_id'],
      boundingbox: json['boundingbox'].map<double>((e) => double.parse(e)).toList(),
      lat: double.parse(json['lat']),
      lon: double.parse(json['lon']),
      displayName: json['display_name'],
      classValue: json['class'],
      type: json['type'],
      importance: double.parse(json['importance'].toString()),
      address: Map<String, String>.from(json['address']),
    );
  }
}


Future<List<NomatimLookupElement>> getNominatimLookupElements(List<int> osmIds) async {
  final String baseUrl = 'https://nominatim.openstreetmap.org/lookup';

  List<NomatimLookupElement> elements = [];

  for (int i = 0; i < osmIds.length; i += 50) {
    List<int> sublist = osmIds.sublist(i, i + 50 > osmIds.length ? osmIds.length : i + 50);

    Uri url = Uri.parse('$baseUrl?format=json&osm_ids=${sublist.map((id) => 'N$id').join(',')}');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));

      for (var json in jsonList) {
        elements.add(NomatimLookupElement.fromJson(json));
      }
    }
  }

  return elements;
}

List<Poi> mapLookupElementToPoi(List<NomatimLookupElement> nomatimElements, List<Poi> pois){
  for(NomatimLookupElement nomatimLookupElement in nomatimElements){
    Poi poi = pois.firstWhere((element) => element.poiElement.id == nomatimLookupElement.osmId);
    poi.nomatimLookupElement = nomatimLookupElement;
  }
  return pois;
}