import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/datos/modelos.dart';
import '../../core/datos/repositorio.dart';
import '../../widgets/carga_de_datos.dart';
import '../../widgets/recarga.dart';

/// Módulo Videos: el material que el doctor publica para todos los pacientes.
///
/// Los videos no se reproducen dentro de la app: se abren en YouTube, en el
/// navegador o en la app que corresponda según el enlace. Así el doctor puede
/// cambiar de plataforma sin que la app se entere.
class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key, this.fuente});

  /// De dónde salen. En la app va sin definir y sale de Supabase; los tests
  /// inyectan una fuente falsa.
  final FuenteCatalogo? fuente;

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  final _recarga = ControlRecarga();

  @override
  void dispose() {
    _recarga.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
        actions: [BotonRecargar(control: _recarga)],
      ),
      body: CargaDeDatos<List<Video>>(
        control: _recarga,
        cargar: () => (widget.fuente ?? RepositorioCatalogo()).videos(),
        vacio: const SinDatos(
          icono: Icons.play_circle_outline,
          mensaje: 'Todavía no hay videos publicados.',
        ),
        constructor: (context, videos) => _Lista(videos: videos),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.videos});

  final List<Video> videos;

  Future<void> _abrir(BuildContext context, Video video) async {
    final destino = Uri.tryParse(video.url);
    final abrio =
        destino != null &&
        await launchUrl(destino, mode: LaunchMode.externalApplication);

    if (abrio || !context.mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('No pudimos abrir este video.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Se abren fuera de la app',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        for (final v in videos)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _abrir(context, v),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.tertiaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 22,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.titulo,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (v.descripcion case final d?
                              when d.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(d, style: theme.textTheme.bodyMedium),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.open_in_new,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
