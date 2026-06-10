import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';

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
                if ((widget.data['subcategoria'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(widget.data['subcategoria'],
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
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
