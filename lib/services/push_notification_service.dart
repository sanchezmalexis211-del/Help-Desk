import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> _backgroundHandler(RemoteMessage message) async {
    print('🚨 Notificación en segundo plano: ${message.notification?.title}');
  }

  static Future<void> initializeApp() async {
    if (kIsWeb) {
      print('🌐 Ejecutando en Web: Se omiten las Notificaciones Push por ahora.');
      return;
    }

    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true, badge: true, sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permisos de notificación concedidos');
      }

      String? token = await _firebaseMessaging.getToken();
      await _firebaseMessaging.subscribeToTopic('alertas_admin');
      print('📡 Dispositivo suscrito al canal alertas_admin. Token: $token');

      FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          print('📩 Título: \${message.notification!.title}');
        }
      });
    } catch (e) {
      print('⚠️ Error al inicializar PushNotifications (se omite para no bloquear la app): \$e');
    }
  }

  // =========================================================================
  // LA "BOCA": Función para disparar la notificación a todos los técnicos
  // =========================================================================
  static Future<void> enviarAlerta({required String titulo, required String cuerpo}) async {
    try {
      // 1. Pega aquí EXACTAMENTE todo el contenido de tu archivo .json descargado de Firebase
      // (No borres las comillas triples ''' ''')
      final String jsonCredentials = '''
      {
        "type": "service_account",
        "project_id": "TU_PROJECT_ID_AQUI",
        "private_key_id": "...",
        "private_key": "...",
        "client_email": "...",
        "client_id": "...",
        "auth_uri": "...",
        "token_uri": "...",
        "auth_provider_x509_cert_url": "...",
        "client_x509_cert_url": "...",
        "universe_domain": "googleapis.com"
      }
      ''';

      // 2. Autenticamos nuestra app con los servidores de Google
      final credentials = auth.ServiceAccountCredentials.fromJson(jsonCredentials);
      final client = await auth.clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/firebase.messaging'],
      );

      // Extraemos automáticamente el ID de tu proyecto desde el JSON
      final mapData = json.decode(jsonCredentials);
      final projectId = mapData['project_id'];

      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

      // 3. Armamos el paquete (Payload) que viajará por la red
      final payload = {
        'message': {
          'topic': 'alertas_admin', // Se envía a todos los que sintonizan este canal
          'notification': {
            'title': titulo,
            'body': cuerpo,
          },
          'android': {
            'priority': 'high', // Fuerza a que el celular suene rápido
          }
        },
      };

      // 4. Hacemos el POST (Disparamos la notificación)
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('✅ Alerta Push enviada con éxito');
      } else {
        print('❌ Error al enviar alerta: ${response.body}');
      }

      client.close();
    } catch (e) {
      print('❌ Fallo crítico en el servicio de alertas: $e');
    }
  }
}