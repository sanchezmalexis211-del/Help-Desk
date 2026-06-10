import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../core/theme.dart';
import 'role_selector.dart'; // <-- ¡CORREGIDO! Ahora están en la misma carpeta

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _iniciarCarga();
  }

  Future<void> _iniciarCarga() async {
    // Simulamos que la app está cargando configuraciones iniciales (3 segundos)
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    // Navegamos a la selección de roles y destruimos el splash screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RoleSelectorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animación desde la nube
            Lottie.network(
              'https://lottie.host/9f50f449-74d3-4876-b6fb-cfa8b5d38a0a/rVfA4Q7W1s.json', 
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 32),
            const Text(
              'Help Desk',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Inicializando entorno...',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}