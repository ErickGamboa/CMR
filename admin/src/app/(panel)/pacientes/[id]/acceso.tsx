"use client";

import { useState, useTransition } from "react";

import { ClaveTemporal } from "@/components/clave-temporal";
import { Button } from "@/components/ui/button";

import { nuevaClave } from "./acciones";

/**
 * Cómo entra el paciente a la app, y qué puede hacer el doctor si no puede.
 *
 * Acá no se muestra ninguna contraseña guardada porque no hay ninguna que
 * mostrar: Supabase guarda un hash. Lo que sí se puede es ponerle una nueva,
 * que resuelve el caso real —el paciente mayor que no logra entrar— sin que la
 * clínica tenga contraseñas legibles de nadie.
 */
export function Acceso({ id, correo }: { id: string; correo: string | null }) {
  const [enCurso, empezar] = useTransition();
  const [clave, setClave] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [confirmando, setConfirmando] = useState(false);

  function asignar() {
    setError(null);
    setConfirmando(false);
    empezar(async () => {
      const r = await nuevaClave(id);
      if (r.ok) setClave(r.clave);
      else setError(r.error);
    });
  }

  if (clave) {
    return (
      <ClaveTemporal
        titulo="Contraseña nueva"
        correo={correo ?? undefined}
        clave={clave}
      />
    );
  }

  return (
    <div className="space-y-3 rounded-lg border p-4">
      <div className="text-sm">
        <span className="text-muted-foreground">Entra con </span>
        <span className="font-medium">{correo ?? "— sin correo —"}</span>
      </div>

      {confirmando ? (
        <div className="space-y-3">
          <p className="max-w-prose text-sm">
            La contraseña que tenga ahora va a dejar de funcionar. Si está
            usando la app en su teléfono, va a tener que volver a entrar con la
            nueva.
          </p>
          <div className="flex gap-2">
            <Button onClick={asignar} disabled={enCurso}>
              {enCurso ? "Asignando…" : "Sí, asignar una nueva"}
            </Button>
            <Button
              variant="outline"
              onClick={() => setConfirmando(false)}
              disabled={enCurso}
            >
              Cancelar
            </Button>
          </div>
        </div>
      ) : (
        <div className="space-y-2">
          <Button variant="outline" onClick={() => setConfirmando(true)}>
            Asignar contraseña nueva
          </Button>
          <p className="max-w-prose text-xs text-muted-foreground">
            Para cuando el paciente no puede entrar y no maneja su correo. La
            contraseña actual no se puede consultar: se guarda cifrada.
          </p>
        </div>
      )}

      {error && (
        <p role="alert" className="text-sm text-destructive">
          {error}
        </p>
      )}
    </div>
  );
}
