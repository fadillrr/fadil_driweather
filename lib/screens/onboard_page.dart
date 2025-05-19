import 'package:flutter/material.dart';
import 'home_page.dart';

class OnboardPage extends StatelessWidget {
  const OnboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 137, 196, 255),
                  Color.fromARGB(255, 255, 255, 255),
                ],
              ),
            ),
          ),

          // Circular lines
          Positioned.fill(child: CustomPaint(painter: CircularLinesPainter())),

          // Top-left circle (posisi responsif, ukuran fixed)
          Positioned(
            top: size.height * 0.1,
            left: size.width * -0.05,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color.fromARGB(255, 252, 209, 143),
                    Color(0xFFFF7C00),
                  ],
                  center: Alignment.topLeft,
                  radius: 0.8,
                ),
              ),
            ),
          ),

          // Cloud circles - posisi responsif, ukuran fixed
          Positioned(
            bottom: size.height * 0.20,
            left: size.width * 0.04,
            child: Container(
              width: 350,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEAF4FE),
              ),
            ),
          ),

          Positioned(
            bottom: size.height * 0.15,
            left: size.width * 0.19,
            child: Container(
              width: 350,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEAF4FE),
              ),
            ),
          ),

          Positioned(
            bottom: size.height * 0.3,
            right: size.width * -0.50,
            child: Container(
              width: 400,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEAF4FE),
              ),
            ),
          ),

          // Content
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 90),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Never get caught\nin the rain again",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Stay ahead of the weather with our accurate forecasts",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 90,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.black26,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Get Started",
                      style: TextStyle(
                        color: Color(0xFF4D4D7F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CircularLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha((0.4 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width * 0.9, size.height * 0.3);

    for (double radius in [80, 165, 245, 320]) {
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
