import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../entorno.dart';
import 'servicio_auth.dart';

/// Implementación real contra Supabase Auth.
///
/// El paciente puede crear su cuenta desde acá, pero crearla no lo vuelve
/// paciente de la clínica: eso lo decide el doctor aprobándola desde el sitio.
/// Quién está aprobado se consulta aparte, en `EstadoCuenta`.
class SupabaseAuth implements ServicioAuth {
  SupabaseAuth(this._client);

  /// Arranca Supabase. Llamar una sola vez antes de `runApp`.
  static Future<SupabaseAuth> inicializar() async {
    await Supabase.initialize(
      url: Entorno.supabaseUrl,
      publishableKey: Entorno.supabasePublishableKey,
    );
    return SupabaseAuth(Supabase.instance.client);
  }

  final SupabaseClient _client;

  @override
  Stream<bool> get cambiosDeSesion => _client.auth.onAuthStateChange
      .map((estado) => estado.session != null)
      .distinct();

  @override
  bool get autenticado => _client.auth.currentSession != null;

  @override
  String? get correoActual => _client.auth.currentUser?.email;

  @override
  Future<void> ingresar({required String correo, required String clave}) async {
    try {
      await _client.auth.signInWithPassword(email: correo, password: clave);
    } on AuthException catch (e) {
      throw FallaAuth(_traducir(e));
    } on SocketException {
      throw const FallaAuth(
        'No pudimos conectar. Revisa tu conexión a internet.',
      );
    } on TimeoutException {
      throw const FallaAuth('El servidor tardó demasiado. Intenta de nuevo.');
    }
  }

  @override
  Future<void> registrar({
    required String correo,
    required String clave,
    required String nombre,
    String? apellidos,
    String? cedula,
  }) async {
    try {
      // El disparador `al_crear_usuario` lee esto para armar la ficha que el
      // doctor va a ver en su bandeja. Lo que no se llenó no se manda, en vez
      // de mandar un null que el disparador tendría que limpiar del otro lado.
      final datos = <String, dynamic>{'nombre': nombre};
      if (apellidos != null) datos['apellidos'] = apellidos;
      if (cedula != null) datos['cedula'] = cedula;

      final res = await _client.auth.signUp(
        email: correo,
        password: clave,
        data: datos,
      );

      // Con la confirmación por correo activada en Supabase, `signUp` crea el
      // usuario pero NO abre sesión: queda esperando que hagan clic en un
      // correo. Sin esto, la app se quedaba muda —la cuenta creada y la
      // pantalla igual— y el paciente lo volvía a intentar hasta chocar con
      // el límite de envíos.
      //
      // En este proyecto la verificación es la aprobación del doctor, así que
      // la confirmación por correo debería estar apagada. Si alguien la
      // prende, al menos se entiende qué pasó.
      if (res.session == null) {
        throw const FallaAuth(
          'Tu cuenta se creó, pero falta confirmar el correo. Revisa tu '
          'bandeja de entrada, o consulta en recepción.',
        );
      }

      // Supabase deja la sesión abierta al registrar. Acá se cierra: la
      // solicitud queda enviada y la persona vuelve al login, que es lo que
      // corresponde a algo que todavía nadie aprobó.
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw FallaAuth(_traducirRegistro(e));
    } on SocketException {
      throw const FallaAuth(
        'No pudimos conectar. Revisa tu conexión a internet.',
      );
    } on TimeoutException {
      throw const FallaAuth('El servidor tardó demasiado. Intenta de nuevo.');
    }
  }

  @override
  Future<void> eliminarCuenta() async {
    try {
      // La función de la base borra `auth.uid()` y nada más; no recibe a quién
      // borrar, justamente para que no se le pueda pedir borrar a otro.
      await _client.rpc<void>('eliminar_mi_cuenta');
      await _client.auth.signOut();
    } on PostgrestException {
      throw const FallaAuth(
        'No pudimos eliminar la cuenta. Intenta de nuevo en unos minutos.',
      );
    } on SocketException {
      throw const FallaAuth(
        'No pudimos conectar. Revisa tu conexión a internet.',
      );
    } on TimeoutException {
      throw const FallaAuth('El servidor tardó demasiado. Intenta de nuevo.');
    }
  }

  @override
  Future<void> salir() => _client.auth.signOut();

  /// Traduce el error de Supabase a un mensaje accionable.
  ///
  /// Deliberadamente no distingue "usuario inexistente" de "clave incorrecta":
  /// hacerlo permitiría a un atacante enumerar qué correos tienen cuenta.
  String _traducir(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'Correo o contraseña incorrectos.';
      case 'email_not_confirmed':
        return 'Tu cuenta todavía no está confirmada. '
            'Contacta a tu administrador.';
      case 'user_banned':
        return 'Tu cuenta está deshabilitada. Contacta a tu administrador.';
      case 'over_request_rate_limit':
        return 'Demasiados intentos. Espera unos minutos e intenta de nuevo.';
    }

    if (e.statusCode == '429') {
      return 'Demasiados intentos. Espera unos minutos e intenta de nuevo.';
    }
    return 'No pudimos iniciar sesión. Intenta de nuevo en unos minutos.';
  }

  /// Traduce el error de registro.
  ///
  /// Acá sí se dice que el correo ya tiene cuenta, al revés que al ingresar:
  /// en un registro el mensaje es útil —le dice a la persona que entre en vez
  /// de registrarse— y no revela nada que no se pueda averiguar igual
  /// intentando registrarse con ese correo.
  String _traducirRegistro(AuthException e) {
    final mensaje = e.message.toLowerCase();

    if (e.code == 'user_already_exists' ||
        e.code == 'email_exists' ||
        mensaje.contains('already registered') ||
        mensaje.contains('already been registered')) {
      return 'Ese correo ya tiene una cuenta. Intenta entrar.';
    }
    // El disparador de la base corta el registro cuando la cédula ya existe.
    if (mensaje.contains('cédula') || mensaje.contains('cedula')) {
      return 'Esa cédula ya tiene una cuenta. Intenta entrar.';
    }
    if (e.code == 'weak_password' || mensaje.contains('password')) {
      return 'La contraseña es muy corta. Usa al menos 6 caracteres.';
    }
    // No es que la persona haya insistido: es el servidor de correo del
    // proyecto, que se quedó sin cuota porque la confirmación por correo está
    // encendida. Decirle "demasiados intentos" la manda a esperar por algo que
    // no depende de ella.
    if (e.code == 'over_email_send_rate_limit' ||
        mensaje.contains('email rate limit')) {
      return 'No pudimos crear la cuenta ahora mismo. Consulta en recepción '
          'y te la creamos nosotros.';
    }
    if (e.statusCode == '429') {
      return 'Demasiados intentos. Espera unos minutos e intenta de nuevo.';
    }
    return 'No pudimos crear la cuenta. Intenta de nuevo en unos minutos.';
  }
}
