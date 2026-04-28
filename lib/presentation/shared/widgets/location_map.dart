import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';

class LocationMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double? height;
  final double zoom;
  final bool interactive;
  final double borderRadius;

  const LocationMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 200,
    this.zoom = 15.0,
    this.interactive = true,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final location = LatLng(latitude, longitude);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderRadius > 0
            ? Border.all(color: AppColors.border, width: 1.5)
            : null,
        boxShadow: borderRadius > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: location,
          initialZoom: zoom,
          interactionOptions: InteractionOptions(
            flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.crisisconnect.app',
            maxZoom: 19,
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: location,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.sos,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
