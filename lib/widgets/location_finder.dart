import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:seyaqti_app/classes/utils.dart';
import 'package:seyaqti_app/widgets/loading.dart';

// ignore: must_be_immutable
class LocationFinder extends StatefulWidget {
  LocationFinder({super.key, required this.selectedMarker});
  Marker? selectedMarker;

  @override
  State<LocationFinder> createState() => _LocationFinderState();
}

class _LocationFinderState extends State<LocationFinder> {
  static const CameraPosition initCamPos = CameraPosition(
    target: LatLng(26.0667, 50.5577),
    zoom: 10.5,
  );

  late final GoogleMapController controller;
  final List<Marker> markers = <Marker>[];

  bool isLoading = true;

  Marker locationMarker(LatLng pos, String id, String title) => Marker(
        markerId: MarkerId(id),
        infoWindow: InfoWindow(title: title),
        icon: id == 'trainee'
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
            : BitmapDescriptor.defaultMarker,
        position: pos,
      );

  getUserLocation() {
    markers.clear();
    widget.selectedMarker!;
    Marker marker = locationMarker(
        widget.selectedMarker!.position, 'trainee', 'Trainee\'s Location');
    markers.add(marker);
    setState(() {});
  }

  Future<Position> getUserCurrentLocation() async {
    setState(() {
      isLoading = true;
    });
    await Geolocator.requestPermission()
        .then((value) {})
        .onError((error, stackTrace) async {
      await Geolocator.requestPermission();
      Utils.ShowErrorBar("$error");
    });
    return await Geolocator.getCurrentPosition();
  }

  setCurrentLocation() async {
    try {
      await getUserCurrentLocation().then((pos) async {
        markers.add(
          locationMarker(
            LatLng(pos.latitude, pos.longitude),
            'instructor',
            'My Location',
          ),
        );
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
      });
      //await getPolyPoints();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  markerFocus(String id) {
    final marker = markers.firstWhere((marker) => marker.markerId.value == id);
    final pos = marker.position;
    CameraPosition cameraPosition = CameraPosition(
      target: LatLng(pos.latitude, pos.longitude),
      zoom: 16.5,
    );
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    controller.showMarkerInfoWindow(MarkerId(id));
  }

  mapFocus() {
    controller.animateCamera(CameraUpdate.newCameraPosition(initCamPos));
  }

  @override
  void initState() {
    super.initState();
    getUserLocation();
    setCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Get Location"),
        centerTitle: false,
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: isLoading ? null : () => markerFocus('instructor'),
            child: const Text('ORIGIN', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: isLoading ? null : () => markerFocus('trainee'),
            child: const Text('DEST', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: GoogleMap(
              zoomControlsEnabled: false,
              initialCameraPosition: initCamPos,
              markers: Set<Marker>.of(markers),
              mapType: MapType.normal,
              onMapCreated: (GoogleMapController controller) {
                this.controller = controller;
                getUserLocation();
              },
            ),
          ),
          if (isLoading) const Loading(color: Colors.white10),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: FloatingActionButton(
          onPressed: mapFocus,
          child: const Icon(Icons.map_outlined),
        ),
      ),
    );
  }
}
