/// Falla de autenticación ya traducida a algo que se le puede mostrar
/// al usuario. Nunca contiene detalles técnicos ni datos del servidor.
class FallaAuth implements Exception {
  const FallaAuth(this.mensaje);

  final String mensaje;

  @override
  String toString() => 'FallaAuth: $mensaje';
}

/// Contrato de autenticación.
///
/// Las pantallas dependen de esta interfaz y no de Supabase, para poder
/// testearlas sin red y para poder cambiar de proveedor sin tocar la UI.
abstract interface class ServicioAuth {
  /// Emite cada vez que la sesión se abre o se cierra.
  Stream<bool> get cambiosDeSesion;

  /// Hay una sesión válida en este momento.
  bool get autenticado;

  /// Correo de la sesión actual, o null si no hay sesión.
  String? get correoActual;

  /// Lanza [FallaAuth] si las credenciales fallan o no hay conexión.
  Future<void> ingresar({required String correo, required String clave});

  /// Crea una cuenta nueva y **no** deja sesión abierta.
  ///
  /// Registrarse es mandar una solicitud, no entrar: la cuenta queda esperando
  /// que el doctor la apruebe. Dejar la sesión abierta haría que la persona
  /// quedara "adentro" viendo una pantalla que no la deja hacer nada, que se
  /// lee como que la app se rompió.
  ///
  /// El nombre, los apellidos y la cédula viajan como metadatos del registro;
  /// del otro lado, un disparador les arma la ficha para que el doctor sepa a
  /// quién está aprobando.
  Future<void> registrar({
    required String correo,
    required String clave,
    required String nombre,
    String? apellidos,
    String? cedula,
  });

  /// Borra la cuenta y **todo** lo que cuelga de ella, sin vuelta atrás.
  ///
  /// App Store y Google Play lo exigen: si la app deja crear una cuenta, tiene
  /// que dejar borrarla desde adentro.
  Future<void> eliminarCuenta();

  Future<void> salir();
}
