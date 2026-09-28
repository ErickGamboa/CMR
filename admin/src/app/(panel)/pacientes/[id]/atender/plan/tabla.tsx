"use client";

import { useActionState, useState } from "react";
import { useFormStatus } from "react-dom";

import { Campo } from "@/components/campo";
import { LimpiarTodo } from "@/components/limpiar-todo";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import {
  GRUPOS,
  TIEMPOS,
  campoCelda,
  escribirCelda,
  leerCelda,
  sumarFila,
  type Grupo,
  type Tiempo,
} from "@/lib/plan";

import { guardarPlan, type Resultado } from "./acciones";

const SIN_ENVIAR: Resultado = { error: null, guardado: false };

export type PlanCargado = {
  vigenteDesde: string;
  notas: string;
  celdas: Record<string, string>;
};

const llave = (g: Grupo, t: Tiempo) => `${g}.${t}`;

/**
 * La tabla del plan, igual a la del papel.
 *
 * Seis grupos por cinco tiempos de comida. Se llena solo donde el paciente
 * come algo de ese grupo: lo que queda en blanco es el guion de la tabla
 * impresa. El total del día no se escribe, se suma.
 */
export function TablaPlan({
  paciente,
  plan,
  cuantos,
  onLimpiar,
}: {
  paciente: string;
  plan: PlanCargado;
  /** 1 si el paciente ya tiene plan, 0 si no. */
  cuantos: number;
  onLimpiar: () => Promise<{ error: string | null }>;
}) {
  const [estado, enviar] = useActionState(guardarPlan, SIN_ENVIAR);

  // Los tres campos van controlados. Las celdas, para poder sumar mientras el
  // doctor escribe; la fecha y las notas, porque con `defaultValue` Base UI
  // avisa —y con razón— cuando el valor de partida cambia después de montado:
  // al limpiar el plan, la fecha vuelve a hoy y las notas a vacío, y un campo
  // no controlado se quedaría mostrando lo del plan que ya no existe.
  //
  // Se resincronizan cuando el servidor manda datos distintos, comparando el
  // contenido y no la identidad del objeto, que cambia en cada render.
  const firma = JSON.stringify(plan);
  const [ultimaFirma, setUltimaFirma] = useState(firma);
  const [celdas, setCeldas] = useState(plan.celdas);
  const [vigenteDesde, setVigenteDesde] = useState(plan.vigenteDesde);
  const [notas, setNotas] = useState(plan.notas);

  if (firma !== ultimaFirma) {
    setUltimaFirma(firma);
    setCeldas(plan.celdas);
    setVigenteDesde(plan.vigenteDesde);
    setNotas(plan.notas);
  }

  return (
    <form action={enviar} className="space-y-6">
      <input type="hidden" name="paciente" value={paciente} />

      {/* En pantalla angosta la tabla no cabe: se desliza a lo ancho en vez de
          apretar las columnas hasta que no se pueda escribir en ellas. */}
      <div className="-mx-1 overflow-x-auto px-1 pb-1">
        <table className="w-full min-w-[46rem] border-separate border-spacing-0">
          <thead>
            <tr>
              <th
                scope="col"
                className="sticky left-0 z-10 rounded-tl-lg border-y border-l bg-muted/50 px-4 py-3 text-left text-sm font-medium"
              >
                Grupo
              </th>
              {TIEMPOS.map((t) => (
                <th
                  key={t.valor}
                  scope="col"
                  className="border-y bg-muted/50 px-3 py-3 text-center text-sm font-medium"
                >
                  <span className="block">{t.corto}</span>
                  {t.corto !== t.titulo && (
                    <span className="block text-xs font-normal text-muted-foreground">
                      {t.valor === "merienda_manana" ? "mañana" : "tarde"}
                    </span>
                  )}
                </th>
              ))}
              <th
                scope="col"
                className="rounded-tr-lg border-y border-r bg-muted/50 px-3 py-3 text-center text-sm font-medium"
              >
                <span className="block">Total</span>
                <span className="block text-xs font-normal text-muted-foreground">
                  del día
                </span>
              </th>
            </tr>
          </thead>

          <tbody>
            {GRUPOS.map((g, fila) => {
              const ultima = fila === GRUPOS.length - 1;
              const total = sumarFila(
                TIEMPOS.map((t) =>
                  leerCelda(celdas[llave(g.valor, t.valor)] ?? ""),
                ),
              );

              return (
                <tr key={g.valor}>
                  <th
                    scope="row"
                    className={`sticky left-0 z-10 border-b border-l bg-background px-4 py-2 text-left text-sm font-medium ${
                      ultima ? "rounded-bl-lg" : ""
                    }`}
                  >
                    {g.titulo}
                  </th>

                  {TIEMPOS.map((t) => (
                    <td key={t.valor} className="border-b px-2 py-2">
                      <input
                        type="text"
                        name={campoCelda(g.valor, t.valor)}
                        aria-label={`${g.titulo} en ${t.titulo}`}
                        value={celdas[llave(g.valor, t.valor)] ?? ""}
                        onChange={(e) =>
                          setCeldas((previas) => ({
                            ...previas,
                            [llave(g.valor, t.valor)]: e.target.value,
                          }))
                        }
                        inputMode="decimal"
                        autoComplete="off"
                        placeholder="–"
                        className="h-9 w-full rounded-md border border-transparent bg-transparent text-center tabular-nums outline-none transition-colors placeholder:text-muted-foreground/40 hover:border-input focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50"
                      />
                    </td>
                  ))}

                  <td
                    className={`border-b border-r bg-secondary/40 px-3 py-2 text-center ${
                      ultima ? "rounded-br-lg" : ""
                    }`}
                  >
                    <span
                      aria-label={`Total de ${g.titulo} en el día`}
                      className={`text-sm font-semibold tabular-nums transition-colors ${
                        total ? "" : "text-muted-foreground/40"
                      }`}
                    >
                      {total ? escribirCelda(total) : "–"}
                    </span>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <p className="max-w-prose text-sm leading-relaxed text-muted-foreground">
        Llená solo lo que el paciente come de cada grupo. Lo que dejés en blanco
        es el guion de la tabla: ese grupo no va en ese tiempo. Para un mínimo,
        escribí el número con un más — <strong>2+</strong> son dos o más, como
        en el papel. <strong>El total del día se suma solo</strong>, y queda
        como mínimo si alguna casilla de la fila lo es.
      </p>

      <div className="grid gap-4 sm:grid-cols-2">
        <Campo
          id="vigente_desde"
          etiqueta="Vigente desde"
          tipo="date"
          value={vigenteDesde}
          onChange={(e) => setVigenteDesde(e.target.value)}
        />
      </div>

      <div className="space-y-2">
        <Label htmlFor="notas">Notas</Label>
        <textarea
          id="notas"
          name="notas"
          rows={3}
          value={notas}
          onChange={(e) => setNotas(e.target.value)}
          placeholder="Aclaraciones que el paciente ve junto a la tabla."
          className="flex w-full rounded-md border border-input bg-transparent px-3 py-2 text-base shadow-xs transition-[color,box-shadow] outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 md:text-sm"
        />
      </div>

      {estado.error && (
        <Alert variant="destructive" className="animate-in fade-in">
          <AlertDescription>{estado.error}</AlertDescription>
        </Alert>
      )}
      {estado.guardado && !estado.error && (
        <p
          role="status"
          className="animate-in fade-in text-sm text-muted-foreground"
        >
          Plan guardado.
        </p>
      )}

      <div className="flex flex-wrap items-center gap-3">
        <Guardar />
        <LimpiarTodo
          que="el plan"
          cuantos={cuantos}
          advertencia="Se va la tabla entera con las notas y la fecha de vigencia, y el paciente queda sin plan."
          onLimpiar={onLimpiar}
        />
      </div>
    </form>
  );
}

function Guardar() {
  const { pending } = useFormStatus();

  return (
    <Button type="submit" disabled={pending}>
      {pending ? "Guardando…" : "Guardar plan"}
    </Button>
  );
}
