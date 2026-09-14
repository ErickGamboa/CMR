import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/ocultar_teclado.dart';
import 'modelo_libro.dart';
import 'repositorio_libro.dart';
import 'widgets/fila_alimento.dart';
import 'widgets/hoja_alimento.dart';
import 'widgets/hoja_simbologia.dart';
import 'widgets/pildora_intercambio.dart';

/// Módulo Libro: la lista de intercambios de alimentos.
///
/// Reemplaza al PDF que se pasaba por WhatsApp. Las tres cosas que el papel no
/// podía dar y que definen esta pantalla:
///
///  - **Buscar.** El libro tiene 284 alimentos; encontrar "wrap integral" en
///    el PDF es raspar catorce páginas. Acá se escribe y aparece, buscando
///    también por marca ("bimbo", "dos pinos").
///  - **Filtrar por grupo.** La pregunta real del paciente no es "¿qué tiene
///    esta galleta?", es "¿qué puedo comer que me cuente 1 carbohidrato?".
///  - **Explicar.** En el papel, "1 C + ½ G" no se entiende sin volver a la
///    primera página. Acá cada alimento se abre y lo dice con palabras.
class LibroScreen extends StatefulWidget {
  const LibroScreen({super.key, this.fuente, this.filtroInicial = const {}});

  /// De dónde se lee el libro. En la app va sin definir y sale de Supabase;
  /// los tests inyectan una fuente falsa para no depender de la red.
  final FuenteLibro? fuente;

  /// Grupos ya filtrados al abrir. Se usa cuando el paciente llega desde su
  /// plan tocando "te tocan 2 carbohidratos": el libro abre mostrando
  /// justamente los alimentos que cuentan carbohidratos.
  final Set<GrupoIntercambio> filtroInicial;

  @override
  State<LibroScreen> createState() => _LibroScreenState();
}

