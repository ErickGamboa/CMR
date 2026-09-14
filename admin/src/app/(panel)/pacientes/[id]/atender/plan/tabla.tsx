"use client";

import { useActionState, useState } from "react";
import { useFormStatus } from "react-dom";

import { Campo } from "@/components/campo";
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
}: {
  paciente: string;
  plan: PlanCargado;
}) {
  const [estado, enviar] = useActionState(guardarPlan, SIN_ENVIAR);

  // Controladas para poder sumar mientras el doctor escribe. Se resincronizan
  // cuando el servidor manda datos distintos —al guardar—, comparando el
  // contenido y no la identidad del objeto, que cambia en cada render.
  const [celdas, setCeldas] = useState(plan.celdas);
  const firma = JSON.stringify(plan.celdas);
  const [ultimaFirma, setUltimaFirma] = useState(firma);

  if (firma !== ultimaFirma) {
    setUltimaFirma(firma);
    setCeldas(plan.celdas);
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
          defaultValue={plan.vigenteDesde}
        />
      </div>

      <div className="space-y-2">
        <Label htmlFor="notas">Notas</Label>
        <textarea
          id="notas"
          name="notas"
          rows={3}
          defaultValue={plan.notas}
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

      <Guardar />
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
