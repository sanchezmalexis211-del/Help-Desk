import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../services/db_service.dart';
import '../../models/ticket_model.dart';
import '../../services/gemini_service.dart';
import '../../services/push_notification_service.dart';

class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final DBService _dbService = DBService();
  final TextEditingController _detallesController = TextEditingController();
  final TextEditingController _otroController = TextEditingController();

  bool _isAnalyzing = false;
  bool _otroErrorVisible = false; // Muestra error si envía "Otro" vacío

  String? _equipoSeleccionado;
  String? _sintomaSeleccionado;

  static const String _opcionOtro = 'Otro / Describir manualmente';

 final List<Map<String, dynamic>> _equipos = [
  {'nombre': 'PC / Computadora', 'icono': Icons.computer_rounded},
  {'nombre': 'Caja / POS', 'icono': Icons.point_of_sale_rounded},
  {'nombre': 'Base de Datos', 'icono': Icons.dns_rounded},
  {'nombre': 'Red / Router', 'icono': Icons.router_rounded},
  {'nombre': 'CCTV / DVR', 'icono': Icons.videocam_rounded},
  {'nombre': 'Impresora', 'icono': Icons.print_rounded},

  // NUEVO
  {'nombre': 'Otros', 'icono': Icons.more_horiz_rounded},
];

