import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../../core/theme.dart';
import '../../widgets/ticket_card.dart';
import '../../widgets/shimmer_ticket.dart';
import '../../models/ticket_model.dart';
import '../shared/ticket_detail_screen.dart';
 
class TechDashboardScreen extends StatelessWidget {
  const TechDashboardScreen({super.key});
 
  void _abrirPanelAccion(BuildContext context, TicketModel ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ActionSheetTecnico(ticket: ticket),
      ),
    );
  }
 
  void _verDetallesResuelto(BuildContext context, TicketModel ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.history_rounded, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Bitácora del Ticket',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetalleFila('Equipo / Categoría:', ticket.categoria),
            const SizedBox(height: 8),
            if (ticket.subcategoria.isNotEmpty)
              _buildDetalleFila('Subcategoría:', ticket.subcategoria),
            const SizedBox(height: 12),
            _buildDetalleFila('Falla Reportada:', ticket.descripcion),
            const SizedBox(height: 12),
            _buildDetalleFila('Diagnóstico Técnico:', ticket.notaTecnica ?? 'Sin nota'),
            const SizedBox(height: 12),
            _buildDetalleFila('Tiempo que tomó:', ticket.tiempoEstimado ?? 'No especificado'),
            const SizedBox(height: 12),
            _buildDetalleFila('Fecha de creación:', _formatearFecha(ticket.fechaCreacion)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketDetailScreen(
                    ticketId: ticket.id!,
                    data: {
                      'categoria': ticket.categoria,
                      'descripcion': ticket.descripcion,
                      'prioridad': ticket.prioridad,
                      'estado': ticket.estado,
                      'notaTecnica': ticket.notaTecnica,
                    },
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('💬 Comentarios', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppTheme.textPrimary),
            child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
 
  Widget _buildDetalleFila(String titulo, String valor) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87, fontSize: 14, fontFamily: 'Roboto'),
        children: [
          TextSpan(
              text: '$titulo\n',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          TextSpan(text: valor, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
 
  String _formatearFecha(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year} a las $hora:$minuto hrs';
  }
 
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
 
    return DefaultTabController(
      length: 3, // ← AHORA SON 3 PESTAÑAS
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Consola de Control'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              tooltip: 'Cerrar Sesión',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
            )
          ],
          bottom: const TabBar(
            labelColor: AppTheme.textPrimary,
            indicatorColor: AppTheme.textPrimary,
            tabs: [
              Tab(text: 'Asignados'),
              Tab(text: 'Refacción'),   // ← NUEVA PESTAÑA
              Tab(text: 'Resueltos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ==========================================
            // PESTAÑA 1: ASIGNADOS
            // ==========================================
            _buildTicketList(
              currentUser: currentUser,
              estado: 'Asignado',
              emptyMessage: 'No tienes tickets asignados.',
              onTap: (context, ticket) => _abrirPanelAccion(context, ticket),
              showRecenteBadge: true,
            ),
 
            // ==========================================
            // PESTAÑA 2: REFACCIÓN (esperando pieza)
            // ==========================================
            _buildTicketList(
              currentUser: currentUser,
              estado: 'Refacción',
              emptyMessage: 'No hay tickets esperando pieza.',
              onTap: (context, ticket) => _abrirPanelAccion(context, ticket),
              showRecenteBadge: false,
              colorEstado: Colors.orange,
            ),
 
            // ==========================================
            // PESTAÑA 3: RESUELTOS
            // ==========================================
            _buildTicketList(
              currentUser: currentUser,
              estado: 'Resuelto',
              emptyMessage: 'No hay tickets resueltos.',
              onTap: (context, ticket) => _verDetallesResuelto(context, ticket),
              showRecenteBadge: false,
              colorEstado: Colors.green,
              iconoFijo: Icons.check_circle_rounded,
              descripcionFn: (ticket) => ticket.notaTecnica ?? 'Sin nota técnica',
              tiempoFijo: 'Ver detalles',
            ),
          ],
        ),
      ),
    );
  }
 
  // Widget reutilizable para las 3 pestañas
  Widget _buildTicketList({
    required User? currentUser,
    required String estado,
    required String emptyMessage,
    required void Function(BuildContext, TicketModel) onTap,
    required bool showRecenteBadge,
    Color? colorEstado,
    IconData? iconoFijo,
    String Function(TicketModel)? descripcionFn,
    String? tiempoFijo,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tickets')
          .where('estado', isEqualTo: estado)
          .where('agenteAsignado', isEqualTo: currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: 3,
            itemBuilder: (_, __) => const ShimmerTicket(),
          );
        }
 
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }
 
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(emptyMessage,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 16)),
          );
        }
 
        final tickets = snapshot.data!.docs
            .map((doc) =>
                TicketModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
 
        // Ordenar por prioridad para Asignados y Refacción
        if (estado != 'Resuelto') {
          tickets.sort((a, b) {
            final prioridades = {'Crítica': 4, 'Alta': 3, 'Media': 2, 'Baja': 1};
            return (prioridades[b.prioridad] ?? 0)
                .compareTo(prioridades[a.prioridad] ?? 0);
          });
        } else {
          tickets.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
        }
 
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final ticket = tickets[index];
 
            IconData iconData = iconoFijo ?? _iconoCategoria(ticket.categoria);
            Color statusColor = colorEstado ?? _colorPrioridad(ticket.prioridad);
 
            bool procesadoPorIA =
                ticket.notaTecnica != null && ticket.notaTecnica!.isNotEmpty;
            String textoPrioridad = tiempoFijo ?? 'Prioridad: ${ticket.prioridad}';
            if (procesadoPorIA && tiempoFijo == null) textoPrioridad += ' ⚡';
 
            final esMuyReciente =
                DateTime.now().difference(ticket.fechaCreacion).inHours < 24;
 
            return InkWell(
              onTap: () => onTap(context, ticket),
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  TicketCard(
                    titulo: ticket.subcategoria.isNotEmpty
                        ? '${ticket.categoria} - ${ticket.subcategoria}'
                        : ticket.categoria,
                    descripcion: descripcionFn != null
                        ? descripcionFn(ticket)
                        : (procesadoPorIA
                            ? ticket.notaTecnica!
                            : ticket.descripcion),
                    icono: iconData,
                    colorEstado: statusColor,
                    tiempo: textoPrioridad,
                  ),
                  if (showRecenteBadge && esMuyReciente)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fiber_new_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('RECIENTE',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5)),
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
    );
  }
 
  IconData _iconoCategoria(String categoria) {
    if (categoria.contains('Red')) return Icons.wifi_off_rounded;
    if (categoria.contains('POS') || categoria.contains('Caja'))
      return Icons.point_of_sale_rounded;
    if (categoria.contains('CCTV')) return Icons.videocam_rounded;
    if (categoria.contains('Base de Datos')) return Icons.dns_rounded;
    if (categoria.contains('Impresora')) return Icons.print_rounded;
    return Icons.computer_rounded;
  }
 
  Color _colorPrioridad(String prioridad) {
    if (prioridad == 'Crítica' || prioridad == 'Alta') return AppTheme.alertCritical;
    if (prioridad == 'Baja') return Colors.blueGrey;
    return AppTheme.alertMedium;
  }
}
 
