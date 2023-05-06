import 'dart:convert';

import 'package:fluffy_maps/map/map_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:galleryimage/galleryimage.dart';

class PoiElement {
  String type;
  int id;
  double lat;
  double lon;
  Map<String, dynamic>? tags;

  PoiElement(
      {required this.type,
      required this.id,
      required this.lat,
      required this.lon,
      required this.tags});

  factory PoiElement.fromJson(Map<String, dynamic> json) {
    return PoiElement(
        type: json['type'],
        id: json['id'],
        lat: json['lat'],
        lon: json['lon'],
        tags: json['tags']);
  }
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

class PoiManager {
  String overpassUrl = "https://overpass-api.de/api/interpreter";

  Future<OverpassResponse?> getAllPoiInRadius(
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

   Future<OverpassResponse?> getAllPoiInBounds(
      LatLngBounds? latLngBounds , LatLng position) async {
    if(latLngBounds == null) return null;
    String body = "[out:json][timeout:20][maxsize:536870912];";
    body += "node(${latLngBounds.south}, ${latLngBounds.west},${latLngBounds.north}, ${latLngBounds.east});";
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

  showPoiDetails(PoiElement poiElement, BuildContext context) async {
    if (poiElement.tags == null) return;
    Map<String, dynamic> tags = poiElement.tags!;
    List<String> images = await getImages(tags);
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return DraggableScrollableSheet(
            snap: true,
            snapSizes: const [0.5, 1.0],
            expand: false,
            builder: (context, scrollController) {
              return CustomScrollView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    // SliverPersistentHeader(
                    //   delegate: PoiSliverAppBar(poiElement: poiElement),
                    //   pinned: true,
                    // ),
                    SliverList(
                        delegate: SliverChildListDelegate([
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(tags["name"] ?? "",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 0, 8, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                (tags["amenity"] ?? "")
                                    .toString()
                                    .replaceAll("_", ""),
                                style: TextStyle(
                                    fontStyle: FontStyle.italic, fontSize: 15)),
                            Text(
                                ((tags["wheelchair"] == null
                                    ? ""
                                    : "Wheelchair: " + tags["wheelchair"])),
                                style: TextStyle(
                                    fontStyle: FontStyle.italic, fontSize: 15))
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          getAdress(tags),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
                      // Text(
                      //   (tags["source"] ?? "").toString().replaceAll("_", ""),
                      //   style: TextStyle(
                      //       fontWeight: FontWeight.bold, fontSize: 20),
                      // ),
                      GalleryImage(
                        imageUrls: images,
                        numOfShowImages: images.length < 4 ? images.length : 4,
                        titleGallery: "",
                      )
                    ]))
                  ]);
            });
      },
    );
  }

  String getAdress(Map<String, dynamic> tags) {
    String? street = tags["addr:street"];
    String? contactStreet = tags["contact:street"];
    String? housenumber = tags["addr:housenumber"];
    String? contactHousenumber = tags["contact:housenumber"];
    String? postcode = tags["addr:postcode"];
    String? city = tags["addr:city"];
    String? contactAdress = tags["contact:address"];
    String? contactAdressFull = tags["contact:address:full"];
    String? country = tags["addr:country"];
    String streetString = "";
    String postCodeString = "";
    String countryString = "";
    if (street != null && housenumber != null) {
      streetString = "$street $housenumber";
    } else {
      if (contactStreet != null && contactHousenumber != null) {
        streetString = "$contactStreet $contactHousenumber";
      }
    }
    if (postcode != null) {
      if (streetString.isEmpty) {
        postCodeString += postcode;
      } else {
        postCodeString += ", $postcode";
      }
      if (city != null) {
        postCodeString += " $city";
      }
    } else if (postcode == null && city != null) {
      postCodeString += ", $city";
    }
    if (country != null) {
      countryString += ", $country";
    }
    String fullAddress = streetString + postCodeString + countryString;
    if (fullAddress.isEmpty) {
      if (contactAdress != null && contactAdress.isNotEmpty) {
        return contactAdress;
      } else if (contactAdressFull != null && contactAdressFull.isNotEmpty) {
        return contactAdressFull;
      }
    }
    return fullAddress;
  }

  Future<List<String>> getImages(Map<String, dynamic> tags) async {
    List<String> urls = [];
    for (String key in tags.keys) {
      // img|image:access_sign|image
      if (key == "image") {
        String url = tags[key];
        RegExp wikimedia =
            RegExp(r"https:\/\/commons\.wikimedia\.org\/wiki\/(.*)");
        RegExpMatch? wikimediaFile = wikimedia.firstMatch(url);
        if (wikimediaFile != null &&
            wikimediaFile.groupCount > 0 &&
            wikimediaFile.group(1) != null) {
          String? wikimediaUrl =
              await extractWikimediaUrl(wikimediaFile.group(1)!);
          if (wikimediaUrl != null) {
            urls.add(wikimediaUrl);
          }
        }
      }
      if (key == "wikimedia_commons") {
        String? url = await extractWikimediaUrl(tags[key]);
        if (url != null) {
          urls.add(url);
        }
      }
      if (key == "mapillary") {
        String? accessToken = dotenv.env['MAPILLARY_ACCESS_TOKEN'];
        if (accessToken != null) {
          http.Response response = await http.get(Uri.parse(
              "https://graph.mapillary.com/${tags[key]}?access_token=${accessToken}&fields=id,captured_at,compass_angle,sequence,geometry,thumb_1024_url"));
          if (response.statusCode == 200) {
            Map<String, dynamic> jsonBody =
                jsonDecode(utf8.decode(response.bodyBytes));
            if (jsonBody.containsKey("thumb_1024_url")) {
              urls.add(jsonBody["thumb_1024_url"]);
            }
          }
        }
      }
    }
    return urls;
  }

  Future<String?> extractWikimediaUrl(String file) async {
    http.Response response = await http
        .get(Uri.parse("https://api.wikimedia.org/core/v1/commons/file/$file"));
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonBody =
          jsonDecode(utf8.decode(response.bodyBytes));
      if (jsonBody.containsKey("preferred") &&
          jsonBody["preferred"].containsKey("url")) {
        return jsonBody["preferred"]["url"];
      }
    }
    return null;
  }
}
