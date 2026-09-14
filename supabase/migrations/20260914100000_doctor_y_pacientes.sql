-- ---------------------------------------------------------------------------
-- El doctor: quién es, y qué puede escribir
-- ---------------------------------------------------------------------------
--
-- Hasta acá la base solo sabía de pacientes: todas las políticas eran
-- `select` contra `auth.uid()`, y no había forma de que nadie escribiera nada.
-- Los datos se cargaban a mano desde el SQL Editor.
--
-- Esta migración es la base del sitio admin. La decisión de fondo: el sitio
-- entra con la sesión del doctor, como la app entra con la del paciente, y es
-- la base la que decide qué puede hacer. NO se usa la llave `service_role`.
--
-- Eso importa porque `service_role` se salta RLS por completo: con ella, un
-- descuido en el sitio puede tocar el expediente de cualquiera. Con políticas,
-- la regla vive pegada al dato y aplica venga de donde venga —el sitio, un
-- script, lo que sea—, y la llave peligrosa no tiene por qué existir en el
-- despliegue.
--
-- (La única cosa que sí va a necesitar `service_role` es crear cuentas en
-- Supabase Auth, porque eso es la Admin API. Eso no está acá: por ahora las
-- cuentas se crean desde el panel de Supabase.)

-- ---------------------------------------------------------------------------
-- Quién es doctor
-- ---------------------------------------------------------------------------

create table if not exists doctores (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  nombre     text not null,
  creado_en  timestamptz not null default now()
);

comment on table doctores is
  'Quién puede administrar pacientes. Se da de alta a mano.';

-- `security definer` a propósito: la función lee `doctores` saltándose RLS.
--
-- Sin eso habría que darle a cada paciente permiso de lectura sobre la tabla
-- de doctores para que su propia política pudiera evaluarse, y una política
-- sobre `doctores` que llamara a esta función se llamaría a sí misma sin
-- parar. `stable` porque dentro de una misma consulta la respuesta no cambia,
-- así Postgres la evalúa una vez y no una por fila.
create or replace function es_doctor()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from doctores d where d.user_id = auth.uid());
$$;

comment on function es_doctor() is
  'True si la sesión actual es de un doctor. Se usa en las políticas de RLS.';

-- ---------------------------------------------------------------------------
-- Los pacientes
-- ---------------------------------------------------------------------------
--
-- `auth.users` no se puede consultar desde el cliente, así que el sitio no
-- tendría cómo listar a nadie. Esta tabla es la que el doctor ve, y además es
-- donde por fin viven el nombre y la cédula.
--
-- La app no la usa todavía: hoy el paciente no ve su propio nombre en ningún
-- lado. Se puede conectar después sin tocar el esquema.

create table if not exists pacientes (
  user_id           uuid primary key references auth.users(id) on delete cascade,

  nombre_completo   text not null,

  -- Única, pero opcional: un paciente extranjero puede no tenerla, y hay
  -- expedientes que se abren antes de pedirle el documento.
  cedula            text unique,

  telefono          text,
  fecha_nacimiento  date,

  -- Dar de baja sin borrar: el expediente se conserva y deja de aparecer en
  -- la lista de trabajo del doctor.
  activo            boolean not null default true,

  creado_en         timestamptz not null default now(),
  actualizado_en    timestamptz not null default now()
);

create index if not exists pacientes_activos_idx
  on pacientes (nombre_completo) where activo;

comment on table pacientes is
  'Ficha del paciente para el sitio admin. La app todavía no la lee.';

-- La de `mapeo_registros` hace lo mismo, pero se llama
-- `mapeo_marcar_actualizado` y colgar de ella una tabla que no es del mapeo se
-- leería raro. Esta es la genérica; la del mapeo se queda donde está.
create or replace function marcar_actualizado()
returns trigger
language plpgsql
as $$
begin
  new.actualizado_en = now();
  return new;
end;
$$;

drop trigger if exists pacientes_actualizado on pacientes;
create trigger pacientes_actualizado
  before update on pacientes
  for each row execute function marcar_actualizado();

-- ---------------------------------------------------------------------------
-- Catálogo de íconos
-- ---------------------------------------------------------------------------
--
-- Un ícono es un glifo de una fuente compilada dentro de la app, así que el
-- doctor no puede inventar nombres: tiene que elegir de una lista cerrada.
-- Esa lista vive en `lib/core/iconos.dart`, y esta tabla es su espejo para
-- que el sitio arme el desplegable sin copiarla a mano.
--
-- Si se agrega un ícono, van los dos lados: primero el `IconData` en Dart,
-- después la fila acá. Al revés, el sitio ofrecería un ícono que la app no
-- sabe dibujar (y que caería en el genérico).

create table if not exists iconos (
  nombre    text primary key,
  etiqueta  text not null,
  grupo     text not null check (grupo in ('recomendacion', 'suplemento')),
  orden     smallint not null default 0
);

insert into iconos (nombre, etiqueta, grupo, orden) values
  ('consejo',        'Consejo general',   'recomendacion',  1),
  ('agua',           'Agua / hidratación','recomendacion',  2),
  ('ejercicio',      'Ejercicio',         'recomendacion',  3),
  ('sueno',          'Sueño',             'recomendacion',  4),
  ('alimentacion',   'Alimentación',      'recomendacion',  5),
  ('proteina',       'Proteína',          'recomendacion',  6),
  ('peso',           'Peso',              'recomendacion',  7),
  ('corazon',        'Corazón',           'recomendacion',  8),
  ('ayuno',          'Ayuno / horario',   'recomendacion',  9),
  ('sol',            'Sol / vitamina D',  'recomendacion', 10),
  ('suplemento',     'Suplemento',        'suplemento',     1),
  ('proteina_polvo', 'Proteína en polvo', 'suplemento',     2),
  ('creatina',       'Creatina',          'suplemento',     3),
  ('omega',          'Omega 3',           'suplemento',     4),
  ('vitamina',       'Vitamina',          'suplemento',     5),
  ('magnesio',       'Magnesio',          'suplemento',     6),
  ('fibra',          'Fibra',             'suplemento',     7),
  ('probiotico',     'Probiótico',        'suplemento',     8)