class _LibroScreenState extends State<LibroScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _pestanas = TabController(length: 3, vsync: this)
    ..addListener(_alCambiarPestana);

  FuenteLibro? _fuente;
  late Future<Libro> _carga = _cargar();

  /// La fuente se resuelve dentro de este `async` a propósito: si Supabase no
  /// está inicializado, el error cae en el [FutureBuilder] y la pantalla
  /// muestra "Intentar de nuevo" en vez de reventar el árbol de widgets.
  Future<Libro> _cargar({bool deNuevo = false}) async {
    final fuente = _fuente ??=
        widget.fuente ?? RepositorioLibro(Supabase.instance.client);
    return deNuevo ? fuente.recargar() : fuente.cargar();
  }

  final TextEditingController _texto = TextEditingController();

  /// Ya normalizada, para no repetir el trabajo en cada fila.
  String _consulta = '';

  late final Set<GrupoIntercambio> _filtros = {...widget.filtroInicial};

  int _pestanaActual = 0;

  static const _indiceLibres = 2;

  void _alCambiarPestana() {
    if (_pestanas.index == _pestanaActual) return;
    // Cambiar de pestaña es irse a otra cosa: el buscador suelta el teclado.
    OcultarTeclado.soltarFoco();
    setState(() => _pestanaActual = _pestanas.index);
  }

  @override
  void dispose() {
    _pestanas.removeListener(_alCambiarPestana);
    _pestanas.dispose();
    _texto.dispose();
    super.dispose();
  }

  void _limpiarBusqueda() {
    OcultarTeclado.soltarFoco();
    _texto.clear();
    setState(() => _consulta = '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Libro'),
        actions: [
          IconButton(
            onPressed: () => HojaSimbologia.mostrar(context),
            icon: const Icon(Icons.help_outline),
            tooltip: 'Cómo leer el libro',
          ),
        ],
        bottom: TabBar(
          controller: _pestanas,
          tabs: const [
            Tab(text: 'Alimentos'),
            Tab(text: 'Restaurantes'),
            Tab(text: 'Libres'),
          ],
        ),
      ),
      body: FutureBuilder<Libro>(
        future: _carga,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Falla(
              mensaje: snapshot.error is FallaLibro
                  ? (snapshot.error! as FallaLibro).mensaje
                  : 'No pudimos cargar el libro.',
              onReintentar: () => setState(() {
                _carga = _cargar(deNuevo: true);
              }),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final libro = snapshot.data!;
          final enLibres = _pestanaActual == _indiceLibres;

          return Column(
            children: [
              _Buscador(
                controller: _texto,
                onChanged: (valor) =>
                    setState(() => _consulta = normalizar(valor.trim())),
                onLimpiar: _limpiarBusqueda,
              ),
              if (!enLibres)
                _FiltrosDeGrupo(
                  seleccionados: _filtros,
                  onCambio: (grupo) {
                    OcultarTeclado.soltarFoco();
                    setState(() {
                      if (!_filtros.remove(grupo)) _filtros.add(grupo);
                    });
                  },
                ),
              Expanded(
                child: TabBarView(
                  controller: _pestanas,
                  children: [
                    _Lista(
                      secciones: libro.alimentos,
                      consulta: _consulta,
                      filtros: _filtros,
                      onLimpiar: _limpiarBusqueda,
                    ),
                    _Lista(
                      secciones: libro.restaurantes,
                      consulta: _consulta,
                      filtros: _filtros,
                      onLimpiar: _limpiarBusqueda,
                    ),
                    // Los alimentos libres no gastan intercambios, así que los
                    // filtros por grupo no aplican acá.
                    _Lista(
                      secciones: libro.libres,
                      consulta: _consulta,
                      filtros: const {},
                      onLimpiar: _limpiarBusqueda,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Buscador extends StatelessWidget {
  const _Buscador({
    required this.controller,
    required this.onChanged,
    required this.onLimpiar,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Busca un alimento o una marca',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: onLimpiar,
                  icon: const Icon(Icons.close),
                  tooltip: 'Limpiar',
                ),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
  }
}

/// Los seis grupos como filtro. Filtran por "qué me cuenta este alimento",
/// que es como se usa el libro cuando ya se sabe qué falta del día.
class _FiltrosDeGrupo extends StatelessWidget {
  const _FiltrosDeGrupo({required this.seleccionados, required this.onCambio});

  final Set<GrupoIntercambio> seleccionados;
  final ValueChanged<GrupoIntercambio> onCambio;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final grupo in GrupoIntercambio.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: FilterChip(
                selected: seleccionados.contains(grupo),
                onSelected: (_) => onCambio(grupo),
                label: Text(grupo.etiqueta),
                avatar: seleccionados.contains(grupo)
                    ? null
                    : CircleAvatar(
                        backgroundColor: PildoraIntercambio.coloresDe(
                          grupo,
                        ).fondo,
                        child: Text(
                          grupo.letra,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: PildoraIntercambio.coloresDe(grupo).texto,
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

/// La lista de una pestaña.
///
/// Sin búsqueda ni filtros muestra el libro con sus encabezados, igual que el
/// papel, para poder hojearlo. Con búsqueda o filtros pasa a una lista plana
/// de resultados, donde cada fila dice de qué sección salió.
class _Lista extends StatelessWidget {
  const _Lista({
    required this.secciones,
    required this.consulta,
    required this.filtros,
    required this.onLimpiar,
  });

  final List<SeccionLibro> secciones;
  final String consulta;
  final Set<GrupoIntercambio> filtros;
  final VoidCallback onLimpiar;

  bool get _filtrando => consulta.isNotEmpty || filtros.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final entradas = _filtrando ? _resultados() : _libroCompleto();

    if (entradas.isEmpty) {
      return _SinResultados(consulta: consulta, onLimpiar: onLimpiar);
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(top: 4, bottom: 32),
      itemCount: entradas.length,
      separatorBuilder: (context, i) {
        final siguiente = entradas[i + 1];
        // Solo se separan filas contiguas: antes de un encabezado ya hay aire.
        return siguiente is _FilaDeAlimento && entradas[i] is _FilaDeAlimento
            ? const Divider(height: 1, indent: 16, endIndent: 16)
            : const SizedBox.shrink();
      },
      itemBuilder: (context, i) => entradas[i].construir(context),
    );
  }

  List<_Entrada> _libroCompleto() {
    final entradas = <_Entrada>[];
    for (final seccion in secciones) {
      if (seccion.alimentos.isEmpty) continue;
      entradas.add(_TituloSeccion(seccion));

      String? subseccionAnterior;
      for (final alimento in seccion.alimentos) {
        if (alimento.subseccion != null &&
            alimento.subseccion != subseccionAnterior) {
          entradas.add(_TituloSubseccion(alimento.subseccion!));
        }
        subseccionAnterior = alimento.subseccion;
        entradas.add(_FilaDeAlimento(alimento: alimento, seccion: seccion));
      }
    }
    return entradas;
  }

  List<_Entrada> _resultados() {
    final encontrados = <_FilaDeAlimento>[];
    for (final seccion in secciones) {
      for (final alimento in seccion.alimentos) {
        if (consulta.isNotEmpty && !alimento.coincideCon(consulta)) continue;
        if (filtros.isNotEmpty && !filtros.any(alimento.gasta)) continue;
        encontrados.add(
          _FilaDeAlimento(
            alimento: alimento,
            seccion: seccion,
            conContexto: true,
          ),
        );
      }
    }
    if (encontrados.isEmpty) return const [];
    return [_Conteo(encontrados.length), ...encontrados];
  }
}

sealed class _Entrada {
  const _Entrada();

  Widget construir(BuildContext context);
}

class _TituloSeccion extends _Entrada {
  const _TituloSeccion(this.seccion);

  final SeccionLibro seccion;

  @override
  Widget construir(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainer,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            seccion.nombre,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          if (seccion.nota != null) ...[
            const SizedBox(height: 4),
            Text(
              seccion.nota!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TituloSubseccion extends _Entrada {
  const _TituloSubseccion(this.nombre);

  final String nombre;

  @override
  Widget construir(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        nombre.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Conteo extends _Entrada {
  const _Conteo(this.cantidad);

  final int cantidad;

  @override
  Widget construir(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        cantidad == 1 ? '1 alimento' : '$cantidad alimentos',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _FilaDeAlimento extends _Entrada {
  const _FilaDeAlimento({
    required this.alimento,
    required this.seccion,
    this.conContexto = false,
  });

  final AlimentoLibro alimento;
  final SeccionLibro seccion;
  final bool conContexto;

  @override
  Widget construir(BuildContext context) {
    return FilaAlimento(
      alimento: alimento,
      contexto: conContexto
          ? [
              seccion.nombre,
              if (alimento.subseccion != null) alimento.subseccion!,
            ].join(' · ')
          : null,
      onTap: () =>
          HojaAlimento.mostrar(context, alimento: alimento, seccion: seccion),
    );
  }
}

class _SinResultados extends StatelessWidget {
  const _SinResultados({required this.consulta, required this.onLimpiar});

  final String consulta;
  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 44,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              consulta.isEmpty
                  ? 'Ningún alimento de esta sección cuenta en los grupos que '
                        'elegiste.'
                  : 'No encontramos nada en esta sección.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Prueba en otra pestaña o cambia la búsqueda.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (consulta.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onLimpiar,
                child: const Text('Limpiar búsqueda'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Falla extends StatelessWidget {
  const _Falla({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 18),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 18),
            FilledButton.tonal(
              onPressed: onReintentar,
              child: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}
