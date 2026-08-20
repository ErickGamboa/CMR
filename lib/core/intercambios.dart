/// Los grupos de intercambio y su aritmética.
///
/// Vive en `core` porque lo comparten el libro (cuánto gasta un alimento) y
/// el plan de alimentación (cuánto le toca al paciente por día).
library;

/// Los seis grupos de intercambio, en el orden de las columnas del libro.
enum GrupoIntercambio {
  carbohidratos(
    letra: 'C',
    columna: 'c',
    etiqueta: 'Carbohidratos',
    singular: 'carbohidrato',
    plural: 'carbohidratos',
  ),
  frutas(
    letra: 'F',
    columna: 'f',
    etiqueta: 'Frutas',
    singular: 'fruta',
    plural: 'frutas',
  ),
  proteinas(
    letra: 'P',
    columna: 'p',
    etiqueta: 'Proteínas',
    singular: 'proteína',
    plural: 'proteínas',
  ),
  vegetales(
    letra: 'V',
    columna: 'v',
    etiqueta: 'Vegetales',
    singular: 'vegetal',
    plural: 'vegetales',
  ),
  lacteos(
    letra: 'L',
    columna: 'l',
    etiqueta: 'Lácteos',
    singular: 'lácteo',
    plural: 'lácteos',
  ),
  grasas(
    letra: 'G',
    columna: 'g',
    etiqueta: 'Grasas',
    singular: 'grasa',
    plural: 'grasas',
  );

  const GrupoIntercambio({
    required this.letra,
    required this.columna,
    required this.etiqueta,
    required this.singular,
    required this.plural,
  });

  /// La letra de la columna en el libro impreso.
  final String letra;

  /// Nombre de la columna en la tabla de Supabase.
  final String columna;

  final String etiqueta;
  final String singular;
  final String plural;

  /// Convierte el valor del enum `grupo_intercambio` de Postgres.
  static GrupoIntercambio? porNombre(String? nombre) {
    for (final g in values) {
      if (g.name == nombre) return g;
    }
    return null;
  }
}

/// Cuántos intercambios de cada grupo gasta una porción.
///
/// Solo guarda los grupos con cantidad distinta de cero: la mayoría de los
/// alimentos gasta uno o dos, y así recorrerlos es directo.
class Intercambios {
  const Intercambios(this._valores);

  /// Lee las columnas c, f, p, v, l y g de una fila de `libro_alimentos`.
  factory Intercambios.desdeFila(Map<String, dynamic> fila) {
    return Intercambios._desde((g) => _aDouble(fila[g.columna]));
  }

  /// Lee el jsonb de `alternativa`, que solo trae los grupos que cambian.
  static Intercambios? desdeJson(Object? json) {
    if (json is! Map) return null;
    final valores = Intercambios._desde((g) => _aDouble(json[g.columna]));
    return valores.vacio ? null : valores;
  }

  factory Intercambios._desde(double Function(GrupoIntercambio) leer) {
    final valores = <GrupoIntercambio, double>{};
    for (final g in GrupoIntercambio.values) {
      final v = leer(g);
      if (v > 0) valores[g] = v;
    }
    return Intercambios(valores);
  }

  final Map<GrupoIntercambio, double> _valores;

  double operator [](GrupoIntercambio grupo) => _valores[grupo] ?? 0;

  bool get vacio => _valores.isEmpty;

  /// Los grupos que gasta, en el orden de las columnas del libro.
  Iterable<(GrupoIntercambio, double)> get presentes =>
      GrupoIntercambio.values
          .where(_valores.containsKey)
          .map((g) => (g, _valores[g]!));

  bool gasta(GrupoIntercambio grupo) => _valores.containsKey(grupo);

  /// "1 carbohidrato + 1 grasa". Es la forma en que la hoja de detalle explica
  /// el conteo, porque "1 C + 1 G" no lo entiende nadie la primera vez.
  String enPalabras() => presentes
      .map((e) => '${formatearCantidad(e.$2)} '
          '${e.$2 == 1 ? e.$1.singular : e.$1.plural}')
      .join(' + ');

  static double _aDouble(Object? valor) => switch (valor) {
        num v => v.toDouble(),
        String v => double.tryParse(v) ?? 0,
        _ => 0,
      };
}

/// Escribe las cantidades como las escribe el libro: los medios con ½ en vez
/// de 0.5, y sin decimal cuando es entero.
String formatearCantidad(double cantidad) {
  final entero = cantidad.truncate();
  final resto = cantidad - entero;
  final medio = (resto - 0.5).abs() < 0.01;

  if (medio) return entero == 0 ? '½' : '$entero½';
  if (resto.abs() < 0.01) return '$entero';
  return cantidad.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}

