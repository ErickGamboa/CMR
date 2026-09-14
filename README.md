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
  core/
    auth/         sesión contra Supabase
    datos/        modelos y repositorios de lo que el doctor carga
    fechas.dart   formato de fechas en español, sin intl
    iconos.dart   catálogo cerrado de íconos que el doctor puede elegir
  features/       una carpeta por módulo (inicio, auth, libro, plan, mapeo…)
  theme/          paleta de marca y tema Material 3
  widgets/        widgets compartidos
supabase/
  migrations/     esquema completo y datos del libro de intercambios
  plantillas/     scripts que el doctor corre a mano
tool/             generador de assets de marca
```

## Base de datos

El libro de intercambios y el plan de alimentación viven en Supabase. Las
migraciones se aplican **en orden de nombre**, desde el SQL Editor o con la
CLI:

```bash
supabase db push          # o pegar los archivos de supabase/migrations/ en orden
```

**Nada de lo que ve el paciente está quemado en el código.** Todo sale de la
base, y cada quien ve lo suyo: citas, mediciones, laboratorios, recomendaciones,
suplementos, péptidos, medicamentos, plan de alimentación y mapeo van por
`paciente_id` con RLS contra `auth.uid()`. El libro de intercambios, las marcas
de suplementos y los videos son catálogo público: el mismo para todos.

La app **solo lee**, con dos excepciones que el paciente sí escribe: el mapeo
(su presión y su glisemia) y, cuando se conecte, sus favoritos del libro.

Scripts que el doctor corre a mano hasta que el sitio admin los reemplace:

| script | qué hace |
|---|---|
| `plantillas/alta_doctor_y_pacientes.sql` | da de alta al doctor y crea la ficha de los pacientes que ya tienen cuenta |
| `plantillas/cargar_paciente.sql` | citas, mediciones, laboratorios, recomendaciones y recetas de un paciente |
| `plantillas/asignar_plan.sql` | el plan de alimentación |
| `plantillas/catalogo.sql` | marcas de suplementos y videos (global) |
| `plantillas/habilitar_modulo.sql` | prende o apaga un módulo opcional (hoy solo Mapeo) |

Un paciente sin nada cargado no ve datos de nadie: cada módulo dice "Todavía no
tienes…" y la app funciona igual.

### Quién escribe

La app **solo lee** (menos el mapeo). Quien escribe expedientes es el doctor, y
eso lo decide la base: la tabla `doctores` dice quién lo es, la función
`es_doctor()` lo resuelve, y cada tabla tiene una política `..._doctor` que la
usa. Varias políticas permisivas sobre la misma tabla se suman con OR, así que
el paciente sigue viendo lo suyo por su política y el doctor pasa por la suya.

La llave `service_role` **no se usa y no debería desplegarse**: se salta RLS por
completo. La única cosa que la va a necesitar algún día es crear cuentas en
Supabase Auth, porque eso es la Admin API; hoy eso se hace desde el panel.

### Íconos

Las recomendaciones y las categorías de suplementos llevan un ícono que el
doctor elige, pero no puede ser cualquiera: un ícono es un glifo de una fuente
compilada dentro de la app. El catálogo de nombres válidos está en
`lib/core/iconos.dart`, y un nombre que la app no conozca cae en el genérico
en vez de romper la pantalla.

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

## Sitio del doctor

En construcción, en `admin/`: **Next.js (App Router) + TypeScript + Supabase +
shadcn/ui**, desplegado en Vercel con *Root Directory* = `admin`.

Vive en este repo, no en uno aparte, porque el sitio y la app están atados por
el esquema: los dos escriben y leen los mismos nombres de columna y los mismos
valores (`'peptido'`, `'medica'`, los nombres de ícono). Con las migraciones en
un solo lugar no hay forma de que se desincronicen sin que se note.

Entra con la sesión del doctor —no con `service_role`— y por eso depende de las
políticas descritas arriba.

## Pendiente

Faltan las fotos de producto de los suplementos, y los videos oficiales: los
que estén cargados hoy son de prueba y se cambian en la tabla `videos`.

La app todavía no lee `pacientes`: el paciente no ve su nombre en ningún lado.
La tabla ya existe y se puede conectar sin tocar el esquema.

Del libro y el plan queda por hacer:

- **Favoritos del libro.** La tabla `libro_favoritos` está creada; la app
  todavía no la usa.
- **Contador del día.** Con el plan y el libro ya en la misma app, el paso que
  falta es poder marcar lo que se comió y descontarlo de lo que le toca hoy.
- Una fila del menú de McDonald's quedó en `por_revisar` y no se muestra
  (ver LIBRO_REVISION.md, §4).
