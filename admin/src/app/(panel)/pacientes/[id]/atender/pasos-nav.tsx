"use client";

import { Check } from "lucide-react";
import Link from "next/link";
import { useSelectedLayoutSegment } from "next/navigation";

import { PASOS, type ClavePaso } from "@/lib/pasos";
import { cn } from "@/lib/utils";

/**
 * El indicador de pasos de la consulta.
 *
 * En pantalla ancha se ven los siete con su número; en teléfono se vuelve una
 * barra de progreso con "Paso 3 de 7", porque siete títulos no entran sin
 * partirse y una fila con scroll lateral esconde justo lo que el indicador
 * viene a mostrar: dónde estás.
 *
 * El palomeo no significa "terminado" sino "tiene algo cargado". Una consulta
 * no obliga a llenar los siete pasos: a veces solo se pesa al paciente.
 */
export function PasosNav({
  base,
  conteos,
}: {
  base: string;
  conteos: Record<ClavePaso, number>;
}) {
  const segmento = useSelectedLayoutSegment();
  const actual = PASOS.findIndex((p) => p.clave === segmento);
  const indice = actual === -1 ? 0 : actual;

  return (
    <nav aria-label="Pasos de la consulta">
      <ol className="hidden items-center gap-1 lg:flex">
        {PASOS.map((p, i) => {
          const esActual = i === indice;
          const tiene = conteos[p.clave] > 0;

          return (
            <li key={p.clave} className="flex min-w-0 flex-1 items-center">
              <Link
                href={`${base}/${p.clave}`}
                aria-current={esActual ? "step" : undefined}
                className={cn(
                  "group flex min-w-0 flex-1 flex-col gap-1.5 rounded-md px-1 py-2 outline-none transition-colors focus-visible:ring-2 focus-visible:ring-ring",
                )}
              >
                <span
                  className={cn(
                    "h-1 w-full rounded-full transition-colors duration-300",
                    esActual
                      ? "bg-primary"
                      : tiene
                        ? "bg-primary/30"
                        : "bg-border group-hover:bg-primary/20",
                  )}
                />
                <span className="flex items-center gap-1.5">
                  <span
                    className={cn(
                      "flex size-5 shrink-0 items-center justify-center rounded-full text-[11px] font-semibold transition-colors",
                      esActual
                        ? "bg-primary text-primary-foreground"
                        : tiene
                          ? "bg-primary/15 text-primary"
                          : "bg-muted text-muted-foreground",
                    )}
                  >
                    {tiene && !esActual ? (
                      <Check className="size-3" aria-hidden />
                    ) : (
                      i + 1
                    )}
                  </span>
                  <span
                    className={cn(
                      "truncate text-xs transition-colors",
                      esActual
                        ? "font-medium text-foreground"
                        : "text-muted-foreground group-hover:text-foreground",
                    )}
                  >
                    {p.titulo}
                  </span>
                </span>
              </Link>
            </li>
          );
        })}
      </ol>

      <div className="space-y-2 lg:hidden">
        <div className="flex items-baseline justify-between gap-3">
          <p className="text-sm font-medium">{PASOS[indice].titulo}</p>
          <p className="shrink-0 text-xs tabular-nums text-muted-foreground">
            Paso {indice + 1} de {PASOS.length}
          </p>
        </div>
        <div className="h-1 w-full overflow-hidden rounded-full bg-border">
          <div
            className="h-full rounded-full bg-primary transition-[width] duration-300 ease-out"
            style={{ width: `${((indice + 1) / PASOS.length) * 100}%` }}
          />
        </div>
      </div>
    </nav>
  );
}
