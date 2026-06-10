import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  String? id;
  String descripcion;
  String categoria;
  String prioridad;
  String estado;          // Usaremos los estados requeridos: 'Abierto', 'En proceso', 'Cerrado'
  DateTime fechaCreacion;
  String? notaTecnica;    
  String? tiempoEstimado; 
  String? agenteAsignado; // <-- NUEVO: Guarda el ID, nombre o correo del agente asignado

  TicketModel({
    this.id,
    required this.descripcion,
    required this.categoria,
    required this.prioridad,
    required this.estado,
    required this.fechaCreacion,
    this.notaTecnica,
    this.tiempoEstimado,
    this.agenteAsignado, // <-- NUEVO
  });

  // =========================================================
  // REQUERIMIENTO LISTO: Ver cuántos días lleva abierto el ticket
  // =========================================================
  int get diasAbierto {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fechaCreacion);
    return diferencia.inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'descripcion': descripcion,
      'categoria': categoria,
      'prioridad': prioridad,
      'estado': estado,
      'fechaCreacion': FieldValue.serverTimestamp(), 
      'notaTecnica': notaTecnica,
      'tiempoEstimado': tiempoEstimado,
      'agenteAsignado': agenteAsignado, // <-- NUEVO: Guarda la asignación en Firestore
    };
  }

  factory TicketModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime fechaParsed = DateTime.now();
    if (map['fechaCreacion'] != null) {
      fechaParsed = (map['fechaCreacion'] as Timestamp).toDate();
    }

    return TicketModel(
      id: documentId,
      descripcion: map['descripcion'] ?? '',
      categoria: map['categoria'] ?? 'General',
      prioridad: map['prioridad'] ?? 'Media',
      estado: map['estado'] ?? 'Abierto', // Si no tiene estado, por defecto inicia 'Abierto'
      fechaCreacion: fechaParsed,
      notaTecnica: map['notaTecnica'],       
      tiempoEstimado: map['tiempoEstimado'], 
      agenteAsignado: map['agenteAsignado'], // <-- NUEVO: Recupera la asignación de Firestore
    );
  }
}