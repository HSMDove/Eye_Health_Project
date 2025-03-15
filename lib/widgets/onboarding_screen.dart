import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/ui_elements.dart';
import '../management/camera_manager.dart'; // ✅ إضافة CameraManager

class OnboardingScreen extends StatefulWidget {
  final CameraManager cameraManager; // ✅ استلام cameraManager

  const OnboardingScreen({super.key, required this.cameraManager});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CameraScreen(cameraManager: widget.cameraManager)), // ✅ تمرير cameraManager
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          _buildPage(
            title: "مرحبًا بك في تطبيق صحة العين!",
            description: "تطبيق يساعدك على مراقبة صحة عينيك من خلال تحليل معدل الرمشات.",
            image: "assets/images/onboarding1.png",
          ),
          _buildPage(
            title: "كيف يعمل التطبيق؟",
            description: "يقوم التطبيق بتحليل معدل رمشاتك وينبهك إذا كان هناك خلل في النمط الطبيعي.",
            image: "assets/images/onboarding2.png",
          ),
          _buildPage(
            title: "جاهز للبدء؟",
            description: "اضغط على الزر أدناه للانتقال إلى التطبيق والبدء في استخدامه!",
            image: "assets/images/onboarding3.png",
          ),
        ],
      ),
      bottomSheet: _currentPage == 2
          ? _buildStartButton()
          : _buildNextButton(),
    );
  }

  Widget _buildPage({required String title, required String description, required String image}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(image, height: 250),
          const SizedBox(height: 30),
          Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Text(description, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          _pageController.nextPage(duration: Duration(milliseconds: 500), curve: Curves.ease);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text("التالي", style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _completeOnboarding,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text("ابدأ استخدام التطبيق", style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }
}
