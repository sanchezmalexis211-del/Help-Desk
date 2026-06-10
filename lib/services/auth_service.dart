import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<String?> iniciarSesion(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String> obtenerRolUsuario(String uid) async {
    try {
      final doc = await _db.collection('usuarios').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final rol = doc.get('rol');
        // Validamos que sea uno de los 3 roles conocidos
        if (rol == 'sysadmin' || rol == 'tecnico' || rol == 'usuario') {
          return rol;
        }
      }
      return 'usuario'; // ← CAMBIO: era 'empleado', no existe en tu Firestore
    } catch (e) {
      return 'usuario';
    }
  }

  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }
}