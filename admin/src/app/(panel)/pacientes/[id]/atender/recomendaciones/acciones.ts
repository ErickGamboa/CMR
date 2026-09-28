"use server";

import { revalidatePath } from "next/cache";

import { cargarPlantilla } from "@/lib/catalogo";
import {
  armarRecomendacion,
  faltantes,
  type DatosAgregar,
} from "@/lib/indicaciones";
import { clienteServidor } from "@/lib/supabase/servidor";

// Un archivo "use server" solo puede exportar funciones async. Los tipos sí
// (se borran al compilar); las constantes van en el componente de cliente.
export type Resultado = { error: string | null };

/**
 * Deja una recomendación.
 *
 * La frase se rearma acá con la plantilla que se lee de la base, no con lo
 * que mandó el navegador: del cliente llegan el id y los valores escogidos y
 * nada más. Así lo que ve el paciente no depende de que nadie haya tocado el
 * formulario por el camino.
 */
export async function agregarRecomendacion(
  paciente: string,
  datos: DatosAgregar,
): Promise<Resultado> {
  if (!paciente) return { error: "Falta el paciente." };

  const plantilla = await cargarPlantilla(datos.plantillaId);
  if (!plantilla || plantilla.tipo !== "recomendacion") {
    return { error: "Esa recomendación ya no está en el catálogo." };
  }

  let fila;

  if (plantilla.libre) {
    const titulo = (datos.libre?.titulo ?? "").trim();
    const texto = (datos.libre?.texto ?? "").trim();

    if (!titulo) return { error: "Escribí el título." };
    if (!texto) return { error: "Escribí la recomendación." };

    fila = {
      titulo,
      texto,
      icono: (datos.libre?.icono ?? "").trim() || "consejo",
    };
  } else {
    const faltan = faltantes(plantilla, datos.valores);
    if (faltan.length > 0) {
      return { error: `Falta ${faltan.map((c) => c.etiqueta).join(", ").toLowerCase()}.` };
    }

    fila = armarRecomendacion(plantilla, datos.valores);
  }

  const supabase = await clienteServidor();
  const { error } = await supabase.from("recomendaciones").insert({
    paciente_id: paciente,
    ...fila,
    plantilla_id: plantilla.id,
    valores: plantilla.libre ? null : datos.valores,
  });

  if (error) return { error: "No pudimos guardarla. Intentá de nuevo." };

  revalidatePath(`/pacientes/${paciente}/atender/recomendaciones`);
  return { error: null };
}

export async function borrarRecomendacion(paciente: string, id: string) {
  const supabase = await clienteServidor();
  const { error } = await supabase
    .from("recomendaciones")
    .delete()
    .eq("id", id);

  if (error) return { error: "No pudimos borrarla." };

  revalidatePath(`/pacientes/${paciente}/atender/recomendaciones`);
  return { error: null };
}

/**
 * Vacía todas las recomendaciones del paciente.
 *
 * Para cuando se replantea el tratamiento y la lista vieja no sirve: borrarlas
 * de una en una eran diez confirmaciones.
 */
export async function limpiarRecomendaciones(paciente: string) {
  const supabase = await clienteServidor();
  const { error } = await supabase
    .from("recomendaciones")
    .delete()
    .eq("paciente_id", paciente);

  if (error) return { error: "No pudimos limpiarlas." };

  revalidatePath(`/pacientes/${paciente}/atender/recomendaciones`);
  return { error: null };
}
