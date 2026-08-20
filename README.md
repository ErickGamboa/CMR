# CMR — Control Metabólico & Regenerativo

App móvil (Android e iOS) para los pacientes de la Clínica CMR.

Las cuentas las administra el doctor desde el sitio web: la app solo consume
sesiones, no tiene registro ni recuperación de contraseña.

## Requisitos

- Flutter 3.44 o superior (Dart 3.12)
- Android SDK para compilar en Android, Xcode para iOS

## Configuración

La clave de Supabase no está en el repositorio. Antes de compilar:

```bash
cp config/supabase.example.json config/supabase.json
```

Y poné en ese archivo la clave publicable del proyecto (Supabase → Project
Settings → API Keys; empieza con `sb_publishable_`). Es pública por diseño —va
dentro del cliente y lo que protege los datos es RLS—, pero se mantiene fuera
del repo para poder rotarla sin tocar el código.

`config/supabase.json` está en `.gitignore`. **Nunca uses la clave
`service_role` en la app.**

## Correr

```bash
flutter run --dart-define-from-file=config/supabase.json
```

Sin la clave la app no revienta: muestra una pantalla que explica qué falta.

## Tests

```bash
flutter test
```

## Estructura

```
lib/
  core/           auth, configuración, datos de demo, intercambios, etiquetas
  features/       una carpeta por módulo (inicio, auth, libro, plan…)
  theme/          paleta de marca y tema Material 3
  widgets/        widgets compartidos
supabase/
  migrations/     esquema y datos del libro de intercambios
  plantillas/     scripts que el doctor corre a mano (asignar un plan)
tool/             generador de assets de marca
```

## Base de datos

El libro de intercambios y el plan de alimentación viven en Supabase. Las
migraciones se aplican **en orden de nombre**, desde el SQL Editor o con la
CLI:

```bash
supabase db push          # o pegar los archivos de supabase/migrations/ en orden
```

El libro es un catálogo público —el mismo para todos los pacientes— que el
doctor mantiene desde el panel de Supabase; la app solo lo lee. El plan es por
paciente y se asigna con `supabase/plantillas/asignar_plan.sql`.

Qué se corrigió al transcribir el libro del PDF, y con qué criterio, está en
[LIBRO_REVISION.md](LIBRO_REVISION.md).

Las pantallas dependen de la interfaz `ServicioAuth`, no de Supabase, así que
los tests corren sin red ni credenciales.

## Marca

La paleta es fija y vive solo en `lib/theme/app_colors.dart`:

| color | hex | rol |
|---|---|---|
| azul abisal | `#090972` | primario |
| turquesa biocelular | `#62A1A6` | secundario |
| azul vital | `#86DBFB` | acento |

Los íconos y las imágenes del splash se generan del logo original:

```bash
dart run tool/build_brand_assets.dart <ruta-al-logo.png>
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Pendiente

Los datos de `lib/core/datos_demo.dart` son inventados y se reemplazan cuando
se conecten las tablas reales. Faltan también las fotos de producto de los
suplementos.

Del libro y el plan queda por hacer:

- **Favoritos del libro.** La tabla `libro_favoritos` está creada; la app
  todavía no la usa.
- **Contador del día.** Con el plan y el libro ya en la misma app, el paso que
  falta es poder marcar lo que se comió y descontarlo de lo que le toca hoy.
- Una fila del menú de McDonald's quedó en `por_revisar` y no se muestra
  (ver LIBRO_REVISION.md, §4).
