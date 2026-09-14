"use client";

import { useState, useTransition } from "react";

import { Button } from "@/components/ui/button";

import { cambiarMapeo } from "./acciones";

/**
 * Prender o apagar el módulo Mapeo para este paciente.
 *
 * Es el único módulo que se habilita uno por uno, así que el texto explica qué
 * cambia del lado del paciente: no es un ajuste del panel, es una ficha que le
 * aparece o le desaparece del Home.
 */
export function Interruptor({
  paciente,
  habilitado,
}: {
  paciente: string;
  habilitado: boolean;
}) {
  const [enCurso, empezar] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function cambiar() {
    setError(null);
    empezar(async () => {
      const r = await cambiarMapeo(paciente, !habilitado);
      if (r.error) setError(r.error);
    });
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-3">
        <span
          className={`inline-flex items-center gap-2 rounded-full px-3 py-1 text-sm font-medium transition-colors ${
            habilitado
              ? "bg-accent text-accent-foreground"
              : "bg-muted text-muted-foreground"
          }`}
        >
          <span
            aria-hidden
            className={`size-2 rounded-full ${habilitado ? "bg-primary" : "bg-muted-foreground/40"}`}
          />
          {habilitado ? "Habilitado" : "Apagado"}
        </span>

        <Button
          variant={habilitado ? "outline" : "default"}
          size="sm"
          onClick={cambiar}
          disabled={enCurso}
        >
          {enCurso
            ? "Guardando…"
            : habilitado
              ? "Apagar el módulo"
              : "Habilitar el módulo"}
        </Button>
      </div>

      <p className="max-w-prose text-sm leading-relaxed text-muted-foreground">
        {habilitado
          ? "El paciente ve la ficha de Mapeo en su Home y puede anotar su presión y su glisemia."
          : "El paciente no ve la ficha de Mapeo. Lo que ya haya anotado se conserva y vuelve a aparecer si lo habilitás."}
      </p>

      {error && (
        <p role="alert" className="text-sm text-destructive">
          {error}
        </p>
      )}
    </div>
  );
}
