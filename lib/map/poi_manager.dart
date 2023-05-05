import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
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

  showPoiDetails(PoiElement poiElement, BuildContext context) async {
    if (poiElement.tags == null) return;
    Map<String, dynamic> tags = poiElement.tags!;
    List<String> images = await getImages(tags);
    showBottomSheet(
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
    String? housenumber = tags["addr:housenumber"];
    String? postcode = tags["addr:postcode"];
    String? city = tags["addr:city"];
    String? country = tags["addr:country"];
    String streetString = "";
    String postCodeString = "";
    String countryString = "";
    if (street != null && housenumber != null) {
      streetString = "$street $housenumber";
    }
    if (postcode != null) {
      postCodeString += ", $postcode";
      if (city != null) {
        postCodeString += " $city";
      }
    } else if (postcode == null && city != null) {
      postCodeString += ", $city";
    }
    if (country != null) {
      countryString += ", $country";
    }
    return streetString + postCodeString + countryString;
  }

  Future<List<String>> getImages(Map<String, dynamic> tags) async {
    List<String> urls = [];
    for (String key in tags.keys) {
      // img|image:access_sign|image
      if (key == "image") {
        urls.add(tags[key]);
      }
      else if (key == "wikimedia_commons") {
        http.Response response = await http.get(Uri.parse(
            "https://api.wikimedia.org/core/v1/commons/file/" + tags[key]));
        if (response.statusCode == 200) {
          Map<String, dynamic> jsonBody =
              jsonDecode(utf8.decode(response.bodyBytes));
          if (jsonBody.containsKey("preferred") &&
              jsonBody["preferred"].containsKey("url")) {
            urls.add(jsonBody["preferred"]["url"]);
          }
        }
      }
    }
    return urls;
  }
}
