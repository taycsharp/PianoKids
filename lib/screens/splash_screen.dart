import 'dart:async';

import 'package:flutter/material.dart';

import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _turn;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _turn = Tween<double>(begin: -0.05, end: 0.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _navigationTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF77A9), Color(0xFF8E7CFF), Color(0xFF5BC0EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotationTransition(
                turns: _turn,
                child: const Text('🎹', style: TextStyle(fontSize: 96)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Happy Piano Kids',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 38, color: Colors.white, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              const Text(
                'Learn piano with stars!',
                style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 36),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
