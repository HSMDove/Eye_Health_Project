import 'package:permission_handler/permission_handler.dart';

class PermissionManager{
  static Future<void> requestCameraPermission() async{
    final status = await Permission.camera.request();

    if(status.isDenied){
      throw Exception('Camera permission is denied. Please enable it in settings.');
    } else if (status.isPermanentlyDenied){
      throw Exception('Camera permission is permanently denied. Please enable it in settings.');
    }
  }

  static Future<bool> isCameraPermissionGranted() async {
    return await Permission.camera.isGranted;
  }
}