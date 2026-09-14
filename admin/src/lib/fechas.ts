const MESES = [
  "enero",
  "febrero",
  "marzo",
  "abril",
  "mayo",
  "junio",
  "julio",
  "agosto",
  "setiembre",
  "octubre",
  "noviembre",
  "diciembre",
];

const DIAS = [
  "domingo",
  "lunes",
  "martes",
  "miércoles",
  "jueves",
  "viernes",
  "sábado",
];

/**
 * Parte una fecha de Postgres sin pasar por `new Date(texto)`.
 *
 * `new Date("2026-09-14")` la interpreta como UTC y en Costa Rica muestra el
 * día anterior. Partiendo el texto a mano, el día es el que dice la base.
 */
function partes(fecha: string) {
  const [f] = fecha.split("T");
  const [a, m, d] = f.split("-").map(Number);
  return { a, m, d };
}

/** Ej.: "8 de agosto, 2026". */
export function formatearFechaCorta(fecha: string) {
  const { a, m, d } = partes(fecha);
  return `${d} de ${MESES[m - 1]}, ${a}`;
}

/** Ej.: "viernes 18 de setiembre · 10:30 a.m.". */
export function formatearFechaHora(fecha: string) {
  const [f, hora = "00:00"] = fecha.split("T");
  const { a, m, d } = partes(f);

  // El día de la semana sí necesita el calendario; se arma a mediodía para que
  // ningún corrimiento de zona lo mueva de día.
  const diaSemana = DIAS[new Date(a, m - 1, d, 12).getDay()];

  const [hh, mm] = hora.slice(0, 5).split(":").map(Number);
  const h12 = hh % 12 === 0 ? 12 : hh % 12;
  const periodo = hh < 12 ? "a.m." : "p.m.";

  return `${diaSemana} ${d} de ${MESES[m - 1]} · ${h12}:${String(mm).padStart(2, "0")} ${periodo}`;
}
