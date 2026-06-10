import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import 'register_user_screen.dart';
import 'subcategory_manager_screen.dart';
import 'ticket_report_screen.dart';
 
/// Dashboard principal del administrador.
/// Ruta: lib/screens/admin/admin_dashboard.dart
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
 
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}
 
class _AdminDashboardState extends State<AdminDashboard> {
  final _db = FirebaseFirestore.instance;
  String _filtroEstado = 'Todos';
  String? _filtroTecnico;
  Map<String, String> _tecnicosMap = {}; // uid → nombre
 
  final List<String> _estados = [
    'Todos', 'Asignado', 'Refacción', 'Resuelto', 'Sin asignar'
  ];
 
  @override
  void initState() {
    super.initState();
    _cargarTecnicos();
  }
 
  Future<void> _cargarTecnicos() async {
    final snap = await _db
        .collection('usuarios')
        .where('rol', isEqualTo: 'tecnico')
        .get();
    final map = <String, String>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      map[doc.id] = data['nombre'] ?? data['email'] ?? 'Técnico';
    }
    setState(() => _tecnicosMap = map);
  }
 
  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
  }
 
  Stream<QuerySnapshot> get _ticketsStream {
    Query query = _db.collection('tickets');
 
    if (_filtroEstado == 'Sin asignar') {
      query = query.where('agenteAsignado', isNull: true);
    } else if (_filtroEstado != 'Todos') {
      query = query.where('estado', isEqualTo: _filtroEstado);
    }
 
    if (_filtroTecnico != null) {
      query = query.where('agenteAsignado', isEqualTo: _filtroTecnico);
    }
 
    return query.snapshots();
  }
 
  void _mostrarAsignacion(String ticketId, String? tecnicoActual) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (modalContext) {
        return FutureBuilder<QuerySnapshot>(
          future: _db
              .collection('usuarios')
              .where('rol', isEqualTo: 'tecnico')
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator()));
            }
            final tecnicos = snapshot.data!.docs;
            if (tecnicos.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No hay técnicos disponibles.'),
              );
            }
 
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tecnicoActual == null
                        ? 'Asignar Técnico'
                        : 'Reasignar Técnico',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (tecnicoActual != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Técnico actual: ${_tecnicosMap[tecnicoActual] ?? tecnicoActual}',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ...tecnicos.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final esActual = doc.id == tecnicoActual;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            esActual ? Colors.black : Colors.grey.shade200,
                        child: Icon(Icons.person,
                            color: esActual ? Colors.white : Colors.black54),
                      ),
                      title: Text(data['nombre'] ?? 'Sin nombre'),
                      subtitle: Text(data['email'] ?? ''),
                      trailing: esActual
                          ? const Chip(
                              label: Text('Actual',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11)),
                              backgroundColor: Colors.black,
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(modalContext);
                        _db.collection('tickets').doc(ticketId).update({
                          'agenteAsignado': doc.id,
                          'estado': 'Asignado',
                        }).then((_) {
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Ticket ${tecnicoActual == null ? 'asignado' : 'reasignado'} a ${data['nombre']}'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Panel Administrador',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              child: const Text('Menú Admin',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_add_rounded),
              title: const Text('Registrar Usuario'),
              subtitle: const Text('Crear usuario/técnico/admin'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RegisterUserScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.category_rounded),
              title: const Text('Subcategorías'),
              subtitle: const Text('Agregar/eliminar problemas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const SubcategoryManagerScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_rounded),
              title: const Text('Reporte de Tickets'),
              subtitle: const Text('Tabla filtrable + exportar CSV'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TicketReportScreen()));
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Tarjetas de totales ──
          _TotalesRow(db: _db),
 
          // ── Filtros ──
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filtro por estado
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _estados.map((e) {
                      final sel = _filtroEstado == e;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(e),
                          selected: sel,
                          onSelected: (_) =>
                              setState(() => _filtroEstado = e),
                          selectedColor: Colors.black,
                          labelStyle: TextStyle(
                              color: sel ? Colors.white : Colors.black87,
                              fontWeight: sel
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Filtro por técnico
                if (_tecnicosMap.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _filtroTecnico,
                    decoration: InputDecoration(
                      hintText: 'Filtrar por técnico',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300)),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Todos los técnicos')),
                      ..._tecnicosMap.entries.map((e) => DropdownMenuItem(
                          value: e.key, child: Text(e.value))),
                    ],
                    onChanged: (v) => setState(() => _filtroTecnico = v),
                  ),
                ],
              ],
            ),
          ),
 
          // ── Lista de tickets ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _ticketsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No hay tickets con este filtro',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 15)),
                      ],
                    ),
                  );
                }
 
                final tickets = snapshot.data!.docs;
 
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final data =
                        tickets[index].data() as Map<String, dynamic>;
                    final ticketId = tickets[index].id;
                    final estado = data['estado'] ?? 'Nuevos';
                    final tecnicoId = data['agenteAsignado'];
                    final tecnicoNombre = tecnicoId != null
                        ? (_tecnicosMap[tecnicoId] ?? 'Técnico asignado')
                        : null;
 
                    // Calcular días abierto
                    int dias = 0;
                    if (data['fechaCreacion'] != null) {
                      final fecha =
                          (data['fechaCreacion'] as Timestamp).toDate();
                      dias = DateTime.now().difference(fecha).inDays;
                    }
 
                    Color estadoColor = Colors.grey;
                    if (estado == 'Asignado') estadoColor = Colors.blueAccent;
                    if (estado == 'Refacción') estadoColor = Colors.orange;
                    if (estado == 'Resuelto') estadoColor = Colors.green;
 
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                _Chip(
                                    label: data['categoria'] ?? 'General',
                                    color: Colors.orange),
                                _Chip(
                                    label: estado, color: estadoColor),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              data['descripcion'] ?? 'Sin descripción',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black87),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Info row
                            Row(
                              children: [
                                Icon(Icons.schedule_rounded,
                                    size: 14,
                                    color: dias > 3
                                        ? Colors.redAccent
                                        : Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  dias == 0
                                      ? 'Hoy'
                                      : '$dias día${dias == 1 ? '' : 's'} abierto',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: dias > 3
                                          ? Colors.redAccent
                                          : Colors.grey.shade600,
                                      fontWeight: dias > 3
                                          ? FontWeight.bold
                                          : FontWeight.normal),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.flag_rounded,
                                    size: 14,
                                    color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  data['prioridad'] ?? 'Media',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary),
                                ),
                                if (tecnicoNombre != null) ...[
                                  const SizedBox(width: 16),
                                  Icon(Icons.person_rounded,
                                      size: 14,
                                      color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      tecnicoNombre,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Botones
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TicketDetailScreen(
                                                ticketId: ticketId,
                                                data: data),
                                      ),
                                    ),
                                    icon: const Icon(Icons.comment_rounded,
                                        size: 16),
                                    label: const Text('Comentarios'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      side: const BorderSide(
                                          color: Colors.black),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _mostrarAsignacion(
                                        ticketId, tecnicoId),
                                    icon: Icon(
                                      tecnicoId == null
                                          ? Icons.person_add_rounded
                                          : Icons.swap_horiz_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      tecnicoId == null
                                          ? 'Asignar'
                                          : 'Reasignar',
                                      style: const TextStyle(
                                          color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
 
// ── Tarjetas de totales ──────────────────────────────────────────────────────
class _TotalesRow extends StatelessWidget {
  final FirebaseFirestore db;
  const _TotalesRow({required this.db});
 
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('tickets').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 80);
 
        final docs = snapshot.data!.docs;
        int total = docs.length;
        int sinAsignar = docs
            .where((d) => (d.data() as Map)['agenteAsignado'] == null)
            .length;
        int enProceso = docs
            .where((d) => (d.data() as Map)['estado'] == 'Asignado')
            .length;
        int resueltos = docs
            .where((d) => (d.data() as Map)['estado'] == 'Resuelto')
            .length;
 
        return Container(
          color: Colors.black,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _TotalChip(label: 'Total', valor: total, color: Colors.white),
              _TotalChip(
                  label: 'Sin asignar',
                  valor: sinAsignar,
                  color: Colors.orange),
              _TotalChip(
                  label: 'En proceso',
                  valor: enProceso,
                  color: Colors.blueAccent),
              _TotalChip(
                  label: 'Resueltos',
                  valor: resueltos,
                  color: Colors.greenAccent),
            ],
          ),
        );
      },
    );
  }
}
 
