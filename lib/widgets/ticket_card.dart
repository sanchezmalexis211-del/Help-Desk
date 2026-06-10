import 'package:flutter/material.dart';
import '../core/theme.dart';

class TicketCard extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color colorEstado;
  final String tiempo;

  const TicketCard({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.colorEstado,
    required this.tiempo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorEstado.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icono, color: colorEstado, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descripcion,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                Text(
                  tiempo,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorEstado),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}