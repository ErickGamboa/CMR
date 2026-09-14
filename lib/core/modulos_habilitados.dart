import 'package:supabase_flutter/supabase_flutter.dart';

/// Qué módulos opcionales tiene prendidos el paciente de la sesión.
///
/// No todos los módulos son para todos: el doctor decide, paciente por
/// paciente, cuáles ve. Los que no dependen de eso ni pasan por acá.
abstract interface class FuenteModulos {
  /// Las claves habilitadas, ej. `{'mapeo'}`.
  Future<Set<String>> habilitados();
}

/// Lee `pacientes_modulos` de Supabase.
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
      final filas = await Supabase.instance.client
          .from('pacientes_modulos')
          .select('modulo')
          .eq('habilitado', true);

      return {
        for (final fila in filas)
          if (fila['modulo'] case final String m) m,
      };
    } on Object {
      return const {};
    }
  }
}
