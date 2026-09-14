"use client";

import Link from "next/link";
import { useState } from "react";

import { Button } from "@/components/ui/button";

/**
 * Muestra una contraseña recién asignada.
 *
 * Va en un bloque grande y en monoespaciada porque su destino es leerse en voz
 * alta o dictarse por teléfono a alguien que la va a escribir a mano.
 *
 * Y avisa que no se puede volver a ver: no es una restricción del sitio, es
 * que Supabase guarda un hash y no la contraseña. Si el doctor cierra esto sin
 * anotarla, la única salida es asignar otra.
 */
export function ClaveTemporal({
  titulo,
  nombre,
  correo,
  clave,
  verFicha,
}: {
  titulo: string;
  nombre?: string;
  correo?: string;
  clave: string;
  verFicha?: string;
}) {
  const [copiado, setCopiado] = useState(false);

  async function copiar() {
    try {
      await navigator.clipboard.writeText(clave);
      setCopiado(true);
      setTimeout(() => setCopiado(false), 2000);
    } catch {
      // Sin portapapeles (contexto no seguro, permiso negado): la contraseña
      // está a la vista igual, que es lo que importa.
    }
  }

  return (
    <div className="space-y-4 rounded-lg border border-accent-foreground/20 bg-accent/40 p-5">
      <div>
        <h2 className="font-medium">{titulo}</h2>
        {nombre && (
          <p className="mt-1 text-sm text-muted-foreground">
            {nombre}
            {correo && ` · ${correo}`}
          </p>
        )}
      </div>

      <div className="space-y-2">
        <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
          Contraseña
        </p>
        <div className="flex flex-wrap items-center gap-3">
          <code className="rounded-md border bg-background px-4 py-2.5 font-mono text-lg tracking-wide">
            {clave}
          </code>
          <Button type="button" variant="outline" size="sm" onClick={copiar}>
            {copiado ? "Copiada" : "Copiar"}
          </Button>
        </div>
      </div>

      <p className="max-w-prose text-sm text-muted-foreground">
        Anotala o dictásela ahora: <strong>no se puede volver a ver</strong>.
        Supabase guarda la contraseña cifrada, no la contraseña. Si se pierde,
        se le asigna otra.
      </p>

      {verFicha && (
        <Link
          href={verFicha}
          className="inline-block text-sm font-medium underline underline-offset-4"
        >
          Ver la ficha del paciente →
        </Link>
      )}
    </div>
  );
}
