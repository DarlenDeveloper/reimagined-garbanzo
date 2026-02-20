import 'package:workmanager/workmanager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'location_service.dart';

const String locationUpdateTask = 'locationUpdateTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp();
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return Future.value(true);
      
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      
      if (position != null) {
        await locationService.saveUserLocation(userId, position);
        print('Background location updated: ${position.latitude}, ${position.longitude}');
      }
      
      return Future.value(true);
    } catch (e) {
      print('Background location update failed: $e');
      return Future.value(false);
    }
  });
}

class BackgroundLocationService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      locationUpdateTask,
      locationUpdateTask,
      frequency: const Duration(hours: 5),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  static Future<void> cancelTask() async {
    await Workmanager().cancelByUniqueName(locationUpdateTask);
  }
}
