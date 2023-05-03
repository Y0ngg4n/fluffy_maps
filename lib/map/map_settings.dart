import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapSettings {
    static getTileLayerWidget() {
    return TileLayer(
        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        subdomains: const ['a', 'b', 'c'],
    );
  }
}