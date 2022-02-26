import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:xml/xml.dart';
import 'package:http/http.dart';

class OverpassApi {
  static const String _apiUrl = 'overpass-api.de';
  static const String _path = '/api/interpreter';

  Future<List<ResponseLocation>> fetchLocationsAroundCenter(
      QueryLocation center, double radius) async {
    Request request = Request('GET', Uri.https(_apiUrl, _path));
    request.bodyFields = _buildRequestBody(center, radius);

    String responseText;
    try {
      StreamedResponse response =
          await Client().send(request).timeout(const Duration(seconds: 25));
      responseText = await response.stream.bytesToString();
    } catch (exception) {
      print(exception);
      return Future.error(exception);
    }
    debugPrint(responseText);

    var responseJson;
    try {
      responseJson = jsonDecode(responseText);
    } catch (exception) {
      String error = '';
      final document = XmlDocument.parse(responseText);
      final paragraphs = document.findAllElements("p");
      paragraphs.forEach((element) {
        if (element.text.trim() == '') {
          return;
        }
        error += '${element.text.trim()}';
      });
      return Future.error(error);
    }

    if (responseJson['elements'] == null) {
      return [];
    }

    List<ResponseLocation> resultList = [];
    for (var location in responseJson['elements']) {
      resultList.add(ResponseLocation.fromJson(location));
    }
    return resultList;
  }

  Map<String, String> _buildRequestBody(QueryLocation center, double radius) {
    OverpassQuery query = new OverpassQuery(
      output: 'json',
      timeout: 25,
      elements: [
        SetElement(
          area: LocationArea(
              longitude: center.longitude,
              latitude: center.latitude,
              radius: radius),
        )
      ],
    );
    return query.toMap();
  }
}

class OverpassQuery {
  String output;
  int timeout;
  List<SetElement> elements;
  OverpassQuery(
      {required this.output, required this.timeout, required this.elements});

  Map<String, String> toMap() {
    String elementsString = '';
    for (SetElement element in elements) {
      elementsString += '$element;';
    }
    String data =
        '[out:$output][timeout:$timeout];($elementsString);out meta center;';
    debugPrint('OverpassQuery: ' + data);
    return <String, String>{'data': data};
  }
}

class SetElement {
  final LocationArea area;
  SetElement({required this.area});

  @override
  String toString() {
    String areaString = '';
    areaString +=
        'way["building"="yes"](around:${area.radius},${area.latitude},${area.longitude})';
    return areaString;
  }
}

class LocationArea {
  final double longitude;
  final double latitude;
  final double radius;

  LocationArea(
      {required this.longitude, required this.latitude, required this.radius});
}

class ResponseLocation {
  late double longitude;
  late double latitude;
  late String name;
  late String addr;
  late String user;

  ResponseLocation({
    required this.longitude,
    required this.latitude,
    required this.name,
    required this.addr,
    required this.user,
  });

  ResponseLocation.fromJson(Map<dynamic, dynamic> json) {
    if (json['tags'] == null) {
      return;
    }
    this.longitude = json['center']['lon'];
    this.latitude = json['center']['lat'];
    Map<String, dynamic> tags = json['tags'];

    if (json['tags']['name'] == null) {
      this.name = 'No name';
    } else {
      this.name = json['tags']['name'];
    }

    List<String> addrTags = [
      'addr:postcode',
      'addr:province',
      'addr:city',
      'addr:quarter',
      'addr:neighbourhood',
      'addr:block_number',
      'addr:housenumber'
    ];
    this.addr = '';
    for (var addrTag in addrTags) {
      if (json['tags'][addrTag] != null) {
        this.addr += json['tags'][addrTag] + ' ';
      }
    }

    if (json['user'] == null) {
      this.user = 'No user';
    } else {
      this.user = json['user'];
    }
  }
}

class QueryLocation {
  final double longitude;
  final double latitude;

  QueryLocation({
    required this.longitude,
    required this.latitude,
  });
}
