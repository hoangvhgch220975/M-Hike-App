
// lib/views/feed/empty_feed_view.dart

import 'package:flutter/material.dart';

class EmptyFeedView extends StatelessWidget {
  const EmptyFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = _FeedColors();

    return Scaffold(
      backgroundColor: colors.lightGrey,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                // HEADER - Same as feed_view
                _buildHeader(colors),

                const SizedBox(height: 40),

                // EMPTY STATE CONTENT
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ILLUSTRATION IMAGE
                        SizedBox(
                          height: 240,
                          width: 240,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              "https://lh3.googleusercontent.com/aida-public/AB6AXuC8Cpp1dGMKyQG12tmVi-BWG_KS6jDfv_EI4aFnDW8hpeJxLrR5JAur5LW0zfGzgCPOrvJsljL9j42_PShKrMpGq42g94KqwA2DUms5WUJmeqpF-mvLwXdFTdWY48IHoawxszAkj4jzEQOeHng8-jIMlta-0TMol11NhAad4GUMcCtanBe75s8LUKMdQDsHPSiFNIBapa_MKc_o03eiXXQW1LnWbTaVJlOpqaI4dh-ect3leEOYzmOKR5RRz4RCTYTDSl-xu4T0YBH-",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // TITLE + DESCRIPTION
                        Text(
                          "Your Adventure Awaits",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colors.darkText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Looks like you haven't completed a hike yet. Every great journey starts with a single step.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.darkGrey,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to create hike or plan view
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.forestGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              elevation: 6,
                              shadowColor: colors.forestGreen.withOpacity(0.3),
                            ),
                            child: const Text(
                              "Start Your First Hike",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // HEADER - Same as feed_view
  Widget _buildHeader(_FeedColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: colors.lightGrey.withOpacity(0.9),
      child: Row(
        children: [
          Image.asset(
            'lib/assets/images/hike_logo.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          const Text(
            "Hike Feed",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, size: 28, color: Color(0xFF1F2937)),
          ),
        ],
      ),
    );
  }
}

// COLOR PALETTE - Same as feed_view
class _FeedColors {
  final Color forestGreen = const Color(0xFF225749);
  final Color skyBlue = const Color(0xFF89CFF0);
  final Color earthBrown = const Color(0xFFA1887F);
  final Color lightGrey = const Color(0xFFF5F5F5);
  final Color darkGrey = const Color(0xFF6B7280);
  final Color darkText = const Color(0xFF1F2937);
}

