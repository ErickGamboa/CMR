-- ---------------------------------------------------------------------------
-- Todo lo que el doctor le receta o le registra a cada paciente
-- ---------------------------------------------------------------------------
--
-- Hasta esta migración, citas, mediciones, laboratorios, recomendaciones,
-- suplementos, péptidos y medicamentos vivían quemados en el código de la app
-- (lib/core/datos_demo.dart) y eran los mismos para todo el mundo. Acá pasan a
-- la base, por paciente, para que el doctor los maneje desde el sitio admin y
-- publicar una versión nueva de la app deje de ser un requisito para cambiar
-- un dato.
--
-- Dos reglas que valen para todo el archivo:
--
--   * Lo del paciente lleva `paciente_id` y RLS contra `auth.uid()`: cada
--     quien ve lo suyo y nada más.
--   * Lo que es catálogo (marcas de suplementos, videos) no lleva paciente:
--     es igual para todos, como el libro de intercambios.
--
-- La app solo lee. Escribir es tarea del doctor, así que ninguna política da
-- insert, update ni delete al paciente.

-- ---------------------------------------------------------------------------
-- Citas
-- ---------------------------------------------------------------------------

create table if not exists citas (
  id            uuid primary key default gen_random_uuid(),
  paciente_id   uuid not null references auth.users(id) on delete cascade,

  -- `timestamp` sin zona horaria a propósito: es la hora del reloj de la
  -- clínica. Con `timestamptz` el doctor escribiría "10:30" y al paciente le
  -- aparecería a las 4:30 a.m., porque Postgres guarda en UTC y la app lo
  -- volvería a convertir.
  fecha         timestamp not null,

  tipo          text not null check (tipo in ('medica', 'enfermeria')),
  profesional   text not null,
  especialidad  text not null,
  lugar         text not null,

  creado_en     timestamptz not null default now()
);

create index if not exists citas_paciente_idx on citas (paciente_id, fecha);

comment on table citas is 'Agenda de cada paciente, médica y de enfermería.';

-- ---------------------------------------------------------------------------
-- Mediciones de composición corporal
-- ---------------------------------------------------------------------------

create table if not exists mediciones (
  id                uuid primary key default gen_random_uuid(),
  paciente_id       uuid not null references auth.users(id) on delete cascade,
  fecha             date not null,

  peso              numeric(5,2) not null check (peso > 0),
  porcentaje_grasa  numeric(5,2) not null check (porcentaje_grasa >= 0),
  grasa_visceral    numeric(5,2) not null check (grasa_visceral >= 0),

  -- Acumulados desde el inicio del plan, no contra la medición anterior.
  grasa_perdida     numeric(5,2) not null default 0,
  musculo_ganado    numeric(5,2) not null default 0,

  creado_en         timestamptz not null default now(),

  -- Una medición por día: si se repite, se corrige la que hay.
  constraint mediciones_una_por_dia unique (paciente_id, fecha)
);

create index if not exists mediciones_paciente_idx
  on mediciones (paciente_id, fecha);

comment on table mediciones is
  'Bioimpedancia por paciente. Grasa perdida y músculo ganado son acumulados.';

-- ---------------------------------------------------------------------------
-- Laboratorios
-- ---------------------------------------------------------------------------

create table if not exists laboratorios (
  id           uuid primary key default gen_random_uuid(),
  paciente_id  uuid not null references auth.users(id) on delete cascade,
  fecha        date not null,

  -- El panel solicitado. Ej.: "Perfil metabólico completo".
  nombre       text not null,

  creado_en    timestamptz not null default now()
);

create index if not exists laboratorios_paciente_idx
  on laboratorios (paciente_id, fecha desc);

create table if not exists laboratorio_analisis (
  id              uuid primary key default gen_random_uuid(),
  laboratorio_id  uuid not null references laboratorios(id) on delete cascade,

  nombre          text not null,

  -- Texto y no número: hay resultados que no lo son ("< 0.5", "negativo").
  valor           text not null,

  unidad          text not null default '',
  referencia      text not null default '',

  -- Lo marca el doctor, no lo calcula la app: el rango viene como texto y
  -- adivinar cuándo un valor se sale de él sería inventar criterio clínico.
  fuera_de_rango  boolean not null default false,

  orden           smallint not null default 0
);

create index if not exists laboratorio_analisis_lab_idx
  on laboratorio_analisis (laboratorio_id, orden);

comment on column laboratorio_analisis.fuera_de_rango is
  'Lo marca el doctor. La app solo lo muestra.';

-- ---------------------------------------------------------------------------
-- Recomendaciones
-- ---------------------------------------------------------------------------

create table if not exists recomendaciones (
  id           uuid primary key default gen_random_uuid(),
  paciente_id  uuid not null references auth.users(id) on delete cascade,
  fecha        date not null default current_date,

  titulo       text not null,
  texto        text not null,

  -- Nombre de ícono de un catálogo cerrado que vive en la app
  -- (lib/core/iconos.dart). Un nombre que la app no conozca cae en el ícono
  -- genérico, así que escribir cualquier cosa no rompe la pantalla.
  icono        text not null default 'consejo',

  creado_en    timestamptz not null default now()
);

