import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'screens/auth_wrapper.dart';
import 'services/push_notification_service.dart'; // <-- IMPORTAMOS EL SERVICIO DE NOTIFICACIONES

void main() async {
  // Asegura que los bindings de Flutter estén listos antes de ejecutar código nativo
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializamos Firebase con la configuración generada para este proyecto
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // <-- INICIAMOS EL "OÍDO" PARA LAS NOTIFICACIONES PUSH -->
  await PushNotificationService.initializeApp(); 

  runApp(const HelpDeskApp());
}

class HelpDeskApp extends StatelessWidget {
  const HelpDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Help Desk Pro',
      theme: AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      home: const AuthWrapper(), 
    );
  }
}