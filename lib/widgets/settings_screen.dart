import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../management/blink_evaluator_service.dart'; // غير المسار حسب مشروعك

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  bool backgroundMode = false; // 🆕 لتشغيل التطبيق بالخلفية (مؤقتًا لا يعمل)
  bool notificationsEnabled = false;
  double notificationInterval = 15;
  double blinkCalculationTime = 60;
  String selectedLanguage = "العربية";

  final TextStyle _titleStyle = const TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _updateBlinkCalculationTime(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('blinkCalculationTime', value);

    setState(() {
      blinkCalculationTime = value; // هنا تحدث الواجهة
    });

    // 🔥 تحدث منطق المعالجة هنا (كود الرمش)
    BlinkEvaluatorService.instance.updateTimings(
      newIntervalSeconds: value.toInt(),
      newEvaluationDurationSeconds: value.toInt(),
    );
  }



  Future<void> _updateDarkMode(bool value) async => _updateSetting('darkMode', value, (val) => darkMode = val);
  Future<void> _updateBackgroundMode(bool value) async => _updateSetting('backgroundMode', value, (val) => backgroundMode = val);
  Future<void> _updateNotifications(bool value) async => _updateSetting('notificationsEnabled', value, (val) => notificationsEnabled = val);
  Future<void> _updateNotificationInterval(double value) async => _updateSetting('notificationInterval', value, (val) => notificationInterval = val);
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool('darkMode') ?? false;
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;

      notificationInterval = prefs.getDouble('notificationInterval') ?? 15;
      blinkCalculationTime = prefs.getDouble('blinkCalculationTime') ?? 60;

      // 🔥 حماية القيم عشان ما تكسر السلايدر
      notificationInterval = notificationInterval.clamp(30, 180);
      blinkCalculationTime = blinkCalculationTime.clamp(30, 90);

      selectedLanguage = prefs.getString('selectedLanguage') ?? "العربية";
    });
  }


  Future<void> _updateLanguage(String language) async {
    await _updateSetting('selectedLanguage', language, (val) => selectedLanguage = val);
  }

  Future<void> _updateSetting<T>(String key, T value, Function(T) setter) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
    setState(() {
      setter(value);
    });
  }

  Color _getSliderColor(double value) {
    if (value <= 10) return Colors.yellow;
    if (value <= 20) return Colors.green;
    return Colors.red;
  }

  Color _getBlinkSliderColor(double value) {
    if (value <= 45) return Colors.yellow;
    if (value <= 75) return Colors.green;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkMode ? const Color(0xFF002134) : const Color.fromARGB(255, 145, 195, 209),
      appBar: AppBar(
        backgroundColor: darkMode ? const Color(0xFF002134) : const Color(0xff79a7b4),
        title: Text("settings".tr(), style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, darkMode),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            SwitchListTile(
              activeColor: const Color(0xFFffa08c),
              title: Text("dark_mode".tr(), style: _titleStyle),
              value: darkMode,
              onChanged: _updateDarkMode,
            ),
            SwitchListTile(
              activeColor: const Color(0xFFffa08c),
              title: Text("background_mode".tr(), style: _titleStyle),
              value: backgroundMode,
              onChanged: (value) {
                // حاليا بس نحفظ القيمة بدون تشغيل فعلي للخدمة
                _updateBackgroundMode(value);
              },
            ),
            SwitchListTile(
              activeColor: const Color(0xFFffa08c),
              title: Text("notifications_enabled".tr(), style: _titleStyle),
              value: notificationsEnabled,
              onChanged: _updateNotifications,
            ),

            const Divider(color: Colors.white, thickness: 2, height: 30),

            _buildSliderRow(
              "notification_interval".tr(),
              notificationInterval,
              30,
              180,
              30,   // كل 10 ثواني خطوة
              _updateNotificationInterval,
              _getSliderColor,
            ),



            _buildSliderRow(
              "blink_calculation_pause".tr(),
              blinkCalculationTime,
              30,
              90,
              2,
              _updateBlinkCalculationTime,
              _getBlinkSliderColor,
            ),


            const Divider(color: Colors.white, thickness: 2, height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "language".tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: selectedLanguage,
                    dropdownColor: darkMode ? const Color(0xFF002134) : Colors.white,
                    style: const TextStyle(color: Colors.black, fontSize: 18),
                    items: ["العربية", "English"].map((String language) {
                      return DropdownMenuItem<String>(
                        value: language,
                        child: Text(
                          language,
                          style: TextStyle(color: darkMode ? Colors.white : Colors.black),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) async {
                      if (newValue != null) {
                        await _updateLanguage(newValue);

                        if (newValue == "العربية") {
                          await context.setLocale(const Locale('ar'));
                        } else if (newValue == "English") {
                          await context.setLocale(const Locale('en'));
                        }

                        setState(() {
                          selectedLanguage = newValue;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("language_changed".tr()), // 🔥 رسالة تأكيد تغيير اللغة
                            backgroundColor: Colors.blueAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },

                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow(String title, double value, double min, double max, int divisions, ValueChanged<double> onChanged, Color Function(double) getColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: "${value.toInt()} ثانية",
          onChanged: onChanged,
          activeColor: getColor(value),
          inactiveColor: Colors.grey.withOpacity(0.3),
        ),
      ],
    );
  }
}




/*import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:restart_app/restart_app.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  bool isBackgroundServiceRunning = false;
  bool notificationsEnabled = false;
  double notificationInterval = 15;
  double blinkCalculationTime = 60;
  String selectedLanguage = "العربية"; // اللغة الافتراضية

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBackgroundServiceStatus();
  }

  /// **تحميل الإعدادات المحفوظة**
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool('darkMode') ?? false;
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
      notificationInterval = prefs.getDouble('notificationInterval') ?? 15;
      blinkCalculationTime = prefs.getDouble('blinkCalculationTime') ?? 60;
      selectedLanguage = prefs.getString('selectedLanguage') ?? "العربية";
    });
  }

  /// **تحديث اللغة وحفظها**
  Future<void> _updateLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);
    setState(() {
      selectedLanguage = language;
    });
  }

  /// **تحديث القيم الأخرى**
  Future<void> _updateDarkMode(bool value) async => _updateSetting('darkMode', value, (val) => darkMode = val);
  Future<void> _updateNotifications(bool value) async => _updateSetting('notificationsEnabled', value, (val) => notificationsEnabled = val);
  Future<void> _updateNotificationInterval(double value) async => _updateSetting('notificationInterval', value, (val) => notificationInterval = val);
  Future<void> _updateBlinkCalculationTime(double value) async => _updateSetting('blinkCalculationTime', value, (val) => blinkCalculationTime = val);

  /// **تحديث أي إعداد عام**
  Future<void> _updateSetting<T>(String key, T value, Function(T) setter) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
    setState(() {
      setter(value);
    });
  }

  /// **التحقق من تشغيل التطبيق في الخلفية**
  Future<void> _checkBackgroundServiceStatus() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    setState(() {
      isBackgroundServiceRunning = isRunning;
    });
  }

  /// **إرجاع لون الشريط بناءً على القيمة**
  Color _getSliderColor(double value) {
    if (value <= 10) return Colors.yellow;
    if (value <= 20) return Colors.green;
    return Colors.red;
  }

  Color _getBlinkSliderColor(double value) {
    if (value == 30) return Colors.yellow;
    if (value == 60) return Colors.green;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkMode ? const Color(0xFF002134) : const Color.fromARGB(255, 145, 195, 209),
      appBar: AppBar(
        backgroundColor: darkMode ? const Color(0xFF002134) : const Color(0xff79a7b4),
        title:  Text("settings".tr(), style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, darkMode),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              activeColor: const Color(0xFFffa08c),
              title:  Text("dark_mode".tr(), style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              value: darkMode,
              onChanged: _updateDarkMode,
            ),
            SwitchListTile(
              activeColor: const Color(0xFFffa08c),
              title:  Text("notification_interval".tr(), style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              value: isBackgroundServiceRunning,
              onChanged: _updateNotifications,
            ),
            SwitchListTile(
              activeColor: const Color(0xFFffa08c),
              title:  Text("notifications_enabled".tr(), style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              value: notificationsEnabled,
              onChanged: _updateNotifications,
            ),

            /// **خط فاصل بين الإعدادات السابقة والإعدادات التالية**
            const Divider(color: Colors.white, thickness: 2, height: 30),

            _buildSliderRow("notification_interval".tr(), notificationInterval, 5, 40, 7, _updateNotificationInterval, _getSliderColor),
          //  _buildSliderRow("blink_calculation_pause".tr() ,blinkCalculationTime, 30, 90, 2, _updateBlinkCalculationTime, _getBlinkSliderColor),

            /// **خط فاصل جديد قبل خيار اللغة** **خط فاصل جديد قبل خيار اللغة**
            const Divider(color: Colors.white, thickness: 2, height: 30),

            /// **اختيار اللغة**
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    "language".tr(),
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: selectedLanguage,
                    dropdownColor: darkMode ? const Color(0xFF002134) : Colors.white,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    items: ["العربية", "English"].map((String language) {
                      return DropdownMenuItem<String>(
                        value: language,
                        child: Text(
                          language,
                          style: TextStyle(color: darkMode ? Colors.white : Colors.black),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        if (newValue == "العربية") {
                          context.setLocale(const Locale('ar'));
                          Restart.restartApp();
                        } else if (newValue == "English") {
                          context.setLocale(const Locale('en'));
                          Restart.restartApp();

                        }
                      }
                    },

                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  /// **إنشاء عنصر لشريط التمرير (Slider)**
  Widget _buildSliderRow(String title, double value, double min, double max, int divisions, ValueChanged<double> onChanged, Color Function(double) getColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: "${value.toInt()} ثانية",
          onChanged: onChanged,
          activeColor: getColor(value),
          inactiveColor: Colors.grey.withOpacity(0.3),
        ),
      ],
    );
  }
}*/