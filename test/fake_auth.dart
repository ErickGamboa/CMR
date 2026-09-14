import 'dart:async';

import 'package:cmr_app/core/auth/servicio_auth.dart';

/// Doble de [ServicioAuth] para tests: sin red, con control sobre el resultado
/// y sobre cuándo se resuelve el ingreso.
class FakeAuth implements ServicioAuth {
  FakeAuth({this.falla});

  /// Si viene, [ingresar] lanza esta falla en vez de abrir sesión.
  final FallaAuth? falla;

  final _controlador = StreamController<bool>.broadcast();
  final List<({String correo, String clave})> llamadas = [];

  Completer<void>? _pendiente;
  bool _autenticado = false;

  /// Deja el próximo [ingresar] colgado hasta llamar a [resolver].
  void suspenderProximoIngreso() => _pendiente = Completer<void>();

  void resolver() => _pendiente?.complete();

  @override
  Stream<bool> get cambiosDeSesion => _controlador.stream;

  @override
  bool get autenticado => _autenticado;

  @override
  String? get correoActual => _autenticado ? llamadas.last.correo : null;

  @override
  Future<void> ingresar({required String correo, required String clave}) async {
    llamadas.add((correo: correo, clave: clave));

    if (_pendiente != null) {
      await _pendiente!.future;
      _pendiente = null;
    }

    if (falla != null) throw falla!;

    _autenticado = true;
    _controlador.add(true);
  }

  /// Lo que se registró, para que los tests lo comprueben.
  final List<({String correo, String nombre, String? cedula})> registros = [];

  /// Si se llamó a [eliminarCuenta].
  bool cuentaEliminada = false;

  @override
  Future<void> registrar({
    required String correo,
    required String clave,
    required String nombre,
    String? apellidos,
    String? cedula,
  }) async {
    if (falla != null) throw falla!;

    // Igual que el real: crear la cuenta NO deja sesión abierta. Registrarse
    // es mandar una solicitud, no entrar.
    registros.add((correo: correo, nombre: nombre, cedula: cedula));
  }

  @override
  Future<void> eliminarCuenta() async {
    if (falla != null) throw falla!;

    cuentaEliminada = true;
    _autenticado = false;
    _controlador.add(false);
  }

  @override
  Future<void> salir() async {
    _autenticado = false;
    _controlador.add(false);
  }

  void dispose() => _controlador.close();
}
