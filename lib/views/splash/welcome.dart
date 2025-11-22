import 'package:flutter/material.dart';
import '../shared/navbar.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Image Section
            Container(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    "https://lh3.googleusercontent.com/aida-public/AB6AXuDMFbB5yR0KJA00XSG6IPJxtpyP4w09eJ_3F8b_7DzgqsT94K7zp8R6KaQ-ceTTc7bLFMU5qF5hpZV17xZgZ7zLjSuQ_9LqjVuC_mPj8b5rnkt8rKSabON9LY32dJzFX_Ze9l_GsuTB3uvkCEhFak626Ttz3ad9ZCwi8Ufism4hFq_5s06kt_6r194BiZmrUepoRAMQW2Ei2UyKRoANbfV3rTH5KEJLfH7VAULKCdYR9v9f1ezGp9Yh9OfdjipPxh5YpgLKxSRYBK13",
                  ),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),

            // Text Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: const [
                        Text(
                          "Your Adventure Awaits",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),

                        SizedBox(height: 12),

                        Text(
                          "Discover new trails, record your hikes, and relive your favorite outdoor moments.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),

                    // Button Explore
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const MainNavbar(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                // Fade transition kết hợp slide từ dưới lên
                                const begin = Offset(0.0, 0.3);
                                const end = Offset.zero;
                                const curve = Curves.easeInOutCubic;

                                var slideTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                var slideAnimation = animation.drive(slideTween);

                                var fadeTween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
                                var fadeAnimation = animation.drive(fadeTween);

                                return SlideTransition(
                                  position: slideAnimation,
                                  child: FadeTransition(
                                    opacity: fadeAnimation,
                                    child: child,
                                  ),
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 600),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF13EC37),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text(
                          "Explore",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF102213),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
