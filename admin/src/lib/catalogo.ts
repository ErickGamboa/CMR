import "server-only";

import {
  COLUMNAS_CATALOGO,
  leerPlantilla,
  type FilaCatalogo,
  type Plantilla,
  type TipoIndicacion,
} from "@/lib/indicaciones";
import { clienteServidor } from "@/lib/supabase/servidor";

/**
 * Las plantillas que el doctor puede escoger, en el orden de su lista.
 *
 * Solo del servidor: el catálogo entero llega renderizado en la página, y lo
 * que el navegador manda de vuelta es un id, nunca una frase.
 */
export async function cargarPlantillas(
  tipos: TipoIndicacion[],
): Promise<Plantilla[]> {
  const supabase = await clienteServidor();

  const { data } = await supabase
    .from("catalogo_indicaciones")
    .select(COLUMNAS_CATALOGO)
    .in("tipo", tipos)
    .eq("activo", true)
    .order("orden", { ascending: true });

  return ((data ?? []) as unknown as FilaCatalogo[]).map(leerPlantilla);
}

/** Una sola, para rearmar la frase del lado del servidor al guardar. */
export async function cargarPlantilla(id: string): Promise<Plantilla | null> {
  const supabase = await clienteServidor();

  const { data } = await supabase
    .from("catalogo_indicaciones")
    .select(COLUMNAS_CATALOGO)
    .eq("id", id)
    .maybeSingle();

  return data ? leerPlantilla(data as unknown as FilaCatalogo) : null;
}
