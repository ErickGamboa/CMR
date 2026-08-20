/// Modelo del libro de intercambios.
///
/// El libro impreso es una tabla con seis columnas —C, F, P, V, L y G— y una
/// fila por alimento: cada fila dice cuántos intercambios de cada grupo gasta
/// una porción. Acá se representa igual, para que lo que muestre la app se
/// pueda comparar renglón por renglón con el papel.
library;

import '../../core/intercambios.dart';

export '../../core/intercambios.dart';

/// Tipo de sección del libro.
enum TipoSeccion {
  /// Una de las seis secciones por grupo de intercambio.
  grupo,

  /// Bebidas alcohólicas y no alcohólicas: no son un grupo propio.
  bebidas,

  /// El menú de una cadena de restaurantes.
  restaurante,

  /// La lista de alimentos libres.
  libres;

  static TipoSeccion porNombre(String? nombre) {
    for (final t in values) {
      if (t.name == nombre) return t;
    }
    return TipoSeccion.grupo;
  }
}

/// Una sección del libro con sus alimentos.
class SeccionLibro {
  SeccionLibro({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.grupo,
    required this.nota,
    required this.alimentos,
  });

  factory SeccionLibro.desdeFila(
    Map<String, dynamic> fila,
    List<AlimentoLibro> alimentos,
  ) {
    return SeccionLibro(
      id: fila['id'] as String,
      nombre: fila['nombre'] as String,
      tipo: TipoSeccion.porNombre(fila['tipo'] as String?),
      grupo: GrupoIntercambio.porNombre(fila['grupo'] as String?),
      nota: fila['nota'] as String?,
      alimentos: alimentos,
    );
  }

  final String id;
  final String nombre;
  final TipoSeccion tipo;

  /// Grupo al que pertenece la sección, cuando aplica.
  final GrupoIntercambio? grupo;

  /// Aclaración que va bajo el título: por ejemplo, que el alcohol se cuenta
  /// como grasa.
  final String? nota;

  final List<AlimentoLibro> alimentos;
}

/// Un alimento del libro.
class AlimentoLibro {
  AlimentoLibro({
    required this.id,
    required this.seccionId,
    required this.subseccion,
    required this.nombre,
    required this.marcas,
    required this.porcion,
    required this.vale,
    required this.alternativa,
    required this.grasaVariable,
    required this.libre,
    required this.nota,
  }) : _busqueda = normalizar('$nombre ${marcas.join(' ')} ${subseccion ?? ''}');

  factory AlimentoLibro.desdeFila(Map<String, dynamic> fila) {
    return AlimentoLibro(
      id: fila['id'] as String,
      seccionId: fila['seccion_id'] as String,
      subseccion: fila['subseccion'] as String?,
      nombre: fila['nombre'] as String,
      marcas: (fila['marcas'] as List?)?.cast<String>() ?? const [],
      porcion: fila['porcion'] as String?,
      vale: Intercambios.desdeFila(fila),
      alternativa: Intercambios.desdeJson(fila['alternativa']),
      grasaVariable: fila['grasa_variable'] as bool? ?? false,
      libre: fila['libre'] as bool? ?? false,
      nota: fila['nota'] as String?,
    );
  }

  final String id;
  final String seccionId;

  /// Encabezado dentro de la sección: "Tortillas", "Acompañamientos".
  final String? subseccion;

  final String nombre;

  /// Marcas que el libro menciona. Van aparte del nombre para poder buscar
  /// "bimbo" o "dos pinos" y encontrar todo lo de esa marca.
  final List<String> marcas;

  final String? porcion;

  /// El conteo de la porción.
  final Intercambios vale;

  /// Conteo alternativo, para los alimentos que el libro anota con "ó": el
  /// queso fresco cuenta como 1 proteína **o** como 1 lácteo.
  final Intercambios? alternativa;

  /// La grasa depende de cómo se preparó el platillo (el "*" del libro).
  final bool grasaVariable;

  /// No gasta intercambios.
  final bool libre;

  final String? nota;

  final String _busqueda;

  /// Nombre con las marcas entre paréntesis, como en el libro impreso.
  String get nombreConMarcas =>
      marcas.isEmpty ? nombre : '$nombre (${marcas.join(', ')})';

  /// La consulta tiene que venir ya normalizada con [normalizar].
  bool coincideCon(String consulta) => _busqueda.contains(consulta);

  /// Si el alimento gasta ese grupo, contando también el conteo alternativo.
  bool gasta(GrupoIntercambio grupo) =>
      vale.gasta(grupo) || (alternativa?.gasta(grupo) ?? false);
}

/// El libro completo.
class Libro {
  const Libro(this.secciones);

  final List<SeccionLibro> secciones;

  /// Las secciones por grupo, más las dos de bebidas. Son las que el paciente
  /// consulta para armar una comida.
  List<SeccionLibro> get alimentos => secciones
      .where((s) => s.tipo == TipoSeccion.grupo || s.tipo == TipoSeccion.bebidas)
      .toList();

  List<SeccionLibro> get restaurantes =>
      secciones.where((s) => s.tipo == TipoSeccion.restaurante).toList();

  List<SeccionLibro> get libres =>
      secciones.where((s) => s.tipo == TipoSeccion.libres).toList();

  int get total =>
      secciones.fold(0, (suma, s) => suma + s.alimentos.length);
}

/// Pasa el texto a minúsculas y le quita las tildes, para que "melon",
/// "Melón" y "MELON" busquen lo mismo.
String normalizar(String texto) {
  const tildes = 'áàäâãéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ';
  const planas = 'aaaaaeeeeiiiiooooouuuuncAAAAAEEEEIIIIOOOOOUUUUNC';

  final salida = StringBuffer();
  for (final unidad in texto.toLowerCase().runes) {
    final caracter = String.fromCharCode(unidad);
    final i = tildes.indexOf(caracter);
    salida.write(i == -1 ? caracter : planas[i]);
  }
  return salida.toString();
}
