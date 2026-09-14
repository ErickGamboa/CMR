/**
 * Los pasos de una consulta, en el orden en que pasa de verdad.
 *
 * Salen del inventario de todo lo que el doctor le carga a un paciente: si
 * algo se llena desde el sitio y es de un paciente, tiene que estar acá. Lo
 * que NO está es a propósito:
 *
 *   - Los datos personales (nombre, cédula, teléfono) viven en la ficha: se
 *     corrigen una vez, no en cada consulta.
 *   - El libro de intercambios, las marcas de suplementos y los videos son
 *     catálogo público, iguales para todos: no son parte de atender a nadie.
 */
export type ClavePaso =
  | "mediciones"
  | "laboratorios"
  | "plan"
  | "prescripciones"
  | "recomendaciones"
  | "mapeo"
  | "citas";

export type Paso = {
  clave: ClavePaso;
  titulo: string;
  /** Qué se hace en este paso, en una línea. */
  detalle: string;
  /** De dónde sale el número que se muestra en el indicador. */
  tabla: string;
  /** Todavía no tiene pantalla propia. */
  pendiente?: boolean;
};

// El orden es el de la consulta real, no el del esquema: primero se mide, con
// eso se ajusta la alimentación, de ahí salen las indicaciones escritas y por
// último lo que va a tomar. Laboratorios, mapeo y la próxima cita van después
// porque no siempre se tocan.
export const PASOS: Paso[] = [
  {
    clave: "mediciones",
    titulo: "Mediciones",
    detalle: "Peso y composición corporal de hoy.",
    tabla: "mediciones",
  },
  {
    clave: "plan",
    titulo: "Alimentación",
    detalle: "Intercambios por tiempo de comida.",
    tabla: "planes_alimentacion",
  },
  {
    clave: "recomendaciones",
    titulo: "Recomendaciones",
    detalle: "Indicaciones escritas que ve en la app.",
    tabla: "recomendaciones",
  },
  {
    clave: "prescripciones",
    titulo: "Suplementación y medicamentos",
    detalle: "Lo que toma, con dosis y frecuencia.",
    tabla: "prescripciones",
  },
  {
    clave: "laboratorios",
    titulo: "Laboratorios",
    detalle: "Exámenes con sus valores y referencias.",
    tabla: "laboratorios",
    pendiente: true,
  },
  {
    clave: "mapeo",
    titulo: "Mapeo",
    detalle: "Presión y glisemia que anota el paciente.",
    tabla: "mapeo_registros",
  },
  {
    clave: "citas",
    titulo: "Próxima cita",
    detalle: "Cuándo vuelve.",
    tabla: "citas",
  },
];

export const PRIMER_PASO = PASOS[0].clave;

export function buscarPaso(clave: string) {
  const i = PASOS.findIndex((p) => p.clave === clave);
  if (i === -1) return null;

  return {
    paso: PASOS[i],
    numero: i + 1,
    anterior: i > 0 ? PASOS[i - 1] : null,
    siguiente: i < PASOS.length - 1 ? PASOS[i + 1] : null,
  };
}
