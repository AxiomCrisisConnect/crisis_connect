import 'dart:async';
import 'package:geolocator/geolocator.dart';

// TODO: Add background_fetch for true background location tracking
// TODO: Request location permissions in AndroidManifest.xml and Info.plist

class LocationService {
  Timer? _backgroundTimer;
  StreamSubscription<Position>? _positionSubscription;

  Future<Position?> getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.denied ||
            result == LocationPermission.deniedForever) {
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 50, // meters
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Starts periodic background location updates, calling [onLocationUpdate]
  /// every [intervalMinutes] minutes when the volunteer is marked available.
  void startBackgroundTracking({
    required int intervalMinutes,
    required Future<void> Function(double lat, double lng) onLocationUpdate,
  }) {
    stopBackgroundTracking();

    // Initial update immediately
    _triggerUpdate(onLocationUpdate);

    _backgroundTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => _triggerUpdate(onLocationUpdate),
    );

    // Also stream fine-grained updates
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 100, // only emit if moved 100m
      ),
    ).listen((pos) {
      // TODO: Combine with battery check — reduce frequency when battery < 20%
      onLocationUpdate(pos.latitude, pos.longitude);
    });
  }

  Future<void> _triggerUpdate(
      Future<void> Function(double, double) onLocationUpdate) async {
    final pos = await getCurrentLocation();
    if (pos != null) {
      await onLocationUpdate(pos.latitude, pos.longitude);
    }
  }

  void stopBackgroundTracking() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Calculate mocked ETA in minutes based on distance
  int calculateEtaMinutes(double volunteerLat, double volunteerLng,
      double targetLat, double targetLng) {
    // Haversine distance in km, assume average speed 40 km/h
    const r = 6371.0;
    final dLat = _toRad(targetLat - volunteerLat);
    final dLng = _toRad(targetLng - volunteerLng);
    final sinDLat = dLat / 2;
    final sinDLng = dLng / 2;
    final a = sinDLat * sinDLat +
        sinDLng * sinDLng; // simplified; replace with proper haversine
    final distKm = r * 2 * a.abs(); // rough approximation
    final etaHours = distKm / 40.0;
    return (etaHours * 60).ceil().clamp(2, 90);
  }

  double _toRad(double deg) => deg * 3.1415926535 / 180;

  /// Check and request background location permission
  Future<bool> requestAlwaysPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always;
  }
}