// =========================================================================
// WIDGET DEL PANEL EMERGENTE
// =========================================================================
class ActionSheetTecnico extends StatefulWidget {
  final TicketModel ticket;
  const ActionSheetTecnico({super.key, required this.ticket});
 
  @override
  State<ActionSheetTecnico> createState() => _ActionSheetTecnicoState();
}
 
class _ActionSheetTecnicoState extends State<ActionSheetTecnico> {
  final TextEditingController _notaController = TextEditingController();
  String _tiempoSeleccionado = '15 min';
  bool _isSaving = false;
 
  final List<String> _tiempos = ['15 min', '1 hr', 'Hoy', 'Refacción'];
 
  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }
 
  Future<void> _guardar() async {
    setState(() => _isSaving = true);
 
    // ← FIX CLAVE: si el tiempo es 'Refacción', el estado es 'Refacción', no 'Resuelto'
    final String nuevoEstado =
        _tiempoSeleccionado == 'Refacción' ? 'Refacción' : 'Resuelto';
 
    try {
      await FirebaseFirestore.instance
          .collection('tickets')
          .doc(widget.ticket.id)
          .update({
        'estado': nuevoEstado,
        'notaTecnica': _notaController.text.trim(),
        'tiempoEstimado': _tiempoSeleccionado,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al guardar: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final esRefaccion = _tiempoSeleccionado == 'Refacción';
 
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Falla original: ${widget.ticket.descripcion}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          const Text('Nota de Diagnóstico:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notaController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: esRefaccion
                  ? 'Ej. Se requiere cambiar fuente de poder...'
                  : 'Ej. Se requiere cambiar cable UTP...',
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Tiempo requerido:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _tiempos.map((tiempo) {
              final isSelected = _tiempoSeleccionado == tiempo;
              final esOpcionRefaccion = tiempo == 'Refacción';
              return ChoiceChip(
                label: Text(tiempo),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _tiempoSeleccionado = tiempo);
                },
                selectedColor:
                    esOpcionRefaccion ? Colors.orange : AppTheme.textPrimary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
 
          // Aviso visual cuando selecciona Refacción
          if (esRefaccion) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El ticket quedará en estado "Esperando Pieza". El usuario verá este aviso.',
                      style: TextStyle(
                          color: Colors.orange.shade800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
 
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TicketDetailScreen(
                      ticketId: widget.ticket.id!,
                      data: {
                        'categoria': widget.ticket.categoria,
                        'descripcion': widget.ticket.descripcion,
                        'prioridad': widget.ticket.prioridad,
                        'estado': widget.ticket.estado,
                        'notaTecnica': widget.ticket.notaTecnica,
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.comment_rounded, size: 18),
              label: const Text('Ver / Agregar Comentarios'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: esRefaccion ? Colors.orange : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      esRefaccion
                          ? '⏳ Marcar como Esperando Pieza'
                          : '✅ Guardar y Marcar Resuelto',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}