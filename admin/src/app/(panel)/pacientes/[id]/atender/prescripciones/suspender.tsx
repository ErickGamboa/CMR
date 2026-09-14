"use client";

import { useState, useTransition } from "react";

import { Button } from "@/components/ui/button";

import { cambiarActivo } from "./acciones";

/**
 * Suspender o volver a indicar algo.
 *
 * Es lo que se usa casi siempre, y no el borrado: suspender conserva el
 * historial de lo que el paciente tomó y solo deja de mostrarlo en la app.
 * Borrar queda para lo que se cargó por error.
 */
export function Suspender({
  paciente,
  id,
  activo,
}: {
  paciente: string;
  id: string;
  activo: boolean;
}) {
  const [enCurso, empezar] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function cambiar() {
    setError(null);
    empezar(async () => {
      const r = await cambiarActivo(paciente, id, !activo);
      if (r.error) setError(r.error);
    });
  }

  return (
    <>
      <Button
        variant="ghost"
        size="sm"
        onClick={cambiar}
        disabled={enCurso}
        className="text-muted-foreground transition-colors hover:text-foreground"
      >
        {enCurso ? "…" : activo ? "Suspender" : "Reactivar"}
      </Button>
      {error && (
        <p role="alert" className="text-xs text-destructive">
          {error}
        </p>
      )}
    </>
  );
}
