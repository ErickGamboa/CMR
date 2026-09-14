-- Dar de alta al doctor, y registrar a los pacientes que ya tienen cuenta.
--
-- Esto se corre UNA VEZ en el SQL Editor de Supabase, después de aplicar la
-- migración 20260914100000_doctor_y_pacientes.sql. Es el arranque del sitio
-- admin: sin una fila en `doctores`, el sitio no deja escribir nada.

-- ---------------------------------------------------------------------------
-- 1. El doctor
-- ---------------------------------------------------------------------------
--
-- La cuenta tiene que existir antes en Supabase Auth (Authentication → Users →
-- Add user). Después, esta fila es la que le da permiso de administrar.
--
-- Ser doctor es poder leer y escribir el expediente de TODOS los pacientes.
-- Esta tabla se mantiene corta y a mano a propósito: no hay pantalla para
-- agregar doctores, justamente para que nadie se agregue solo.

insert into doctores (user_id, nombre)
select id, 'Dr. Nombre Apellido'
  from auth.users
 where email = 'doctor@ejemplo.com'
    on conflict (user_id) do update set nombre = excluded.nombre;

-- Comprobar que quedó:
-- select d.nombre, u.email from doctores d join auth.users u on u.id = d.user_id;

-- ---------------------------------------------------------------------------
-- 2. Los pacientes que ya tienen cuenta
-- ---------------------------------------------------------------------------
--
-- Todo el que ya entra a la app está en `auth.users` pero no tiene ficha, así
-- que el sitio no lo vería. Esto les crea una con el correo como nombre
-- provisional; el doctor lo corrige desde el sitio.
--
-- Excluye a los doctores para que no se listen como pacientes de sí mismos.

insert into pacientes (user_id, nombre_completo)
select u.id, u.email
  from auth.users u
 where not exists (select 1 from doctores d where d.user_id = u.id)
    on conflict (user_id) do nothing;

-- Ver cómo quedó la lista:
-- select p.nombre_completo, p.cedula, u.email, p.activo
--   from pacientes p join auth.users u on u.id = p.user_id
--  order by p.nombre_completo;

-- Corregir uno a mano mientras el sitio no exista:
-- update pacientes
--    set nombre_completo = 'Nombre Real', cedula = '1-2345-6789'
--  where user_id = (select id from auth.users where email = 'paciente@ejemplo.com');

-- ---------------------------------------------------------------------------
-- 3. Comprobar que las políticas quedaron bien
-- ---------------------------------------------------------------------------
--
-- Esto se corre DESDE EL SQL EDITOR, que usa un rol administrador, así que
-- `es_doctor()` devuelve false ahí (no hay sesión de usuario). Sirve para ver
-- que la función existe y que las políticas están creadas, no para probar los
-- permisos: eso se prueba entrando al sitio con la cuenta del doctor.

-- select es_doctor();  -- false acá: el SQL Editor no tiene sesión de usuario

-- Las políticas de escritura del doctor, tabla por tabla:
-- select tablename, policyname, cmd
--   from pg_policies
--  where schemaname = 'public' and policyname like '%_doctor'
--  order by tablename;
