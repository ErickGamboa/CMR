/**
 * Listas fijas que comparten el servidor y el navegador.
 *
 * Viven acá, en un archivo sin `"use client"` ni `"use server"`, porque un
 * componente de servidor **no puede importar datos de un módulo de cliente**:
 * de un archivo `"use client"` solo recibe componentes, y una constante le
 * llega como una referencia vacía. El síntoma es un `TIPOS.map is not a
 * function` en tiempo de ejecución, que no aparece ni en `tsc` ni en el build.
 *
 * Regla corta: si el servidor y el cliente necesitan el mismo dato, el dato no
 * puede vivir en el archivo del formulario.
 */

/** Las tres clases de prescripción, y en qué módulo de la app sale cada una. */
export const TIPOS_PRESCRIPCION = [
  { valor: "suplemento", titulo: "Suplemento", donde: "Mi plan" },
  { valor: "peptido", titulo: "Péptido", donde: "Péptidos" },
  { valor: "medicamento", titulo: "Medicamento", donde: "Medicamentos" },
] as const;

export const TIPOS_CITA = [
  { valor: "medica", titulo: "Cita médica" },
  { valor: "enfermeria", titulo: "Cita enfermería" },
] as const;

/** El lugar que se propone al agendar. */
export const LUGAR_POR_DEFECTO = "Clínica COSME - CMR";