class _TotalChip extends StatelessWidget {
  final String label;
  final int valor;
  final Color color;
  const _TotalChip(
      {required this.label, required this.valor, required this.color});
 
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$valor',
            style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 10)),
        ],
      ),
    );
  }
}
 
class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12)),
    );
  }
}
 
// ── Detalle de ticket con comentarios ────────────────────────────────────────
class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  final Map<String, dynamic> data;
  const TicketDetailScreen(
      {super.key, required this.ticketId, required this.data});
 
  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}
 
class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _comentarioController = TextEditingController();
  final _db = FirebaseFirestore.instance;
  bool _enviando = false;
 
  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }
 
  Future<void> _enviarComentario() async {
    if (_comentarioController.text.trim().isEmpty) return;
    setState(() => _enviando = true);
 
    final user = FirebaseAuth.instance.currentUser;
    final userDoc =
        await _db.collection('usuarios').doc(user?.uid).get();
    final nombre = (userDoc.data() as Map?)?['nombre'] ?? 'Admin';
 
    await _db
        .collection('tickets')
        .doc(widget.ticketId)
        .collection('comentarios')
        .add({
      'texto': _comentarioController.text.trim(),
      'autorId': user?.uid,
      'autorNombre': nombre,
      'fecha': FieldValue.serverTimestamp(),
    });
 
    _comentarioController.clear();
    setState(() => _enviando = false);
  }
 
  @override
  Widget build(BuildContext context) {
    final estado = widget.data['estado'] ?? 'Nuevos';
 
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Detalle del Ticket',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Info del ticket
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.data['categoria'] ?? 'General',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(widget.data['descripcion'] ?? '',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 12),
                Row(children: [
                  _Chip(label: estado, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  _Chip(
                      label: widget.data['prioridad'] ?? 'Media',
                      color: Colors.orange),
                ]),
                if (widget.data['notaTecnica'] != null) ...[
                  const SizedBox(height: 12),
                  Text('Nota técnica:',
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  Text(widget.data['notaTecnica'],
                      style: const TextStyle(fontSize: 14)),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
 
          // Comentarios
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('tickets')
                  .doc(widget.ticketId)
                  .collection('comentarios')
                  .orderBy('fecha', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comentarios = snapshot.data!.docs;
                if (comentarios.isEmpty) {
                  return Center(
                    child: Text('Sin comentarios aún.',
                        style: TextStyle(color: Colors.grey.shade400)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comentarios.length,
                  itemBuilder: (context, index) {
                    final c = comentarios[index].data()
                        as Map<String, dynamic>;
                    DateTime? fecha;
                    if (c['fecha'] != null) {
                      fecha = (c['fecha'] as Timestamp).toDate();
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(c['autorNombre'] ?? 'Usuario',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              if (fecha != null)
                                Text(
                                  '${fecha.day}/${fecha.month} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(c['texto'] ?? '',
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
 
          // Input de comentario
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _comentarioController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un comentario...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _enviando ? null : _enviarComentario,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
 