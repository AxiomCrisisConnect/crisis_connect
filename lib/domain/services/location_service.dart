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

  double _toRad(double deg) => deg * 3.1415926535 / 180;

  /// Check and request background location permission
  Future<bool> requestAlwaysPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse) {
      // Try to upgrade to always, though on some platforms this requires opening settings
      // depending on OS version.
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }
}
