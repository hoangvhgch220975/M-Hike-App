import 'package:flutter/material.dart';
import 'welcome.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();

    // Chuyển sang màn hình welcome sau khi animation hoàn thành
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const WelcomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Fade transition với curve mượt mà hơn
              const fadeBegin = 0.0;
              const fadeEnd = 1.0;
              const fadeCurve = Curves.easeInOutCubic;

              var fadeTween = Tween(begin: fadeBegin, end: fadeEnd).chain(CurveTween(curve: fadeCurve));
              var fadeAnimation = animation.drive(fadeTween);

              // Slide transition từ dưới lên nhẹ nhàng
              const slideBegin = Offset(0.0, 0.08);
              const slideEnd = Offset.zero;
              const slideCurve = Curves.easeOutCubic;

              var slideTween = Tween(begin: slideBegin, end: slideEnd).chain(CurveTween(curve: slideCurve));
              var slideAnimation = animation.drive(slideTween);

              // Scale transition nhẹ
              const scaleBegin = 0.96;
              const scaleEnd = 1.0;

              var scaleTween = Tween(begin: scaleBegin, end: scaleEnd).chain(CurveTween(curve: fadeCurve));
              var scaleAnimation = animation.drive(scaleTween);

              return SlideTransition(
                position: slideAnimation,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    child: child,
                  ),
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 900),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Hiển thị logo từ assets
                Image.asset(
                  'lib/assets/images/hike_logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 24),

                const Text(
                  "M-Hike",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),

            // Progress Bar
            Positioned(
              bottom: 64,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _progress,
                builder: (context, child) {
                  return Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _progress.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
