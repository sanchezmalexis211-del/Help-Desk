
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // TODO: ¡MUY IMPORTANTE! Pega aquí tu API Key de Google AI Studio
  static const String _apiKey = 'AIzaSyCwpBLHQQb-7cOJCIjxugXlV3EJ9PjuoY8';

  static Future<Map<String, String>> clasificarTicket(String descripcionFalla) async {
   final model = GenerativeModel(
      // ¡Aquí ponemos el modelo correcto que te dio la terminal!
      model: 'gemini-2.5-flash', 
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
    // =========================================================================
    // NUEVO PROMPT ANALÍTICO: Obliga a la IA a "pensar" y evaluar el impacto real
    // =========================================================================
   final prompt = '''
    Eres un Jefe de Soporte Técnico experto. Tu trabajo es analizar reportes de fallas y asignar la prioridad correcta.

    REGLAS ESTRICTAS DE NEGOCIO:
    - Baja: Dudas, petición de nuevo software, problemas estéticos o mantenimiento preventivo. El usuario no tiene urgencia real.
    - Media: Falla de hardware/software que afecta a 1 solo usuario, pero puede seguir trabajando (lentitud, equipo secundario falla).
    - Alta: Bloqueo total para 1 usuario clave, o falla que afecta a varios pero NO detiene las ventas ni la operación principal.
    - Crítica: IMPACTO FINANCIERO O DE SEGURIDAD. Negocio detenido. Servidores caídos, Puntos de Venta (POS) fallando, Base de Datos muerta, Red general caída, o CCTV apagado.

    EJEMPLOS DE ENTRENAMIENTO (Usa esta misma lógica):
    Reporte: "Mi teclado se traba a veces" -> {"prioridad": "Baja", "categoria": "Hardware", "resumen_tecnico": "Revisión física de teclado"}
    Reporte: "No puedo imprimir mi reporte mensual" -> {"prioridad": "Media", "categoria": "Hardware", "resumen_tecnico": "Falla en impresora local"}
    Reporte: "La caja 2 no lee las tarjetas de crédito y hay fila" -> {"prioridad": "Crítica", "categoria": "POS", "resumen_tecnico": "Terminal de cobro rechaza tarjetas"}
    Reporte: "Las cámaras de la entrada principal se apagaron" -> {"prioridad": "Crítica", "categoria": "CCTV", "resumen_tecnico": "Pérdida de video en acceso principal"}
    Reporte: "No hay internet en toda la sucursal" -> {"prioridad": "Crítica", "categoria": "Red", "resumen_tecnico": "Caída general de enlace a internet"}

    Reporte real a analizar: "$descripcionFalla"

    Devuelve SOLO un objeto JSON puro, sin texto extra ni formato markdown, usando esta estructura exacta:
    {
      "prioridad": "Media",
      "categoria": "Hardware",
      "resumen_tecnico": "Resumen técnico de 5 a 8 palabras"
    }
    ''';
    
    try {
      print('--- GEMINI ANALIZANDO EL IMPACTO ---'); 
      
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      if (response.text != null) {
        String rawText = response.text!.trim();
        if (rawText.startsWith('```json')) {
          rawText = rawText.replaceAll('```json', '');
          rawText = rawText.replaceAll('```', '');
        }
        rawText = rawText.trim();
        
        print('ANÁLISIS COMPLETADO: $rawText'); 

        final Map<String, dynamic> jsonMap = jsonDecode(rawText);
        
        return {
          "prioridad": jsonMap["prioridad"]?.toString() ?? "Media",
          "categoria": jsonMap["categoria"]?.toString() ?? "Otro",
          "resumen_tecnico": jsonMap["resumen_tecnico"]?.toString() ?? "Revisión técnica requerida",
        };
      }
    } catch (e) {
      print('=== 🚨 ERROR AL ANALIZAR EN GEMINI 🚨 ===');
      print(e.toString());
    }
    
    return {
      "prioridad": "Media",
      "categoria": "Otro",
      "resumen_tecnico": "" 
    };
  }
}