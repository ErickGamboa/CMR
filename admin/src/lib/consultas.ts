import "server-only";

import { revalidatePath } from "next/cache";

import type { ClavePaso } from "@/lib/pasos";
import { clienteServidor } from "@/lib/supabase/servidor";

/** Pasadas estas horas, una consulta que nadie cerró se da por terminada. */
const HORAS_VIVA = 12;

/**
 * Qué pasos se tocaron en la consulta que está abierta ahora.
 *
 * Solo lectura: la página no abre ni cierra nada al dibujarse. Si la consulta
 * abierta ya está vieja se devuelve vacío, y quien la cierra de verdad es la
 * primera acción que escriba algo.
 */
export async function pasosDeLaConsulta(
  paciente: string,
): Promise<Set<ClavePaso>> {
  const supabase = await clienteServidor();

  const { data } = await supabase
    .from("consultas")
    .select("abierta_en, pasos")
    .eq("paciente_id", paciente)
    .is("cerrada_en", null)
    .maybeSingle();

  if (!data) return new Set();

  const abierta = new Date(data.abierta_en as string).getTime();
  if (Date.now() - abierta > HORAS_VIVA * 3600_000) return new Set();

  return new Set((data.pasos ?? []) as ClavePaso[]);
}

/**
 * Deja constancia de que el doctor dio este paso por hecho.
 *
 * La llama una sola cosa: el botón "Siguiente" del paso. Guardar no palomea
 * —el doctor puede corregir un dato y seguir trabajando ahí— y saltar de paso
 * tocando un número del indicador tampoco. El visto dice lo que el doctor dijo,
 * no lo que la base alcanzó a deducir.
 *
 * Si falla no se avisa: el dato del paciente ya quedó bien y lo único que se
 * pierde es un palomeo.
 */
export async function marcarPaso(paciente: string, paso: ClavePaso) {
  const supabase = await clienteServidor();
  await supabase.rpc("marcar_paso", { p_paciente: paciente, p_paso: paso });
  invalidarIndicador(paciente);
}

export async function cerrarConsulta(paciente: string) {
  const supabase = await clienteServidor();
  await supabase.rpc("cerrar_consulta", { p_paciente: paciente });
  invalidarIndicador(paciente);
}

/**
 * Obliga a volver a dibujar el indicador de pasos.
 *
 * El `"layout"` del segundo argumento es lo importante. Un layout existe
 * justamente para no redibujarse al moverse entre las rutas que envuelve: al
 * pasar de mediciones a alimentación, Next reusa el que ya tenía, y con él el
 * indicador con los palomeos de antes. El visto solo aparecía recargando la
 * página a mano.
 *
 * Marcarlo por ruta y no por etiqueta porque es de un paciente: invalidar el
 * indicador de uno no tiene por qué botar el de los demás.
 */
function invalidarIndicador(paciente: string) {
  revalidatePath(`/pacientes/${paciente}/atender`, "layout");
}
