import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static Future<void> requestCameraPermission() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus.isDenied || micStatus.isDenied) {
      throw Exception('❌ صلاحية الكاميرا أو المايك مرفوضة. الرجاء تفعيلها من الإعدادات.');
    } else if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
      throw Exception('🚫 صلاحية الكاميرا أو المايك مرفوضة نهائيًا. فعّلها يدويًا من إعدادات الجهاز.');
    }
  }

  static Future<bool> isCameraPermissionGranted() async {
    return await Permission.camera.isGranted;
  }

  static Future<bool> isMicrophonePermissionGranted() async {
    return await Permission.microphone.isGranted;
  }
}
