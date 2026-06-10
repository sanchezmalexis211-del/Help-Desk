class AIService {
  Future<Map<String, String>> clasificarTicket(String descripcion) async {
    // Simulación de latencia del modelo
    await Future.delayed(const Duration(seconds: 2));

    String categoria = 'Hardware / Computadora';
    String prioridad = 'Media';
    String descLower = descripcion.toLowerCase();

    if (descLower.contains('internet') || descLower.contains('red')) {
      categoria = 'Red e Internet';
      prioridad = 'Alta';
    } else if (descLower.contains('pos') || descLower.contains('caja')) {
      categoria = 'Sistema POS / Caja';
      prioridad = 'Crítica';
    }

    return {
      'categoria': categoria,
      'prioridad': prioridad,
    };
  }
}