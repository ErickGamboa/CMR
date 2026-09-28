-- ---------------------------------------------------------------------------
-- Dar de alta a alguien como doctor
-- ---------------------------------------------------------------------------
--
-- Entrar al sitio no distingue tipos de cuenta: cualquiera con correo y
-- contraseña válidos pasa el login. Lo que decide quién administra la clínica
-- es tener una fila en `doctores`; sin ella, la cuenta se topa con "Este panel
-- es para el equipo de la clínica" y no ve nada más.
--
-- Por eso esto no tiene pantalla y se corre a mano desde el SQL Editor de
-- Supabase: dar permisos de doctor no puede ser un botón que un doctor le
-- pueda apretar a cualquiera.
--
-- La cuenta tiene que existir antes. Se crea desde la app ("Crear una cuenta")
-- o desde el sitio (Pacientes → Nuevo paciente), y después se corre esto.

-- ---------------------------------------------------------------------------
-- 1. Ver quién es doctor hoy
-- ---------------------------------------------------------------------------

select d.nombre, u.email, d.creado_en
  from doctores d
  join auth.users u on u.id = d.user_id
 order by d.creado_en;

-- ---------------------------------------------------------------------------
-- 2. Dar de alta
-- ---------------------------------------------------------------------------
--
-- Cambiá las dos líneas de abajo y corré el bloque entero. El nombre es el
-- que sale en la cabecera del panel y en el menú de la esquina.

insert into doctores (user_id, nombre)
select u.id, 'Dr. Roy Jiménez'                    -- <- el nombre que se muestra
  from auth.users u
 where u.email = 'correo@ejemplo.com'             -- <- el correo de la cuenta
on conflict (user_id) do update
  set nombre = excluded.nombre;

-- Si no devuelve ninguna fila, ese correo no tiene cuenta todavía. Comprobalo:
--
--   select id, email, created_at from auth.users where email = 'correo@ejemplo.com';

-- ---------------------------------------------------------------------------
-- 3. Quitarle el permiso
-- ---------------------------------------------------------------------------
--
-- Solo saca a la persona del panel: la cuenta sigue existiendo y puede entrar
-- a la app como cualquier otra. Para borrar la cuenta entera es otra cosa.

-- delete from doctores
--  where user_id = (select id from auth.users where email = 'correo@ejemplo.com');

-- ---------------------------------------------------------------------------
-- Ojo con el último
-- ---------------------------------------------------------------------------
--
-- Si se le quita el permiso al único doctor, nadie puede volver a entrar al
-- panel y la única forma de arreglarlo es volver acá, al SQL Editor. Antes de
-- correr el `delete`, corré la consulta 1 y contá cuántos quedan.
