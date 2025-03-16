import 'package:eye_health/widgets/ui_elements.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../management/camera_manager.dart';

class OnboardingScreen extends StatefulWidget {
  final CameraManager cameraManager;

  const OnboardingScreen({super.key, required this.cameraManager});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.fastOutSlowIn),
    );

    _animationController.forward();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CameraScreen(cameraManager: widget.cameraManager),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var tween = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.fastOutSlowIn));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002134),
      body: PageView(
        controller: _pageController,
        physics: _currentPage == 0
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
            _animationController.reset();
            _animationController.forward();
          });
        },
        children: [
          _buildPage(
            title: "مرحبًا بك في تطبيق صحة العين!",
            description: "تطبيق يساعدك على مراقبة صحة عينيك من خلال تحليل معدل الرمشات.",
            image: "assets/images/eye_image.png",
            buttonRow: _buildNextButton(),
          ),
          _buildPage(
            title: "كيف يعمل التطبيق؟",
            description: "التطبيق يقوم بحساب عدد رمشاتك من خلال الكاميرا , ثم يقيم و يحلل هذه الرمشات , وسيتم تنبيهك بحالة رمشاتك",
            image: "assets/images/count_image.png",
            buttonRow: _buildNavigationButtons(),
          ),
          _buildPage(
            title: "جاهز للبدء؟",
            description: "اضغط على الزر أدناه للانتقال إلى التطبيق والبدء في استخدامه!",
            image: "assets/images/next_image.png",
            buttonRow: _buildNavigationButtons(isFinal: true),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required String image,
    required Widget buttonRow,
  }) {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(image, height: 350),
              const SizedBox(height: 0),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFA08C),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FadeTransition(
          opacity: _fadeAnimation,
          child: buttonRow,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  /// **زر "التالي" بدون زر الرجوع (للصفحة الأولى فقط)**
  Widget _buildNextButton() {
    return Center(
      child: _buildCustomButton(
        label: "التالي",
        onPressed: () {
          if (_currentPage < 2) {
            _animationController.reverse().then((_) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.fastOutSlowIn,
              );
            });
          }
        },
      ),
    );
  }

  /// **شريط يحتوي على زر "رجوع" و "التالي"**
  Widget _buildNavigationButtons({bool isFinal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCustomButton(
          label: "رجوع",
          onPressed: () {
            if (_currentPage > 0) {
              _animationController.reverse().then((_) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.fastOutSlowIn,
                );
              });
            }
          },
        ),
        _buildCustomButton(
          label: isFinal ? "ابدأ استخدام التطبيق" : "التالي",
          onPressed: isFinal
              ? () {
            _animationController.reverse().then((_) {
              _completeOnboarding();
            });
          }
              : () {
            if (_currentPage < 2) {
              _animationController.reverse().then((_) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.fastOutSlowIn,
                );
              });
            }
          },
        ),
      ],
    );
  }

  /// **دالة لإنشاء زر موحد التصميم**
  Widget _buildCustomButton({required String label, required VoidCallback onPressed}) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA08C).withOpacity(0.35),
            blurRadius: 30,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: label == "ابدأ استخدام التطبيق" ? const Color(0xFFFFA08C) : const Color(0xFF002134),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: Color(0xFFFFA08C), width: 2),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 10,
          shadowColor: Colors.transparent,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            color: label == "ابدأ استخدام التطبيق" ? const Color(0xFF002134) : const Color(0xFFFFA08C),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
