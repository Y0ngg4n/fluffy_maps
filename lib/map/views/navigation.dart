import 'dart:async';

import 'package:fluffy_maps/map/map_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:georouter/georouter.dart';
import 'package:latlong2/latlong.dart';

import '../api/location_manager.dart';
import '../api/osrm.dart';
import 'map_view.dart';

class OSRMRoute {
  LatLng? start;
  LatLng? end;
  List<LatLng> route;
  List<LatLng> breadCrumbs;
  List<LatLng> navigationDistancePoints;

  OSRMRoute(
      {this.start,
      this.end,
      required this.route,
      required this.breadCrumbs,
      required this.navigationDistancePoints});
}

class NavigationManager {
  static Future<void> getRoute(WidgetRef ref, LatLng start, LatLng end) async {
    print(ref.read(travelModeProvider.notifier).getState());
    OSRMRoute? route = await OSRM.route(
        ref.read(travelModeProvider.notifier).getState(), start, end);
    if (route != null) {
      ref.read(routeProvider.notifier).set(route);
      mapKey.currentState!.setState(() {});
      mapKey.currentState!.startListeningForLocationChange();
    }
  }
}

class NavigationStart extends ConsumerStatefulWidget {
  Stream<Position>? positionStream;

  NavigationStart({Key? key, required this.positionStream}) : super(key: key);

  @override
  ConsumerState<NavigationStart> createState() => _NavigationStartState();
}

class _NavigationStartState extends ConsumerState<NavigationStart> {
  List<bool> selected = List.generate(4, (index) => index == 0 ? true : false);

  @override
  Widget build(BuildContext context) {
    OSRMRoute route = ref.read(routeProvider.notifier).getState();

    return StreamBuilder<Position>(
        stream: widget.positionStream,
        builder: (context, snapshot) {
          double distance = OSRM.getDistanceOfRoute(
              LengthUnit.Meter, route.navigationDistancePoints);
          if (snapshot.hasData) {
            distance = OSRM.getDistanceOfRoute(
                LengthUnit.Meter, route.navigationDistancePoints);
          }
          return Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      ToggleButtons(
                          isSelected: selected,
                          onPressed: (index) async {
                            setState(() {
                              for (int buttonIndex = 0;
                                  buttonIndex < selected.length;
                                  buttonIndex++) {
                                if (buttonIndex == index) {
                                  selected[buttonIndex] = true;
                                } else {
                                  selected[buttonIndex] = false;
                                }
                              }
                            });
                            switch (index) {
                              case 0:
                                ref
                                    .read(travelModeProvider.notifier)
                                    .set(TravelMode.walking);
                                break;
                              case 1:
                                ref
                                    .read(travelModeProvider.notifier)
                                    .set(TravelMode.cycling);
                                break;
                              case 2:
                                ref
                                    .read(travelModeProvider.notifier)
                                    .set(TravelMode.transit);
                                break;
                              case 3:
                                ref
                                    .read(travelModeProvider.notifier)
                                    .set(TravelMode.driving);
                                break;
                              default:
                                ref
                                    .read(travelModeProvider.notifier)
                                    .set(TravelMode.walking);
                                break;
                            }

                            if (route.start != null && route.end != null) {
                              await NavigationManager.getRoute(
                                  ref, route.start!, route.end!);
                            }
                          },
                          children: const [
                            Icon(Icons.directions_walk),
                            Icon(Icons.directions_bike),
                            Icon(Icons.directions_bus),
                            Icon(Icons.directions_car),
                          ])
                    ],
                  ),
                  Text("Distance: " + distance.toString())
                ],
              ),
            ],
          );
        });
  }
}
