import 'dart:convert';

import 'package:fluffy_maps/map/api/metadata_manager.dart';
import 'package:fluffy_maps/map/api/overpass.dart';
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
  double? lat;
  double? lon;
  Map<String, String>? tags;
  List<int>? nodes;

  PoiElement(
      {required this.type,
      required this.id,
      required this.lat,
      required this.lon,
      required this.tags,
      this.nodes});

  factory PoiElement.fromJson(Map<String, dynamic> json) {
    return PoiElement(
        type: json['type'],
        id: json['id'],
        lat: json['lat'],
        lon: json['lon'],
        tags: json['tags'] != null
            ? Map<String, String>.from(json['tags'])
            : null,
        nodes: json['nodes'] != null ? List<int>.from(json['nodes']) : null);
  }
}

class PoiManager {
  static showPoiDetails(Poi poi, BuildContext context) async {
    if (poi.poiElement.tags == null) return;
    Map<String, dynamic> tags = poi.poiElement.tags!;
    List<String> images = await MetadataManager.getImages(tags);
    showModalBottomSheet(
      barrierColor: Colors.black.withOpacity(0),
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
                        child: Text(
                            tags["name"] ??
                                (poi.nomatimLookupElement != null
                                    ? poi.nomatimLookupElement!
                                        .address["amenity"]
                                    : ""),
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
                          MetadataManager.getAdress(poi),
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
}
