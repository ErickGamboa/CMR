"use client";

import { Check, Copy } from "lucide-react";
import Link from "next/link";
import { useState } from "react";

import { Button, buttonVariants } from "@/components/ui/button";

/**
 * Muestra una contraseña recién asignada.
 *
 * Va en grande y en monoespaciada porque su destino es leerse en voz alta o
 * dictarse por teléfono a alguien que la va a escribir a mano.
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
    <div className="animate-in fade-in zoom-in-95 duration-300 space-y-5 rounded-xl border border-accent-foreground/15 bg-accent/40 p-5 sm:p-6">
      <div className="space-y-1">
        <h2 className="font-medium">{titulo}</h2>
        {nombre && (
          <p className="text-sm text-muted-foreground">
            {nombre}
            {correo && ` · ${correo}`}
          </p>
        )}
        {!nombre && correo && (
          <p className="text-sm text-muted-foreground">{correo}</p>
        )}
      </div>

      <div className="space-y-2">
        <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
          Contraseña
        </p>
        <div className="flex flex-wrap items-center gap-2">
          <code className="flex-1 rounded-lg border bg-background px-4 py-3 text-center font-mono text-lg tracking-wider sm:text-xl">
            {clave}
          </code>
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={copiar}
            className="gap-1.5 transition-colors"
          >
            {copiado ? (
              <>
                <Check className="size-4" /> Copiada
              </>
            ) : (
              <>
                <Copy className="size-4" /> Copiar
              </>
            )}
          </Button>
        </div>
      </div>

      <p className="text-sm leading-relaxed text-muted-foreground">
        Anotala o dictásela ahora: <strong>no se puede volver a ver</strong>.
        Supabase guarda la contraseña cifrada, no la contraseña. Si se pierde,
        se le asigna otra.
      </p>

      {verFicha && (
        <Link
          href={verFicha}
          className={buttonVariants({ variant: "outline", size: "sm" })}
        >
          Ver la ficha del paciente
        </Link>
      )}
    </div>
  );
}
