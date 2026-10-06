import 'package:supabase_flutter/supabase_flutter.dart';

import 'local/sincronizador.dart';

/// Qué módulos opcionales tiene prendidos el paciente de la sesión.
///
/// No todos los módulos son para todos: el doctor decide, paciente por
/// paciente, cuáles ve. Los que no dependen de eso ni pasan por acá.
abstract interface class FuenteModulos {
  /// Las claves habilitadas, ej. `{'mapeo'}`.
  Future<Set<String>> habilitados();
}

/// Baja de `pacientes_modulos` las claves habilitadas.
///
/// Se guarda en el teléfono como el resto: si no, sin señal la ficha de Mapeo
/// desaparecería del Home justo cuando el paciente quiere anotar.
Future<Object?> bajarModulos(SupabaseClient db) async {
  final filas = await db
      .from('pacientes_modulos')
      .select('modulo')
      .eq('habilitado', true);

  return [
    for (final fila in filas)
      if (fila['modulo'] case final String m) m,
  ];
}

/// Lee de la copia local qué módulos tiene prendidos.
///
/// Ante cualquier problema devuelve el conjunto vacío en vez de reventar: un
/// módulo opcional que no se pudo confirmar se trata como apagado. Es la
/// opción segura —el paciente ve el Home de siempre— y además es lo que hace
/// que la pantalla de Inicio funcione en los tests, donde no hay Supabase.
class RepositorioModulos implements FuenteModulos {
  const RepositorioModulos();

  @override
  Future<Set<String>> habilitados() async {
    try {
      final datos = await Sincronizador.actual?.leer(Claves.modulos);
      return {...?(datos as List<dynamic>?)?.cast<String>()};
    } on Object {
      return const {};
    }
  }
}
