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

  Future<void> salir();
}
