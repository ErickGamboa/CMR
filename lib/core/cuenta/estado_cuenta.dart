import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/sincronizador.dart';

/// En qué situación está la cuenta de quien tiene la sesión abierta.
///
/// Tener sesión y ser paciente de la clínica dejaron de ser lo mismo cuando la
/// app permitió registrarse: entre las dos cosas está la aprobación del
/// doctor. Esto es lo que las separa.
enum EstadoCuenta {
  /// Se registró y el doctor todavía no la aprueba. No ve nada de la app.
  pendiente,

  /// Aprobada por el doctor. Es la única que ve la app completa.
  activa,

  /// El doctor la dio de baja.
  inactiva;

  static EstadoCuenta porValor(String? valor) => switch (valor) {
    'activo' => activa,
    'inactivo' => inactiva,
    _ => pendiente,
  };
}

/// De dónde se sabe en qué situación está la cuenta.
abstract interface class FuenteCuenta {
  /// Lo que dice el servidor ahora. Necesita internet.
  Future<EstadoCuenta> estado();

  /// Lo que dijo el servidor la última vez, sin preguntarle: lo que deja
  /// entrar sin conexión. `null` si nunca se supo.
  Future<EstadoCuenta?> recordado();
}

/// Lee el estado de la ficha del paciente en Supabase, y recuerda el último
/// en el teléfono.
class RepositorioCuenta implements FuenteCuenta {
  RepositorioCuenta([SupabaseClient? client]) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _db => _client ?? Supabase.instance.client;

  @override
  Future<EstadoCuenta?> recordado() async {
    try {
      final datos = Sincronizador.actual;
      if (datos == null) return null;

      final foto = await datos.almacen.leer(datos.llaveDelPaciente('cuenta'));
      return switch (foto?.datos) {
        final String valor => EstadoCuenta.values.asNameMap()[valor],
        _ => null,
      };
    } on Object {
      return null;
    }
  }

  Future<void> _recordar(EstadoCuenta estado) async {
    final datos = Sincronizador.actual;
    if (datos == null) return;

    try {
      // Una cuenta que ya no está activa no se queda con nada guardado: si el
      // doctor la dio de baja, sus datos tampoco se ven sin conexión.
      if (estado != EstadoCuenta.activa) await datos.vaciar();
      await datos.almacen.guardar(
        datos.llaveDelPaciente('cuenta'),
        estado.name,
      );
    } on Object {
      // Recordarlo es un extra: si falla, la próxima vez se pregunta de nuevo.
    }
  }

  @override
  Future<EstadoCuenta> estado() async {
    try {
      // RLS solo deja ver la fila propia, así que no hace falta filtrar por
      // usuario: si viene algo, es de quien pregunta.
      final fila = await _db
          .from('pacientes')
          .select('estado')
          .maybeSingle()
          .timeout(Sincronizador.espera);

      // Sin ficha, se trata como pendiente. Pasa con las cuentas viejas y con
      // la del doctor si entra a la app: ninguna de las dos es un paciente
      // aprobado, y ante la duda la app no muestra nada.
      final estado = EstadoCuenta.porValor(fila?['estado'] as String?);
      await _recordar(estado);
      return estado;
    } on PostgrestException {
      throw const FallaCuenta(
        'No pudimos verificar tu cuenta. Intenta de nuevo en unos minutos.',
      );
    } on SocketException {
      throw const FallaCuenta(
        'No pudimos conectar. Revisa tu conexión a internet.',
      );
    } on TimeoutException {
      throw const FallaCuenta('El servidor tardó demasiado. Intenta de nuevo.');
    }
  }
}

class FallaCuenta implements Exception {
  const FallaCuenta(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
