import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../entorno.dart';
import 'servicio_auth.dart';

/// Implementación real contra Supabase Auth.
///
/// Las cuentas las crea el administrador desde el sitio web; la app solo
/// consume sesiones. Por eso acá no hay registro ni recuperación de clave.
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
  Future<void> ingresar({
    required String correo,
    required String clave,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: correo, password: clave);
    } on AuthException catch (e) {
      throw FallaAuth(_traducir(e));
    } on SocketException {
      throw const FallaAuth(
        'No pudimos conectar. Revisá tu conexión a internet.',
      );
    } on TimeoutException {
      throw const FallaAuth('El servidor tardó demasiado. Intentá de nuevo.');
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
            'Contactá a tu administrador.';
      case 'user_banned':
        return 'Tu cuenta está deshabilitada. Contactá a tu administrador.';
      case 'over_request_rate_limit':
        return 'Demasiados intentos. Esperá unos minutos e intentá de nuevo.';
    }

    if (e.statusCode == '429') {
      return 'Demasiados intentos. Esperá unos minutos e intentá de nuevo.';
    }
    return 'No pudimos iniciar sesión. Intentá de nuevo en unos minutos.';
  }
}
