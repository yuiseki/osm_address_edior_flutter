import 'dart:async';

import 'package:flutter/material.dart';
// location lib
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
// flutter map
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

import '../widgets/drawer.dart';
import '../widgets/popup.dart';
import '../api/overpass.dart';

class HomePage extends StatefulWidget {
  static const String route = '/';
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PopupController _popupLayerController = PopupController();
  final OverpassApi _overpassApi = OverpassApi();

  late CenterOnLocationUpdate _centerOnLocationUpdate;
  late StreamController<double> _centerCurrentLocationStreamController;
  late Stream<LocationMarkerPosition> _positionStream;
  Timer? _debounce;
  late List<MyMarker> _markers;

  void getPoi(MapPosition position) {
    debugPrint('getPoi debounce...');
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () async {
      debugPrint('getPoi debounced!!!');
      // do something with query
      List<ResponseLocation> res =
          await _overpassApi.fetchLocationsAroundCenter(
              QueryLocation(
                  longitude: position.center!.longitude,
                  latitude: position.center!.latitude),
              50);
      _markers = res
          .map(
            (item) => MyMarker(
              poi: Poi(
                position: LatLng(item.latitude, item.longitude),
                name: item.name,
                addr: item.addr,
                user: item.user,
              ),
            ),
          )
          .toList();
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _centerOnLocationUpdate = CenterOnLocationUpdate.never;
    _centerCurrentLocationStreamController = StreamController<double>();
    _positionStream =
        const LocationMarkerDataStreamFactory().geolocatorPositionStream(
      stream: Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ),
    );
    _markers = [];
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _centerCurrentLocationStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      drawer: buildDrawer(context, HomePage.route),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(0, 0),
          zoom: 5,
          maxZoom: 20,
          interactiveFlags: InteractiveFlag.all - InteractiveFlag.rotate,
          onPositionChanged: (MapPosition position, bool hasGesture) {
            getPoi(position);
            if (hasGesture) {
              debugPrint('FlutterMap onPositionChanged hasGesture');
              setState(() {
                _centerOnLocationUpdate = CenterOnLocationUpdate.never;
              });
            } else {
              debugPrint('FlutterMap onPositionChanged');
            }
          },
        ),
        children: [
          TileLayerWidget(
              options: TileLayerOptions(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                  maxNativeZoom: 19,
                  maxZoom: 20)),
          LocationMarkerLayerWidget(
            options: LocationMarkerLayerOptions(
                accuracyCircleColor:
                    Colors.deepPurple.shade100.withOpacity(0.3),
                headingSectorColor: Colors.deepPurple.shade300.withOpacity(0.8),
                marker: DefaultLocationMarker(
                  color: Colors.deepPurple.shade300,
                ),
                positionStream: _positionStream),
            plugin: LocationMarkerPlugin(
              centerCurrentLocationStream:
                  _centerCurrentLocationStreamController.stream,
              centerOnLocationUpdate: _centerOnLocationUpdate,
            ),
          ),
          PopupMarkerLayerWidget(
            options: PopupMarkerLayerOptions(
                markers: _markers,
                popupController: _popupLayerController,
                markerRotateAlignment:
                    PopupMarkerLayerOptions.rotationAlignmentFor(
                        AnchorAlign.top),
                popupBuilder: (BuildContext context, Marker marker) {
                  if (marker is MyMarker) {
                    return MyPopup(marker);
                  } else {
                    return const Card(child: Text('Not a poi'));
                  }
                }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(
            Icons.my_location,
            color: Colors.white,
          ),
          onPressed: () {
            debugPrint('FloatingActionButton onPressed');
            _determinePosition();
            setState(() {
              _centerOnLocationUpdate = CenterOnLocationUpdate.never;
            });
            _centerCurrentLocationStreamController.add(20);
          }),
    );
  }
}

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  return await Geolocator.getCurrentPosition();
}
