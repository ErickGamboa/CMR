-- Libro de intercambios de alimentos y plan de alimentación.
--
-- El libro es un catálogo público (lo mismo para todos los pacientes) que el
-- doctor mantiene desde Supabase. El plan es por paciente y lo asigna Esteban.
--
-- Fuente del catálogo: "Lista de Intercambios de Alimentos" (CMR, Dr. Roy
-- Esteban Jiménez Chaves). Los seis grupos de intercambio son carbohidratos,
-- frutas, proteínas, vegetales, lácteos y grasas; en el libro impreso son las
-- columnas C, F, P, V, L y G.

-- ---------------------------------------------------------------------------
-- Tipos
-- ---------------------------------------------------------------------------

do $$ begin
  create type grupo_intercambio as enum (
    'carbohidratos', 'frutas', 'proteinas', 'vegetales', 'lacteos', 'grasas'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type tiempo_comida as enum (
    'desayuno', 'merienda_manana', 'almuerzo', 'merienda_tarde', 'cena'
  );
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------------
-- Catálogo: secciones del libro
-- ---------------------------------------------------------------------------

create table if not exists libro_secciones (
  id          text primary key,
  nombre      text not null,

  -- 'grupo'        una de las secciones por grupo de intercambio
  -- 'bebidas'      bebidas alcohólicas y no alcohólicas; no son un grupo
  --                propio, gastan carbohidratos, frutas y grasas
  -- 'restaurante'  el menú de una cadena
  -- 'libres'       la lista de alimentos libres
  tipo        text not null
              check (tipo in ('grupo', 'bebidas', 'restaurante', 'libres')),

  -- Grupo al que pertenece la sección, cuando aplica. Sirve para saltar del
  -- plan ("te tocan 2 carbohidratos") a las secciones que los ofrecen.
  grupo       grupo_intercambio,

  -- Aclaración que la app muestra bajo el título de la sección. Ej.: en las
  -- bebidas alcohólicas, que el alcohol se cuenta como grasa.
  nota        text,

  orden       smallint not null,

  unique (orden)
);

comment on table libro_secciones is
  'Secciones del libro de intercambios: grupos, restaurantes y alimentos libres.';

-- ---------------------------------------------------------------------------
-- Catálogo: alimentos
-- ---------------------------------------------------------------------------

create table if not exists libro_alimentos (
  id            text primary key,
  seccion_id    text not null references libro_secciones(id) on delete restrict,

  -- Encabezado dentro de la sección: "Tortillas", "Panes", "Acompañamientos".
  -- Su posición en la pantalla la define el `orden` del primer alimento que
  -- lo usa, así que no necesita tabla aparte.
  subseccion    text,

  nombre        text not null,

  -- Marcas comerciales que el libro menciona para este alimento. Van aparte
  -- del nombre para poder buscar por marca ("Bimbo", "Dos Pinos").
  marcas        text[] not null default '{}',

  -- La medida a la que aplica el conteo: "3 unidades", "½ taza", "30 g".
  porcion       text,

  -- Cuántos intercambios de cada grupo gasta la porción.
  c             numeric(4,2) not null default 0 check (c >= 0),
  f             numeric(4,2) not null default 0 check (f >= 0),
  p             numeric(4,2) not null default 0 check (p >= 0),
  v             numeric(4,2) not null default 0 check (v >= 0),
  l             numeric(4,2) not null default 0 check (l >= 0),
  g             numeric(4,2) not null default 0 check (g >= 0),

  -- Conteo alternativo, para los alimentos que el libro anota con "ó": el
  -- queso fresco cuenta como 1 proteína O como 1 lácteo, a elección. Mismas
  -- llaves que las columnas de arriba, ej. '{"l": 1}'.
  alternativa   jsonb,

  -- El libro marca con "*" las comidas compuestas cuya grasa depende de cómo
  -- se cocinaron. Se muestra como "+ grasa según preparación".
  grasa_variable boolean not null default false,

  -- Alimento libre: no gasta ningún intercambio. Varios traen condición
  -- ("1 cucharada libre al día / 2 cucharadas = ½ carbohidrato"), que va en
  -- `nota` y a veces también en las columnas de conteo.
  libre         boolean not null default false,

  -- Condiciones y aclaraciones: "1 al día", "2 cucharadas libres al día /
  -- 4 cucharaditas = ½ carbohidrato".
  nota          text,

  -- 'publicado'   se muestra en la app
  -- 'por_revisar' no se muestra: el dato del PDF quedó dudoso y falta que el
  --               doctor lo confirme
  estado        text not null default 'publicado'
                check (estado in ('publicado', 'por_revisar')),

  orden         smallint not null,

  -- Un alimento que no es libre, no gasta nada y no aclara nada es un error
  -- de captura.
  constraint libro_alimentos_cuenta_algo check (
    libre
    or estado = 'por_revisar'
    or c + f + p + v + l + g > 0
    or grasa_variable
    or nota is not null
  )
);

create index if not exists libro_alimentos_seccion_orden_idx
  on libro_alimentos (seccion_id, orden);

comment on table libro_alimentos is
  'Alimentos del libro con su equivalencia en intercambios.';

-- ---------------------------------------------------------------------------
-- Favoritos del paciente
-- ---------------------------------------------------------------------------

create table if not exists libro_favoritos (
  paciente_id  uuid not null references auth.users(id) on delete cascade,
  alimento_id  text not null references libro_alimentos(id) on delete cascade,
  creado_en    timestamptz not null default now(),

  primary key (paciente_id, alimento_id)
);

-- ---------------------------------------------------------------------------
-- Plan de alimentación
-- ---------------------------------------------------------------------------

create table if not exists planes_alimentacion (
  id             uuid primary key default gen_random_uuid(),
  paciente_id    uuid not null references auth.users(id) on delete cascade,
  vigente_desde  date not null default current_date,
  activo         boolean not null default true,
  notas          text,
  creado_en      timestamptz not null default now()
);

-- Un solo plan activo por paciente.
create unique index if not exists planes_alimentacion_activo_idx
  on planes_alimentacion (paciente_id) where activo;

-- Total diario por grupo. Se guarda aparte de la suma de los tiempos de
-- comida porque no siempre coincide: en el plan de ejemplo los vegetales
-- dicen "4+" al día y la fila reparte "2+" en tres tiempos.
create table if not exists plan_totales (
  plan_id    uuid not null references planes_alimentacion(id) on delete cascade,
  grupo      grupo_intercambio not null,
  total      numeric(4,2) not null check (total >= 0),

  -- El "+" de "4+": el total es un mínimo, no un techo.
  es_minimo  boolean not null default false,

  primary key (plan_id, grupo)
);

-- Cuánto de cada grupo va en cada tiempo de comida. La ausencia de fila es el
-- "-" de la tabla impresa: ese grupo no va en ese tiempo.
create table if not exists plan_distribucion (
  plan_id    uuid not null references planes_alimentacion(id) on delete cascade,
  grupo      grupo_intercambio not null,
  tiempo     tiempo_comida not null,
  cantidad   numeric(4,2) not null check (cantidad >= 0),
  es_minimo  boolean not null default false,

  primary key (plan_id, grupo, tiempo)
);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table libro_secciones     enable row level security;
alter table libro_alimentos     enable row level security;
alter table libro_favoritos     enable row level security;
alter table planes_alimentacion enable row level security;
alter table plan_totales        enable row level security;
alter table plan_distribucion   enable row level security;

-- El libro es el mismo para todos: cualquier paciente con sesión lo lee
-- completo. Escribirlo es tarea del doctor desde el panel de Supabase, así
-- que la app no tiene permiso de escritura.
drop policy if exists libro_secciones_lectura on libro_secciones;
create policy libro_secciones_lectura on libro_secciones
  for select to authenticated using (true);

drop policy if exists libro_alimentos_lectura on libro_alimentos;
create policy libro_alimentos_lectura on libro_alimentos
  for select to authenticated using (estado = 'publicado');

-- Los favoritos sí los maneja el paciente, y solo los suyos.
drop policy if exists libro_favoritos_propios on libro_favoritos;
create policy libro_favoritos_propios on libro_favoritos
  for all to authenticated
  using (paciente_id = auth.uid())
  with check (paciente_id = auth.uid());

-- El plan lo asigna el doctor; el paciente solo lee el suyo.
drop policy if exists planes_propios on planes_alimentacion;
create policy planes_propios on planes_alimentacion
  for select to authenticated using (paciente_id = auth.uid());

drop policy if exists plan_totales_propios on plan_totales;
create policy plan_totales_propios on plan_totales
  for select to authenticated using (
    exists (
      select 1 from planes_alimentacion p
      where p.id = plan_totales.plan_id and p.paciente_id = auth.uid()
    )
  );

drop policy if exists plan_distribucion_propios on plan_distribucion;
create policy plan_distribucion_propios on plan_distribucion
  for select to authenticated using (
    exists (
      select 1 from planes_alimentacion p
      where p.id = plan_distribucion.plan_id and p.paciente_id = auth.uid()
    )
  );
