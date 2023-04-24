import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:seyaqti_app/classes/utils.dart';
import 'package:seyaqti_app/widgets/loading.dart';

// ignore: must_be_immutable
class LocationPicker extends StatefulWidget {
  Marker? selectedMarker;
  LocationPicker({super.key});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late final GoogleMapController controller;
  static const CameraPosition initCamPos = CameraPosition(
    target: LatLng(26.0667, 50.5577),
    zoom: 10.5,
  );
  final List<Marker> markers = <Marker>[];
  bool isLoading = true;

  Marker locationMarker(LatLng pos) => Marker(
        markerId: const MarkerId('1'),
        infoWindow: const InfoWindow(title: 'My Location'),
        position: pos,
      );

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
        markers.clear();
        widget.selectedMarker =
            locationMarker(LatLng(pos.latitude, pos.longitude));
        markers.add(widget.selectedMarker!);
        CameraPosition cameraPosition = CameraPosition(
          target: LatLng(pos.latitude, pos.longitude),
          zoom: 16.5,
        );
        controller
            .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    setCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Location Picker"),
        centerTitle: true,
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: isLoading ? null : setCurrentLocation,
            icon: const Icon(
              Icons.my_location,
              size: 15,
            ),
            label: const Text('My Location', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: GoogleMap(
              initialCameraPosition: initCamPos,
              markers: Set<Marker>.of(markers),
              mapType: MapType.normal,
              myLocationEnabled: false,
              compassEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                this.controller = controller;
              },
              onLongPress: (pos) {
                markers.clear();
                widget.selectedMarker = locationMarker(pos);
                markers.add(widget.selectedMarker!);
                CameraPosition cameraPosition = CameraPosition(
                  target: LatLng(pos.latitude, pos.longitude),
                  zoom: 16.5,
                );
                controller.animateCamera(
                    CameraUpdate.newCameraPosition(cameraPosition));
                setState(() {});
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(right: 100),
            child: RichText(
              textAlign: TextAlign.justify,
              text: const TextSpan(
                style: TextStyle(fontSize: 11, color: Colors.black),
                children: [
                  WidgetSpan(
                    child: Icon(Icons.info, size: 15),
                  ),
                  TextSpan(
                    text:
                        ' Click the \'My Location\' button above to auto-select your location. Alternatively, you can use the map controls and hold to select it manually.',
                  ),
                ],
              ),
            ),
          ),
          if (isLoading) const Loading(color: Colors.white10),
        ],
      ),
    );
  }
}
