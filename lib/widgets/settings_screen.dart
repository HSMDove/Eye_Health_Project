import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import '../management/notification_manager.dart';
import '../management/blink_evaluator.dart';
import '../management/blink_counter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  bool notificationsEnabled = false;
  double notificationInterval = 15;
  double blinkCalculationTime = 60;
  String selectedLanguage = "العربية";

  final BlinkEvaluator blinkEvaluator = BlinkEvaluator(
    blinkCounter: BlinkCounter(),
    onEvaluationComplete: (_) {},
  );

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool('darkMode') ?? false;
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
      notificationInterval = prefs.getDouble('notificationInterval') ?? 15;
      blinkCalculationTime = prefs.getDouble('blinkCalculationTime') ?? 60;
      selectedLanguage = prefs.getString('selectedLanguage') ?? "العربية";
    });

    blinkEvaluator.updateTimings(
      newIntervalSeconds: blinkCalculationTime.toInt(),
      newEvaluationDurationSeconds: blinkCalculationTime.toInt(),
      newNotificationMinutes: notificationInterval.toInt(),
    );

    if (notificationsEnabled) {
      await NotificationManager.toggleNotifications(true);
      await NotificationManager.updateNotificationInterval(notificationInterval);
    }
  }

  Future<void> _updateLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);
    setState(() {
      selectedLanguage = language;
    });

    if (language == "العربية") {
      await context.setLocale(const Locale('ar'));
    } else if (language == "English") {
      await context.setLocale(const Locale('en'));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("language_changed".tr()),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _updateSetting<T>(String key, T value, Function(T) setter) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is double) await prefs.setDouble(key, value);
    if (value is String) await prefs.setString(key, value);

    setState(() {
      setter(value);
    });
  }

  Future<void> _updateDarkMode(bool value) async =>
      _updateSetting('darkMode', value, (val) => darkMode = val);

  Future<void> _updateNotifications(bool value) async {
    await _updateSetting('notificationsEnabled', value, (val) => notificationsEnabled = val);
    await NotificationManager.toggleNotifications(value);
  }

  Future<void> _updateNotificationInterval(double value) async {
    await _updateSetting('notificationInterval', value, (val) => notificationInterval = val);
    if (notificationsEnabled) {
      await NotificationManager.updateNotificationInterval(value);
    }
    blinkEvaluator.updateTimings(
      newIntervalSeconds: blinkCalculationTime.toInt(),
      newEvaluationDurationSeconds: blinkCalculationTime.toInt(),
      newNotificationMinutes: value.toInt(),
    );
  }

  Future<void> _updateBlinkCalculationTime(double value) async {
    await _updateSetting('blinkCalculationTime', value, (val) => blinkCalculationTime = val);
    blinkEvaluator.updateTimings(
      newIntervalSeconds: value.toInt(),
      newEvaluationDurationSeconds: value.toInt(),
      newNotificationMinutes: notificationInterval.toInt(),
    );
  }

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
      backgroundColor:
      darkMode ? const Color(0xFF002134) : const Color.fromARGB(255, 145, 195, 209),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              activeColor: const Color(0xFFffa08c),
              title: Text("dark_mode".tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              value: darkMode,
              onChanged: _updateDarkMode,
            ),
            SwitchListTile(
              activeColor: const Color(0xFFffa08c),
              title: Text("notifications_enabled".tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              value: notificationsEnabled,
              onChanged: _updateNotifications,
            ),
            const Divider(color: Colors.white, thickness: 2, height: 30),
            _buildSliderRow("notification_interval".tr(), notificationInterval, 5, 40, 7,
                _updateNotificationInterval, _getSliderColor),
            _buildSliderRow("blink_calculation_pause".tr(), blinkCalculationTime, 30, 90, 2,
                _updateBlinkCalculationTime, _getBlinkSliderColor),
            const Divider(color: Colors.white, thickness: 2, height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "language".tr(),
                    style:
                    const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                      if (newValue != null) _updateLanguage(newValue);
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

  Widget _buildSliderRow(String title, double value, double min, double max, int divisions,
      ValueChanged<double> onChanged, Color Function(double) getColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: "${value.toInt()} ${title.contains("interval") ? "دقيقة" : "ثانية"}",
          onChanged: onChanged,
          activeColor: getColor(value),
          inactiveColor: Colors.grey.withOpacity(0.3),
        ),
      ],
    );
  }
}
