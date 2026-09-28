"use client";

import { partir, type Valores } from "@/lib/indicaciones";

/**
 * Una plantilla escrita como va a quedar, con lo que falta resaltado.
 *
 * Es lo que hace que llenar sea rápido sin ser a ciegas: el doctor toca un
 * botón de dosis y ve la frase completa cambiar, y los `____` que quedan le
 * dicen qué le falta sin tener que leer un mensaje de error después.
 *
 * `sobreOscuro` es para el chip de dosis, que va en azul. Ahí lo lleno no
 * puede pintarse del color del texto normal —quedaría azul oscuro sobre azul
 * oscuro, o sea invisible justo en el dato que se acaba de escoger— así que
 * hereda el color del chip y solo cambia el grosor.
 */
export function Frase({
  plantilla,
  valores,
  sobreOscuro = false,
  className = "",
}: {
  plantilla: string;
  valores: Valores;
  sobreOscuro?: boolean;
  className?: string;
}) {
  return (
    <span className={className}>
      {partir(plantilla, valores).map((parte, i) => {
        if (parte.tipo === "texto") return <span key={i}>{parte.texto}</span>;

        return (
          <span
            key={i}
            className={
              parte.lleno
                ? sobreOscuro
                  ? "font-semibold"
                  : "font-semibold text-foreground"
                : sobreOscuro
                  ? "rounded bg-primary-foreground/25 px-1 font-semibold"
                  : "rounded bg-amber-500/15 px-1 font-semibold text-amber-700 dark:text-amber-400"
            }
          >
            {parte.texto}
          </span>
        );
      })}
    </span>
  );
}
