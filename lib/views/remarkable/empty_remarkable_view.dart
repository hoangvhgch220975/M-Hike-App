import 'package:flutter/material.dart';

class EmptyRemarkableView extends StatelessWidget {
  const EmptyRemarkableView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6), // background-light

      // ❗ AppBar đã bỏ back + filter icon
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        automaticallyImplyLeading: false, // bỏ nút back auto
        centerTitle: true,
        title: const Text(
          'Remarkable Hikes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // === Illustration ===
                  SizedBox(
                    width: 260,
                    child: CustomPaint(
                      size: const Size(200, 150),
                      painter: MountainIllustrationPainter(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // === Title ===
                  const Text(
                    "Your Most Memorable Adventures",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3A56),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // === Description ===
                  const SizedBox(
                    width: 260,
                    child: Text(
                      "This is where hikes you mark as 'remarkable' will appear. Go back to your hike history to select your favorites.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6C757D),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // === Button ===
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3A56),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "View My Hikes",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// === Painter cho illustration trong HTML ===
// (Không cần y hệt 100%, chỉ cần giống tinh thần line-art)
class MountainIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF89CFF0).withOpacity(0.2),
          const Color(0xFF89CFF0).withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final mountainPath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.9)
      ..lineTo(size.width * 0.5, size.height * 0.35)
      ..lineTo(size.width * 0.6, size.height * 0.55)
      ..lineTo(size.width * 0.75, size.height * 0.9)
      ..close();

    canvas.drawPath(mountainPath, skyPaint);

    final outline = Paint()
      ..color = const Color(0xFF6C757D)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final outlinePath = Path()
      ..moveTo(0, size.height * 0.9)
      ..lineTo(size.width * 0.25, size.height * 0.7)
      ..lineTo(size.width * 0.5, size.height * 0.35)
      ..lineTo(size.width * 0.6, size.height * 0.55)
      ..lineTo(size.width * 0.75, size.height * 0.9)
      ..lineTo(size.width, size.height * 0.75);

    canvas.drawPath(outlinePath, outline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
