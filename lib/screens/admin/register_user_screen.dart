import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
 
/// Pantalla para que el sysadmin registre nuevos usuarios, agentes o admins.
/// Ruta: lib/screens/admin/register_user_screen.dart
class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});
 
  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}
 
class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _rolSeleccionado = 'usuario';
  bool _isLoading = false;
 
  final List<Map<String, dynamic>> _roles = [
    {'valor': 'usuario', 'label': 'Usuario', 'icono': Icons.person_rounded},
    {
      'valor': 'tecnico',
      'label': 'Técnico / Agente',
      'icono': Icons.build_rounded
    },
    {
      'valor': 'sysadmin',
      'label': 'Administrador',
      'icono': Icons.admin_panel_settings_rounded
    },
  ];
 
  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
 
  Future<void> _registrar() async {
    if (_nombreController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _mostrarError('Por favor llena todos los campos');
      return;
    }
    if (_passwordController.text.trim().length < 6) {
      _mostrarError('La contraseña debe tener al menos 6 caracteres');
      return;
    }
 
    setState(() => _isLoading = true);
 
    try {
      // Crear usuario en Firebase Auth
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
 
      // Guardar datos en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(credential.user!.uid)
          .set({
        'nombre': _nombreController.text.trim(),
        'email': _emailController.text.trim(),
        'rol': _rolSeleccionado,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'activo': true,
      });
 
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text('Usuario "${_nombreController.text.trim()}" creado exitosamente'),
          ]),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
 
      // Limpiamos el formulario
      _nombreController.clear();
      _emailController.clear();
      _passwordController.clear();
      setState(() {
        _rolSeleccionado = 'usuario';
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String msg = 'Error al crear usuario';
      if (e.code == 'email-already-in-use') {
        msg = 'Este correo ya está registrado';
      } else if (e.code == 'invalid-email') {
        msg = 'Correo inválido';
      } else if (e.code == 'weak-password') {
        msg = 'Contraseña muy débil';
      }
      _mostrarError(msg);
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error: $e');
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Registrar Usuario',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 8),
              const Text('Tipo de cuenta',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
 
              // Selector de rol
              Row(
                children: _roles.map((rol) {
                  final isSelected = _rolSeleccionado == rol['valor'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _rolSeleccionado = rol['valor']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.black
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(rol['icono'],
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                size: 24),
                            const SizedBox(height: 6),
                            Text(
                              rol['label'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
 
              const SizedBox(height: 28),
              _buildField('Nombre completo', _nombreController,
                  Icons.badge_rounded),
              const SizedBox(height: 16),
              _buildField('Correo electrónico', _emailController,
                  Icons.email_outlined,
                  tipo: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildField('Contraseña', _passwordController,
                  Icons.lock_outline,
                  obscure: true),
              const SizedBox(height: 32),
 
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _registrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.person_add_rounded,
                          color: Colors.white),
                  label: Text(
                    _isLoading ? 'Creando...' : 'Crear Cuenta',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ),
 
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
 
              // Lista de usuarios existentes
              const Text('Usuarios registrados',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .orderBy('fechaCreacion', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Text('No hay usuarios registrados.');
                  }
                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final rol = data['rol'] ?? 'usuario';
                      Color chipColor = Colors.grey;
                      if (rol == 'sysadmin') chipColor = Colors.black;
                      if (rol == 'tecnico') chipColor = Colors.blueAccent;
 
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: chipColor.withOpacity(0.1),
                          child: Icon(Icons.person_rounded,
                              color: chipColor, size: 20),
                        ),
                        title: Text(data['nombre'] ?? 'Sin nombre',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(data['email'] ?? ''),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: chipColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(rol,
                              style: TextStyle(
                                  color: chipColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _buildField(
    String hint,
    TextEditingController controller,
    IconData icono, {
    bool obscure = false,
    TextInputType tipo = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: tipo,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icono, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
    );
  }
}