final Map<String, List<String>> _sintomasPorEquipo = {
  'PC / Computadora': [
    'No enciende',
    'Muy lenta / Congelada',
    'Pantalla negra/azul',
    'No da video',
  ],

  'Caja / POS': [
    'No enciende',
    'Sistema congelado',
    'Pantalla azul',
    'Cajón trabado',
  ],

  'Base de Datos': [
    'No guarda reportes',
    'Error de sincronización',
    'Lento al cargar',
    'Error de acceso',
  ],

  'Red / Router': [
    'Sin internet',
    'Intermitente',
    'Switch apagado',
    'Cable roto',
  ],

  'CCTV / DVR': [
    'Cámara sin señal',
    'DVR pitando',
    'No graba',
    'Visión nocturna falla',
  ],

  'Impresora': [
    'Atasco de papel',
    'No imprime',
    'Falta tinta',
    'Error de red',
  ],

  // NUEVO
  'Otros': [
    _opcionOtro,
  ],
};
  bool get _esOtro => _sintomaSeleccionado == _opcionOtro;

  @override
  void dispose() {
    _detallesController.dispose();
    _otroController.dispose();
    super.dispose();
  }

  Future<void> _enviarReporte() async {
    // Validación: si eligió "Otro" y no escribió nada, bloqueamos y mostramos error
    if (_esOtro && _otroController.text.trim().isEmpty) {
      setState(() => _otroErrorVisible = true);
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _otroErrorVisible = false;
    });

    try {
      // Si es "Otro", usamos la descripción manual como síntoma real
      final String sintomaFinal = _esOtro
          ? _otroController.text.trim()
          : _sintomaSeleccionado!;

      // Contexto rico para Gemini
      String contextoParaGemini =
          'El equipo es un/a $_equipoSeleccionado. La falla reportada es: "$sintomaFinal".';

      if (_detallesController.text.trim().isNotEmpty) {
        contextoParaGemini +=
            ' Además, el usuario agrega estos detalles: "${_detallesController.text.trim()}".';
      }

      // Llamamos a Gemini
      final clasificacionIA = await GeminiService.clasificarTicket(contextoParaGemini);

      final nuevoTicket = TicketModel(
        descripcion: contextoParaGemini,
        categoria: _equipoSeleccionado!,
        prioridad: clasificacionIA['prioridad'] ?? 'Media',
        notaTecnica: clasificacionIA['resumen_tecnico'],
        estado: 'Nuevos',
        fechaCreacion: DateTime.now(),
      );

      await _dbService.crearTicket(nuevoTicket);

      // Notificación push al administrador
      String iconoAlerta = nuevoTicket.prioridad == 'Crítica'
          ? '🚨'
          : (nuevoTicket.prioridad == 'Alta' ? '⚠️' : '🔔');
      await PushNotificationService.enviarAlerta(
        titulo: '$iconoAlerta Falla ${nuevoTicket.prioridad}: ${nuevoTicket.categoria}',
        cuerpo: nuevoTicket.notaTecnica ?? nuevoTicket.descripcion,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Reporte enviado al equipo técnico',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Limpiamos el formulario
      setState(() {
        _equipoSeleccionado = null;
        _sintomaSeleccionado = null;
        _detallesController.clear();
        _otroController.clear();
        _isAnalyzing = false;
        _otroErrorVisible = false;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al procesar: $e'),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 700;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Nuevo Reporte',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Cerrar Sesión',
            onPressed: () async => await FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 10),
                  children: [
                    // ==========================================
                    // PASO 1: EQUIPO
                    // ==========================================
                    _buildHeaderPaso(1, '¿Qué equipo presenta fallas?',
                        isActive: true),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isDesktop ? 3 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isDesktop ? 1.5 : 1.3,
                      ),
                      itemCount: _equipos.length,
                      itemBuilder: (context, index) {
                        final equipo = _equipos[index];
                        final isSelected =
                            _equipoSeleccionado == equipo['nombre'];

                        return GestureDetector(
                          onTap: () => setState(() {
                            _equipoSeleccionado = equipo['nombre'];
                            _sintomaSeleccionado = null;
                            _otroController.clear();
                            _otroErrorVisible = false;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                if (!isSelected)
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4))
                              ],
                              border: Border.all(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 2),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(equipo['icono'],
                                    size: 36,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87),
                                const SizedBox(height: 12),
                                Text(
                                  equipo['nombre'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // ==========================================
                    // PASO 2: PROBLEMA EXACTO
                    // ==========================================
                    AnimatedSize(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      child: _equipoSeleccionado == null
                          ? const SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeaderPaso(
                                    2, 'Selecciona el problema exacto',
                                    isActive: true),
                                const SizedBox(height: 16),
                                ..._sintomasPorEquipo[_equipoSeleccionado]!
                                    .map((sintoma) {
                                  final isSelected =
                                      _sintomaSeleccionado == sintoma;
                                  final esOpcionOtro =
                                      sintoma == _opcionOtro;

                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        InkWell(
                                          onTap: () => setState(() {
                                            _sintomaSeleccionado = sintoma;
                                            _otroController.clear();
                                            _otroErrorVisible = false;
                                          }),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 18),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.grey.shade900
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: esOpcionOtro && !isSelected
                                                    ? Colors.grey.shade400
                                                    : isSelected
                                                        ? Colors.grey.shade900
                                                        : Colors.grey.shade200,
                                                // Borde punteado visual para "Otro"
                                                width: esOpcionOtro ? 1.5 : 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  esOpcionOtro
                                                      ? (isSelected
                                                          ? Icons.edit_rounded
                                                          : Icons
                                                              .edit_outlined)
                                                      : (isSelected
                                                          ? Icons
                                                              .radio_button_checked
                                                          : Icons
                                                              .radio_button_unchecked),
                                                  color: isSelected
                                                      ? Colors.white
                                                      : esOpcionOtro
                                                          ? Colors.grey.shade600
                                                          : Colors.grey.shade400,
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Text(
                                                    sintoma,
                                                    style: TextStyle(
                                                      color: isSelected
                                                          ? Colors.white
                                                          : Colors.black87,
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      fontSize: 16,
                                                      fontStyle: esOpcionOtro
                                                          ? FontStyle.italic
                                                          : FontStyle.normal,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Campo de texto que aparece SOLO si eligió "Otro"
                                        AnimatedSize(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                          child: (esOpcionOtro && isSelected)
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 10),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      TextField(
                                                        controller:
                                                            _otroController,
                                                        maxLength: 120,
                                                        autofocus: true,
                                                        onChanged: (_) {
                                                          if (_otroErrorVisible) {
                                                            setState(() =>
                                                                _otroErrorVisible =
                                                                    false);
                                                          }
                                                        },
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.black87),
                                                        decoration:
                                                            InputDecoration(
                                                          hintText:
                                                              'Describe la falla con tus palabras...',
                                                          hintStyle: TextStyle(
                                                              color: Colors.grey
                                                                  .shade400),
                                                          filled: true,
                                                          fillColor:
                                                              Colors.white,
                                                          counterStyle:
                                                              TextStyle(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade500),
                                                          // Borde rojo si hay error de validación
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            borderSide:
                                                                BorderSide(
                                                              color: _otroErrorVisible
                                                                  ? Colors.red
                                                                  : Colors.grey
                                                                      .shade300,
                                                              width:
                                                                  _otroErrorVisible
                                                                      ? 2
                                                                      : 1,
                                                            ),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            borderSide:
                                                                const BorderSide(
                                                                    color: Colors
                                                                        .black,
                                                                    width: 2),
                                                          ),
                                                        ),
                                                      ),
                                                      // Mensaje de error inline
                                                      if (_otroErrorVisible)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 4,
                                                                  left: 4),
                                                          child: Row(
                                                            children: [
                                                              const Icon(
                                                                  Icons
                                                                      .error_outline,
                                                                  color: Colors
                                                                      .red,
                                                                  size: 14),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Text(
                                                                'Por favor describe el problema antes de enviar',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .red
                                                                        .shade700,
                                                                    fontSize:
                                                                        12),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                    ),

                    const SizedBox(height: 20),

                    // ==========================================
                    // PASO 3: DETALLES ADICIONALES
                    // ==========================================
                    AnimatedSize(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      child: _sintomaSeleccionado == null
                          ? const SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                _buildHeaderPaso(
                                  3,
                                  _esOtro
                                      ? 'Contexto adicional (Opcional)'
                                      : 'Detalles adicionales (Opcional)',
                                  isActive: true,
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _detallesController,
                                  maxLines: 3,
                                  style:
                                      const TextStyle(color: Colors.black87),
                                  decoration: InputDecoration(
                                    hintText: _esOtro
                                        ? 'Ej. Cuándo empezó, si hubo algún evento previo...'
                                        : 'Ej. Empezó a fallar después de un apagón...',
                                    hintStyle: TextStyle(
                                        color: Colors.grey.shade400),
                                    filled: true,
                                    fillColor: Colors.white,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade200),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                          color: Colors.black, width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 100),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AnimatedOpacity(
        opacity: (_equipoSeleccionado != null && _sintomaSeleccionado != null)
            ? 1.0
            : 0.0,
        duration: const Duration(milliseconds: 300),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FloatingActionButton.extended(
              onPressed: (_equipoSeleccionado != null &&
                      _sintomaSeleccionado != null &&
                      !_isAnalyzing)
                  ? _enviarReporte
                  : null,
              backgroundColor: Colors.black,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              label: _isAnalyzing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('ENVIAR REPORTE',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
              icon: _isAnalyzing
                  ? null
                  : const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderPaso(int numero, String texto, {required bool isActive}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Text(
            numero.toString(),
            style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.black87 : Colors.grey.shade400,
            ),
          ),
        ),
      ],
    );
  }
}