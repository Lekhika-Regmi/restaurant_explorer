import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapViewWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? title;

  const MapViewWidget({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.title,
  }) : super(key: key);

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LatLng position = LatLng(widget.latitude, widget.longitude);

    final CameraPosition initialCameraPosition = CameraPosition(
      target: position,
      zoom: 15,
    );

    final Marker marker = Marker(
      markerId: const MarkerId('restaurant_marker'),
      position: position,
      infoWindow: InfoWindow(title: widget.title ?? 'Restaurant Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    return SizedBox(
      height: 250,
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GoogleMap(
            initialCameraPosition: initialCameraPosition,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: {marker},
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            buildingsEnabled: true,
            trafficEnabled: false,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
          ),
        ),
      ),
    );
  }
}
