import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../widgets/ticket_card.dart';
import 'new_ticket.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Devuelve color e ícono según el estado del ticket
  ({Color color, IconData icono, String etiqueta}) _infoEstado(String estado) {
    switch (estado) {
      case 'Asignado':
        return (
          color: Colors.blueAccent,
          icono: Icons.person_pin_rounded,
          etiqueta: 'Asignado a técnico',
        );
      case 'Refacción':
        return (
          color: Colors.orange,
          icono: Icons.build_circle_rounded,
          etiqueta: '⏳ Esperando pieza',
        );
      case 'Resuelto':
        return (
          color: Colors.green,
          icono: Icons.check_circle_rounded,
          etiqueta: '✅ Resuelto',
        );
      case 'Nuevos':
      default:
        return (
          color: Colors.grey.shade500,
          icono: Icons.schedule_rounded,
          etiqueta: 'Pendiente de asignación',
        );
    }
  }

  // Devuelve ícono según categoría
  IconData _iconoCategoria(String categoria) {
    final c = categoria.toLowerCase();
    if (c.contains('pos') || c.contains('caja')) return Icons.point_of_sale_rounded;
    if (c.contains('red') || c.contains('router')) return Icons.wifi_tethering_error_rounded;
    if (c.contains('cctv')) return Icons.videocam_off_rounded;
    if (c.contains('impresora')) return Icons.print_rounded;
    if (c.contains('base de datos')) return Icons.dns_rounded;
    return Icons.computer_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mis Reportes',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .where('usuarioId', isEqualTo: currentUser?.uid)
            .orderBy('fechaCreacion', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.black));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded,
                      size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No tienes reportes activos.',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Toca el botón para crear uno.',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            );
          }

          final tickets = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            physics: const BouncingScrollPhysics(),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final data = tickets[index].data() as Map<String, dynamic>;

              final String categoria = data['categoria'] ?? 'General';
              final String descripcion = data['descripcion'] ?? 'Sin descripción';
              final String prioridad = data['prioridad'] ?? 'Media';
              final String estado = data['estado'] ?? 'Nuevos';

              final info = _infoEstado(estado);

              // Badge de prioridad solo si es crítica o alta
              final bool esCritica =
                  prioridad == 'Crítica' || prioridad == 'Alta';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TicketCard(
                      titulo: categoria,
                      descripcion: descripcion,
                      icono: _iconoCategoria(categoria),
                      colorEstado: info.color,
                      tiempo: info.etiqueta,
                    ),

                    // Badge de prioridad alta/crítica
                    if (esCritica && estado != 'Resuelto')
                      Positioned(
                        top: -6,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            prioridad == 'Crítica'
                                ? '🚨 Crítica'
                                : '⚠️ Alta',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // Banner especial para Refacción
                    if (estado == 'Refacción')
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(16)),
                            border: Border(
                              top: BorderSide(
                                  color: Colors.orange.shade200, width: 1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 14, color: Colors.orange.shade700),
                              const SizedBox(width: 6),
                              Text(
                                'Tu técnico está gestionando una pieza de repuesto',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewTicketScreen()),
        ),
        backgroundColor: Colors.black,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo Reporte',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}