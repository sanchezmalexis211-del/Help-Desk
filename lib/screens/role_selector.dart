import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'employee/home_screen.dart';
import 'technician/tech_dashboard.dart';
// TODO: Crea este archivo o comenta la línea si aún no lo tienes
// import 'admin/admin_dashboard.dart'; 

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Help Desk', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Selecciona tu entorno de prueba para la revisión.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 48),
              
              // 1. ROL: USUARIO / EMPLEADO
              _buildRoleCard(
                context,
                'Portal Empleado (Usuario)',
                Icons.person_outline,
                Colors.white,
                AppTheme.textPrimary,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
              ),
              const SizedBox(height: 20),
              
              // 2. ROL: TÉCNICO / AGENTE
              _buildRoleCard(
                context,
                'Consola Técnico (Agente)',
                Icons.support_agent_rounded,
                Colors.white,
                AppTheme.textPrimary,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TechDashboardScreen())),
              ),
              const SizedBox(height: 20),

              // 3. ROL: SYSADMIN (NUEVO)
              _buildRoleCard(
                context,
                'Panel Sysadmin (Control Total)',
                Icons.admin_panel_settings_rounded,
                AppTheme.textPrimary, // Fondo negro para darle jerarquía
                Colors.white,         // Texto blanco
                () {
                  // Reemplaza esto con la ruta real a tu vista de administrador
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vista Sysadmin en construcción...')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, String title, IconData icon, Color bg, Color text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: text),
            const SizedBox(width: 20),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: text)),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: text.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}