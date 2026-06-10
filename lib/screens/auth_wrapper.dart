import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'employee/home_screen.dart';
import 'technician/tech_dashboard.dart';
import 'admin/admin_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final user = snapshot.data!;
        return FutureBuilder<String>(
          future: AuthService().obtenerRolUsuario(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Si algo falla, roleSnapshot.data será null → va a HomeScreen
            final rol = roleSnapshot.data ?? 'usuario';

            if (rol == 'sysadmin') {
              return const AdminDashboard();
            } else if (rol == 'tecnico') {
              return const TechDashboardScreen();
            } else {
              return const HomeScreen();
            }
          },
        );
      },
    );
  }
}