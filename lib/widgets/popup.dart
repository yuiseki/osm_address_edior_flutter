import 'package:flutter/material.dart';

import 'package:latlong2/latlong.dart';

import 'package:flutter_map/flutter_map.dart';

class Poi {
  Poi({
    required this.position,
    required this.name,
    required this.addr,
    required this.user,
  });

  final LatLng position;
  final String name;
  final String addr;
  final String user;
}

class MyMarker extends Marker {
  MyMarker({required this.poi})
      : super(
          height: 45,
          width: 45,
          point: poi.position,
          builder: (BuildContext ctx) => const Icon(Icons.location_on),
          anchorPos: AnchorPos.align(AnchorAlign.top),
        );

  final Poi poi;
}

class MyPopup extends StatefulWidget {
  final MyMarker marker;

  const MyPopup(this.marker, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyPopupState(marker);
}

class _MyPopupState extends State<MyPopup> {
  final MyMarker _marker;

  _MyPopupState(this._marker);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => setState(() {
          debugPrint('MyPopup onTap');
        }),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(left: 20, right: 10),
              child: Icon(Icons.edit),
            ),
            _cardDescription(context),
          ],
        ),
      ),
    );
  }

  Widget _cardDescription(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        constraints: const BoxConstraints(minWidth: 100, maxWidth: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              _marker.poi.name,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14.0,
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4.0)),
            Text(
              _marker.poi.addr,
              overflow: TextOverflow.fade,
              softWrap: true,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14.0,
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4.0)),
            Text(
              'Latitude: ${_marker.point.latitude}',
              style: const TextStyle(fontSize: 12.0),
            ),
            Text(
              'Longitude: ${_marker.point.longitude}',
              style: const TextStyle(fontSize: 12.0),
            ),
            Text(
              'User: ${_marker.poi.user}',
              style: const TextStyle(fontSize: 12.0),
            ),
          ],
        ),
      ),
    );
  }
}