on conflict (nombre) do update
  set etiqueta = excluded.etiqueta,
      grupo    = excluded.grupo,
      orden    = excluded.orden;

-- ---------------------------------------------------------------------------
-- RLS de las tablas nuevas
-- ---------------------------------------------------------------------------

alter table doctores  enable row level security;
alter table pacientes enable row level security;
alter table iconos    enable row level security;

-- Un doctor ve la lista de doctores. El paciente no tiene nada que hacer acá.
drop policy if exists doctores_lectura on doctores;
create policy doctores_lectura on doctores
  for select to authenticated using (es_doctor());

-- El paciente ve su propia ficha; el doctor las administra todas.
drop policy if exists pacientes_propia on pacientes;
create policy pacientes_propia on pacientes
  for select to authenticated using (user_id = auth.uid());

drop policy if exists pacientes_doctor on pacientes;
create policy pacientes_doctor on pacientes
  for all to authenticated
  using (es_doctor()) with check (es_doctor());

-- El catálogo de íconos lo lee cualquiera con sesión; cambiarlo implica tocar
-- la app, así que no se administra desde el sitio.
drop policy if exists iconos_lectura on iconos;
create policy iconos_lectura on iconos
  for select to authenticated using (true);

-- ---------------------------------------------------------------------------
-- Qué puede escribir el doctor
-- ---------------------------------------------------------------------------
--
-- Van explícitas tabla por tabla, y no en un bucle, a propósito: esto define
-- quién toca expedientes médicos y tiene que poder leerse de corrido y
-- buscarse por nombre de tabla.
--
-- Las políticas de paciente que ya existen NO se tocan: en Postgres varias
-- políticas permisivas sobre la misma tabla se suman con OR, así que el
-- paciente sigue viendo lo suyo y el doctor pasa por la suya.

drop policy if exists citas_doctor on citas;
create policy citas_doctor on citas
  for all to authenticated using (es_doctor()) with check (es_doctor());

drop policy if exists mediciones_doctor on mediciones;
create policy mediciones_doctor on mediciones
  for all to authenticated using (es_doctor()) with check (es_doctor());

drop policy if exists laboratorios_doctor on laboratorios;
create policy laboratorios_doctor on laboratorios
  for all to authenticated using (es_doctor()) with check (es_doctor());

drop policy if exists laboratorio_analisis_doctor on laboratorio_analisis;
create policy laboratorio_analisis_doctor on laboratorio_analisis
  for all to authenticated using (es_doctor()) with check (es_doctor());

drop policy if exists recomendaciones_doctor on recomendaciones;
create policy recomendaciones_doctor on recomendaciones
  for all to authenticated using (es_doctor()) with check (es_doctor());

drop policy if exists prescripciones_doctor on prescripciones;
create policy prescripciones_doctor on prescripciones
  for all to authenticated using (es_doctor()) with check (es_doctor());

-- Qué módulos opcionales ve cada paciente.
drop policy if exists pacientes_modulos_doctor on pacientes_modulos;
create policy pacientes_modulos_doctor on pacientes_modulos
  for all to authenticated using (es_doctor()) with check (es_doctor());

-- El plan de alimentación.
drop policy if exists planes_doctor on planes_alimentacion;
create policy planes_doctor on planes_alimentacion
  for all to authenticated using (es_doctor()) with check (es_doctor());

drop policy if exists plan_totales_doctor on plan_totales;
create policy plan_totales_doctor on plan_totales
  for all to authenticated using (es_doctor()) with check (es_doctor());

drop policy if exists plan_distribucion_doctor on plan_distribucion;
create policy plan_distribucion_doctor on plan_distribucion
  for all to authenticated using (es_doctor()) with check (es_doctor());

-- El mapeo lo escribe el paciente: son sus mediciones de la casa. El doctor
-- las lee, que es para lo que existe el módulo, pero no las corrige.
drop policy if exists mapeo_registros_doctor on mapeo_registros;
create policy mapeo_registros_doctor on mapeo_registros
  for select to authenticated using (es_doctor());

-- Catálogo público: lo mantiene el doctor desde el sitio.
drop policy if exists libro_secciones_doctor on libro_secciones;
create policy libro_secciones_doctor on libro_secciones
  for all to authenticated using (es_doctor()) with check (es_doctor());

drop policy if exists libro_alimentos_doctor on libro_alimentos;
create policy libro_alimentos_doctor on libro_alimentos
  for all to authenticated using (es_doctor()) with check (es_doctor());

drop policy if exists suplemento_categorias_doctor on suplemento_categorias;
create policy suplemento_categorias_doctor on suplemento_categorias
  for all to authenticated using (es_doctor()) with check (es_doctor());

drop policy if exists suplemento_marcas_doctor on suplemento_marcas;
create policy suplemento_marcas_doctor on suplemento_marcas
  for all to authenticated using (es_doctor()) with check (es_doctor());

drop policy if exists videos_doctor on videos;
create policy videos_doctor on videos
  for all to authenticated using (es_doctor()) with check (es_doctor());

-- Ojo: `libro_alimentos` tenía una política de lectura que solo muestra lo
-- 'publicado'. El doctor necesita ver también lo que está en 'por_revisar'
-- para poder confirmarlo, y la suya se lo permite porque las políticas se
-- suman con OR.
