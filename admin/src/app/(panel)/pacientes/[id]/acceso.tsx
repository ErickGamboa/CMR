"use client";

import { useState, useTransition } from "react";

import { ClaveTemporal } from "@/components/clave-temporal";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
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

  function asignar() {
    setError(null);
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
    <div className="space-y-4">
      <div className="space-y-1">
        <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
          Entra con
        </p>
        <p className="truncate text-sm font-medium">
          {correo ?? "— sin correo —"}
        </p>
      </div>

      <AlertDialog>
        <AlertDialogTrigger
          render={
            <Button variant="outline" className="w-full" disabled={enCurso} />
          }
        >
          {enCurso ? "Asignando…" : "Asignar contraseña nueva"}
        </AlertDialogTrigger>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>¿Asignar una contraseña nueva?</AlertDialogTitle>
            <AlertDialogDescription className="leading-relaxed">
              La que tenga ahora deja de funcionar. Si está usando la app en su
              teléfono, va a tener que volver a entrar con la nueva.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction onClick={asignar}>
              Asignar una nueva
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <p className="text-xs leading-relaxed text-muted-foreground">
        Para cuando el paciente no puede entrar y no maneja su correo. La
        contraseña actual no se puede consultar: se guarda cifrada.
      </p>

      {error && (
        <p role="alert" className="text-sm text-destructive">
          {error}
        </p>
      )}
    </div>
  );
}
