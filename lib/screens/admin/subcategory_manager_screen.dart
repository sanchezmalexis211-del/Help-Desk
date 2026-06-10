import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubcategoryManagerScreen extends StatefulWidget {
  const SubcategoryManagerScreen({super.key});

  @override
  State<SubcategoryManagerScreen> createState() => _SubcategoryManagerScreenState();
}

class _SubcategoryManagerScreenState extends State<SubcategoryManagerScreen> {
  final _db = FirebaseFirestore.instance;
  final _nombreController = TextEditingController();
  final _detalleController = TextEditingController();
  String _categoriaSeleccionada = 'PC / Computadora';

  final List<String> _categoriasBase = [
    'PC / Computadora',
    'Caja / POS',
    'Base de Datos',
    'Red / Router',
    'CCTV / DVR',
    'Impresora',
  ];

  // ==========================================
  // LA MAGIA AQUÍ: Limpiamos la diagonal
  // ==========================================
  String get _categoriaLimpia => _categoriaSeleccionada.replaceAll('/', '-');

  @override
  void dispose() {
    _nombreController.dispose();
    _detalleController.dispose();
    super.dispose();
  }

  Future<void> _agregarSubcategoria() async {
    if (_nombreController.text.trim().isEmpty) {
      _mostrarError('Ingresa el nombre del problema');
      return;
    }

    final docId = '${_categoriaLimpia}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      await _db
          .collection('subcategorias')
          .doc(_categoriaLimpia) // Usamos la versión sin diagonal
          .collection('items')
          .doc(docId)
          .set({
        'nombre': _nombreController.text.trim(),
        'detalle': _detalleController.text.trim(),
        'fechaCreacion': FieldValue.serverTimestamp(),
        'activo': true,
      });

      _nombreController.clear();
      _detalleController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Subcategoría agregada'),
            ]),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _mostrarError('Error al agregar: $e');
    }
  }

  Future<void> _eliminarSubcategoria(String nombre) async {
    try {
      final query = await _db
          .collection('subcategorias')
          .doc(_categoriaLimpia) // Usamos la versión sin diagonal
          .collection('items')
          .where('nombre', isEqualTo: nombre)
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subcategoría eliminada'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _mostrarError('Error al eliminar: $e');
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Gestionar Subcategorías',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Selector de categoría
          Text('Categoría',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _categoriaSeleccionada,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
            items: _categoriasBase
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _categoriaSeleccionada = v);
            },
          ),
          const SizedBox(height: 24),

          // Formulario para agregar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Agregar nuevo problema',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blueAccent)),
                const SizedBox(height: 12),
                TextField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    hintText: 'Ej: No enciende, Pantalla azul, etc.',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _detalleController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Detalle o descripción adicional (opcional)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _agregarSubcategoria,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text('Agregar',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Lista de subcategorías existentes
          Text('Problemas en $_categoriaSeleccionada',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('subcategorias')
                .doc(_categoriaLimpia) // Usamos la versión sin diagonal
                .collection('items')
                .where('activo', isEqualTo: true)
                .orderBy('fechaCreacion', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = snapshot.data!.docs;
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No hay problemas agregados en esta categoría.',
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                );
              }

              return Column(
                children: items.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200, width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['nombre'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                if ((data['detalle'] ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    data['detalle'],
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Eliminar'),
                                  content: Text('¿Eliminar "${data['nombre']}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _eliminarSubcategoria(data['nombre']);
                                      },
                                      child: const Text('Eliminar',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_rounded,
                                color: Colors.redAccent, size: 20),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}