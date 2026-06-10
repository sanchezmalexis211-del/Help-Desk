import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- Agregamos Auth
import '../models/ticket_model.dart';

class DBService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // <-- Instancia de Auth

  // Función para guardar un nuevo ticket en Firestore
  Future<void> crearTicket(TicketModel ticket) async {
    try {
      // 1. Obtenemos el UID del empleado que inició sesión
      final String? uid = _auth.currentUser?.uid;

      // 2. Convertimos el modelo a mapa
      Map<String, dynamic> ticketData = ticket.toMap();

      // 3. ¡INYECCIÓN CLAVE! Le pegamos los datos que faltan
      ticketData['usuarioId'] = uid; 
      ticketData['agenteAsignado'] = null; // Queda libre para que el Admin lo vea

      // 4. Guardamos en Firebase
      await _db.collection('tickets').add(ticketData);
      
    } catch (e) {
      print('Error al guardar el ticket: $e');
      rethrow;
    }
  }
}