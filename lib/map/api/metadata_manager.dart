import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'overpass.dart';

class MetadataManager {
  static Future<String?> extractWikimediaUrl(String file) async {
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

  static String getAdress(Poi poi) {
    Map<String, String> tags = poi.poiElement.tags!;
    String? street = tags["addr:street"];
    String? contactStreet = tags["contact:street"];
    String? housenumber = tags["addr:housenumber"];
    String? contactHousenumber = tags["contact:housenumber"];
    String? postcode = tags["addr:postcode"];
    String? city = tags["addr:city"];
    String? contactAdress = tags["contact:address"];
    String? contactAdressFull = tags["contact:address:full"];
    String? country = tags["addr:country"];
    String? nomatimHouseNumber;
    String? nomatimRoad;
    String? nomatimCity;
    String? nomatimPostcode;
    String? nomatimCountry;
    String streetString = "";
    String postCodeString = "";
    String countryString = "";
    if (poi.nomatimLookupElement != null) {
      nomatimHouseNumber = poi.nomatimLookupElement!.address["house_number"];
      nomatimRoad = poi.nomatimLookupElement!.address["road"];
      nomatimCity = poi.nomatimLookupElement!.address["city"];
      nomatimPostcode = poi.nomatimLookupElement!.address["postcode"];
      nomatimCountry = poi.nomatimLookupElement!.address["country"];
      if (nomatimRoad != null && nomatimHouseNumber != null) {
        streetString = "$nomatimRoad $nomatimHouseNumber";
      } else {
        if (nomatimRoad != null) {
          streetString = nomatimRoad;
        }
      }

      if (nomatimPostcode != null) {
        if (streetString.isEmpty) {
          postCodeString += nomatimPostcode;
        } else {
          postCodeString += ", $nomatimPostcode";
        }
        if (city != null) {
          postCodeString += ", $nomatimCity";
        }
      } else if (nomatimPostcode == null && nomatimCity != null) {
        postCodeString += ", $nomatimCity";
      }
      if (nomatimCountry != null) {
        countryString += ", $nomatimCountry";
      }
      String fullAdress = streetString + postCodeString + countryString;
      if (fullAdress.isNotEmpty) {
        return fullAdress;
      }
    }

    if (street != null && housenumber != null) {
      streetString = "$street $housenumber";
    } else {
      if (street != null) {
        streetString = street;
      } else if (contactStreet != null && contactHousenumber != null) {
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

  static Future<List<String>> getImages(Map<String, dynamic> tags) async {
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
}
