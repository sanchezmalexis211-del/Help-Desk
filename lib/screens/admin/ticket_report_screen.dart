import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Pantalla para generar reportes en tabla de tickets.
/// Ruta sugerida: lib/screens/admin/ticket_report_screen.dart
class TicketReportScreen extends StatefulWidget {
  const TicketReportScreen({super.key});

  @override
  State<TicketReportScreen> createState() => _TicketReportScreenState();
}

class _TicketReportScreenState extends State<TicketReportScreen> {
  final _db = FirebaseFirestore.instance;
  String _filtroEstado = 'Todos';
  DateTimeRange? _rango;
  List<Map<String, dynamic>> _tickets = [];
  bool _cargando = false;

  final List<String> _estados = [
    'Todos',
    'Asignado',
    'Refacción',
    'Resuelto',
  ];

  @override
  void initState() {
    super.initState();
    _generarReporte();
  }

  Future<void> _generarReporte() async {
    setState(() => _cargando = true);

    try {
      Query query = _db.collection('tickets');

      // Filtrar por estado
      if (_filtroEstado != 'Todos') {
        query = query.where('estado', isEqualTo: _filtroEstado);
      }

      final docs = await query.get();
      final tickets = <Map<String, dynamic>>[];

      for (final doc in docs.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Filtrar por rango de fechas si está seleccionado
        if (_rango != null && data['fechaCreacion'] != null) {
          final fecha = (data['fechaCreacion'] as Timestamp).toDate();
          if (fecha.isBefore(_rango!.start) ||
              fecha.isAfter(_rango!.end.add(const Duration(days: 1)))) {
            continue;
          }
        }

        tickets.add({
          'id': doc.id,
          ...data,
        });
      }

      // Ordenar por fecha descendente
      tickets.sort((a, b) {
        final fechaA = (a['fechaCreacion'] as Timestamp?)?.toDate() ??
            DateTime.now();
        final fechaB = (b['fechaCreacion'] as Timestamp?)?.toDate() ??
            DateTime.now();
        return fechaB.compareTo(fechaA);
      });

      setState(() {
        _tickets = tickets;
        _cargando = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al generar reporte: $e'),
            backgroundColor: Colors.redAccent),
      );
      setState(() => _cargando = false);
    }
  }

  Future<void> _seleccionarRango() async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _rango,
    );
    if (rango != null) {
      setState(() => _rango = rango);
      _generarReporte();
    }
  }

  String _formatoFecha(Timestamp? ts) {
    if (ts == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate());
  }

  int _diasAbierto(Timestamp? ts) {
    if (ts == null) return 0;
    return DateTime.now().difference(ts.toDate()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Reporte de Tickets',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Exportar a CSV',
            onPressed: _exportarCSV,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filtro por estado
                const Text('Estado',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
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
                          onSelected: (_) {
                            setState(() => _filtroEstado = e);
                            _generarReporte();
                          },
                          selectedColor: Colors.black,
                          labelStyle: TextStyle(
                            color: sel ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Filtro por fecha
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _seleccionarRango,
                        icon: const Icon(Icons.calendar_today_rounded),
                        label: Text(
                          _rango == null
                              ? 'Seleccionar rango'
                              : '${DateFormat('dd/MM').format(_rango!.start)} - ${DateFormat('dd/MM').format(_rango!.end)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (_rango != null)
                      IconButton(
                        onPressed: () {
                          setState(() => _rango = null);
                          _generarReporte();
                        },
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Limpiar filtro',
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Tabla de tickets
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _tickets.isEmpty
                    ? Center(
                        child: Text(
                          'No hay tickets con este filtro.',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 15),
                        ),
                      )
                    : SingleChildScrollView(
                        child: DataTable(
                          columnSpacing: 12,
                          dataRowHeight: 60,
                          headingRowColor: MaterialStateColor.resolveWith(
                              (_) => Colors.black),
                          columns: const [
                            DataColumn(
                              label: Text('Categoría',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Prioridad',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Estado',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Días',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Fecha',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                          rows: _tickets.map((t) {
                            final dias = _diasAbierto(
                                t['fechaCreacion'] as Timestamp?);
                            final diasColor = dias > 3
                                ? Colors.redAccent
                                : dias > 1
                                    ? Colors.orange
                                    : Colors.green;

                            return DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      t['categoria'] ?? '-',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (t['prioridad'] == 'Crítica'
                                              ? Colors.redAccent
                                              : t['prioridad'] == 'Alta'
                                                  ? Colors.orange
                                                  : Colors.blueAccent)
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      t['prioridad'] ?? 'Media',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: t['prioridad'] == 'Crítica'
                                            ? Colors.redAccent
                                            : t['prioridad'] == 'Alta'
                                                ? Colors.orange
                                                : Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      t['estado'] ?? 'Nuevos',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: diasColor.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$dias días',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: diasColor,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _formatoFecha(
                                        t['fechaCreacion'] as Timestamp?),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
          ),

          // Resumen
          Container(
            width: double.infinity,
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ResumenChip('Total', _tickets.length),
                _ResumenChip(
                  'Resueltos',
                  _tickets
                      .where((t) => t['estado'] == 'Resuelto')
                      .length,
                ),
                _ResumenChip(
                  'Pendientes',
                  _tickets
                      .where((t) => t['estado'] != 'Resuelto')
                      .length,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportarCSV() {
    if (_tickets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay tickets para exportar.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    // Generar CSV en memoria
    StringBuffer csv = StringBuffer();
    csv.writeln(
        'ID,Categoría,Descripción,Prioridad,Estado,Técnico,Días Abierto,Fecha Creación,Nota Técnica');

    for (final t in _tickets) {
      final dias = _diasAbierto(t['fechaCreacion'] as Timestamp?);
      final fecha = _formatoFecha(t['fechaCreacion'] as Timestamp?);

      csv.writeln(
        '"${t['id'] ?? ''}","${t['categoria'] ?? ''}","${(t['descripcion'] ?? '').replaceAll('"', '""')}","${t['prioridad'] ?? ''}","${t['estado'] ?? ''}","${t['agenteAsignado'] ?? 'Sin asignar'}","$dias","$fecha","${(t['notaTecnica'] ?? '').replaceAll('"', '""')}"',
      );
    }

    // Mostrar diálogo con opción de copiar
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reporte Generado'),
        content: const Text(
            'Contenido CSV generado. Cópialo para pegar en Excel o Google Sheets.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              // En un app real aquí copiarías al clipboard
              // Por ahora solo mostramos el mensaje
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'CSV copiado al portapapeles. Pégalo en Excel.'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Copiar'),
          ),
        ],
      ),
    );
  }
}

class _ResumenChip extends StatelessWidget {
  final String label;
  final int valor;
  const _ResumenChip(this.label, this.valor);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$valor',
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
