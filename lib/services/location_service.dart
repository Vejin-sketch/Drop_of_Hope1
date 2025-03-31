import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';

class LocationService {
  static Future<Position?> getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      bool opened = await Geolocator.openLocationSettings();
      if (!opened) {
        print('User refused to open location settings.');
        return null;
      }

      // ✅ After opening settings, give them time to turn GPS on, then try again
      await Future.delayed(Duration(seconds: 2));
      return await getUserLocation(); // 👈 retry after user enables GPS
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Location permission denied');
        return null;
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print("User's location: ${position.latitude}, ${position.longitude}");
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }
}