import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  bool isBackgroundServiceRunning = false; // ✅ تم تعريف المتغير

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBackgroundServiceStatus();
  }

  // ✅ تحميل الإعدادات المخزنة
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  // ✅ تحديث الوضع الليلي
  Future<void> _updateDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    setState(() {
      darkMode = value;
    });
  }

  // ✅ التحقق مما إذا كانت الخدمة الخلفية تعمل
  Future<void> _checkBackgroundServiceStatus() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    setState(() {
      isBackgroundServiceRunning = isRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkMode ? const Color(0xFF222831) : const Color.fromARGB(255, 145, 195, 209),
      appBar: AppBar(
        backgroundColor: darkMode ? const Color(0xFF393E46) : const Color(0xff79a7b4),
        title: const Text("الإعدادات", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, darkMode),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ زر تفعيل الوضع الليلي
            SwitchListTile(
              activeColor: const Color(0xFF00ADB5),
              title: const Text("الوضع الليلي",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              value: darkMode,
              onChanged: (value) {
                _updateDarkMode(value);
              },
            ),

            // ✅ تشغيل/إيقاف التطبيق في الخلفية
            SwitchListTile(
              activeColor: const Color(0xFF00ADB5),
              title: const Text("تشغيل التطبيق في الخلفية",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              value: isBackgroundServiceRunning,
              onChanged: (value) async {
                final service = FlutterBackgroundService();
                if (value) {
                  await service.startService();
                } else {
                  service.invoke('stop');
                }
                setState(() {
                  isBackgroundServiceRunning = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