create index if not exists recomendaciones_paciente_idx
  on recomendaciones (paciente_id, fecha desc);

-- ---------------------------------------------------------------------------
-- Prescripciones: suplementos, péptidos y medicamentos
-- ---------------------------------------------------------------------------
--
-- Una sola tabla para los tres porque son la misma cosa con distinto nombre:
-- algo que el doctor indicó, con dosis, frecuencia e indicación. La app ya los
-- dibuja con la misma tarjeta.

create table if not exists prescripciones (
  id           uuid primary key default gen_random_uuid(),
  paciente_id  uuid not null references auth.users(id) on delete cascade,

  tipo         text not null
                 check (tipo in ('suplemento', 'peptido', 'medicamento')),

  nombre       text not null,
  dosis        text not null,
  frecuencia   text not null,

  -- Cómo o cuándo tomarlo. Ej.: "con el desayuno", "vía subcutánea".
  indicacion   text,

  -- Suspender algo no es borrarlo: el historial del paciente se conserva y la
  -- app deja de mostrarlo.
  activo       boolean not null default true,

  orden        smallint not null default 0,
  creado_en    timestamptz not null default now()
);

create index if not exists prescripciones_paciente_idx
  on prescripciones (paciente_id, tipo, orden);

comment on table prescripciones is
  'Suplementos, péptidos y medicamentos indicados por el doctor a un paciente.';

-- ---------------------------------------------------------------------------
-- Catálogo de marcas de suplementos (igual para todos)
-- ---------------------------------------------------------------------------

create table if not exists suplemento_categorias (
  id      text primary key,
  nombre  text not null,
  icono   text not null default 'suplemento',
  orden   smallint not null
);

create table if not exists suplemento_marcas (
  id            uuid primary key default gen_random_uuid(),
  categoria_id  text not null
                  references suplemento_categorias(id) on delete cascade,
  nombre        text not null,
  presentacion  text not null,
  orden         smallint not null default 0
);

create index if not exists suplemento_marcas_categoria_idx
  on suplemento_marcas (categoria_id, orden);

comment on table suplemento_categorias is
  'Catálogo público de tipos de suplemento. El mismo para todos los pacientes.';

-- ---------------------------------------------------------------------------
-- Videos (igual para todos)
-- ---------------------------------------------------------------------------

create table if not exists videos (
  id           uuid primary key default gen_random_uuid(),
  titulo       text not null,
  descripcion  text,

  -- A dónde lleva el video: YouTube, Vimeo o un archivo en Supabase Storage.
  -- La app abre el enlace en la app que corresponda.
  url          text not null,

  -- Despublicar en vez de borrar, igual que con las prescripciones.
  publicado    boolean not null default true,

  orden        smallint not null default 0,
  creado_en    timestamptz not null default now()
);

create index if not exists videos_orden_idx on videos (orden) where publicado;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table citas                 enable row level security;
alter table mediciones            enable row level security;
alter table laboratorios          enable row level security;
alter table laboratorio_analisis  enable row level security;
alter table recomendaciones       enable row level security;
alter table prescripciones        enable row level security;
alter table suplemento_categorias enable row level security;
alter table suplemento_marcas     enable row level security;
alter table videos                enable row level security;

drop policy if exists citas_propias on citas;
create policy citas_propias on citas
  for select to authenticated using (paciente_id = auth.uid());

drop policy if exists mediciones_propias on mediciones;
create policy mediciones_propias on mediciones
  for select to authenticated using (paciente_id = auth.uid());

drop policy if exists laboratorios_propios on laboratorios;
create policy laboratorios_propios on laboratorios
  for select to authenticated using (paciente_id = auth.uid());

-- Los analitos no llevan paciente: cuelgan del laboratorio, y es el
-- laboratorio el que decide de quién son.
drop policy if exists laboratorio_analisis_propios on laboratorio_analisis;
create policy laboratorio_analisis_propios on laboratorio_analisis
  for select to authenticated using (
    exists (
      select 1 from laboratorios l
      where l.id = laboratorio_analisis.laboratorio_id
        and l.paciente_id = auth.uid()
    )
  );

drop policy if exists recomendaciones_propias on recomendaciones;
create policy recomendaciones_propias on recomendaciones
  for select to authenticated using (paciente_id = auth.uid());

drop policy if exists prescripciones_propias on prescripciones;
create policy prescripciones_propias on prescripciones
  for select to authenticated using (paciente_id = auth.uid());

-- El catálogo es el mismo para todos, como el libro.
drop policy if exists suplemento_categorias_lectura on suplemento_categorias;
create policy suplemento_categorias_lectura on suplemento_categorias
  for select to authenticated using (true);

drop policy if exists suplemento_marcas_lectura on suplemento_marcas;
create policy suplemento_marcas_lectura on suplemento_marcas
  for select to authenticated using (true);

drop policy if exists videos_lectura on videos;
create policy videos_lectura on videos
  for select to authenticated using (publicado);
