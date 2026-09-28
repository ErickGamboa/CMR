import { clienteServidor, usuarioActual } from "@/lib/supabase/servidor";

export type Doctor = { userId: string; nombre: string; correo: string };

/**
 * El doctor de la sesión, o `null` si quien entró no lo es.
 *
 * Tener cuenta no es ser doctor: los pacientes usan el mismo Supabase Auth que
 * el sitio, así que cualquiera de ellos podría llegar hasta acá con una sesión
 * válida. Lo que separa a uno de otro es una fila en `doctores`.
 *
 * No hace falta comparar nada a mano: la política de RLS de esa tabla solo
 * deja leerla a quien ya es doctor, así que a un paciente la consulta le sale
 * vacía. Si esta función devuelve algo, la base ya lo autorizó.
 */
export async function doctorActual(): Promise<Doctor | null> {
  const usuario = await usuarioActual();
  if (!usuario) return null;

  const supabase = await clienteServidor();
  const { data } = await supabase
    .from("doctores")
    .select("user_id, nombre")
    .eq("user_id", usuario.id)
    .maybeSingle();

  if (!data) return null;

  return {
    userId: data.user_id as string,
    nombre: data.nombre as string,
    correo: usuario.email ?? "",
  };
}

/**
 * Quiénes administran la clínica, para poder sacarlos de la lista de
 * pacientes.
 *
 * El disparador que arma la ficha corre con cada cuenta que se crea, sin saber
 * todavía si esa persona va a terminar siendo doctor. Así que un doctor tiene
 * fila en `pacientes` igual que cualquiera, y sin esto aparecería en la lista
 * de trabajo, con su botón de aprobar y su botón de borrar.
 *
 * Se filtra al leer y no borrando la fila al dar de alta al doctor porque así
 * da igual cómo llegó a serlo: el permiso se otorga a mano en el SQL Editor y
 * no hay forma de encadenarle una limpieza.
 */
export async function idsDeDoctores(): Promise<Set<string>> {
  const supabase = await clienteServidor();
  const { data } = await supabase.from("doctores").select("user_id");

  return new Set((data ?? []).map((d) => d.user_id as string));
}
