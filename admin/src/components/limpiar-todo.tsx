"use client";

import { Eraser } from "lucide-react";
import { useState, useTransition } from "react";

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

/**
 * Vaciar una lista entera de un paso.
 *
 * Existe porque al replantear un tratamiento el doctor no quiere borrar
 * veintidós suplementos de uno en uno. Es el botón más destructivo del sitio,
 * así que:
 *
 *   - No aparece si no hay nada que limpiar. Un botón de borrar todo junto a
 *     una lista vacía solo invita a apretarlo.
 *   - Dice cuántos se lleva. "Limpiar todo" no informa; "se borran los 14 que
 *     tiene" sí, y es la última oportunidad de notar que estás en el paciente
 *     equivocado.
 */
export function LimpiarTodo({
  que,
  cuantos,
  advertencia,
  onLimpiar,
}: {
  /** Qué se vacía, en plural: "los suplementos". */
  que: string;
  cuantos: number;
  /** Una línea más para lo que no se recupera de ningún lado. */
  advertencia?: string;
  onLimpiar: () => Promise<{ error: string | null }>;
}) {
  const [enCurso, empezar] = useTransition();
  const [error, setError] = useState<string | null>(null);

  if (cuantos === 0) return null;

  function limpiar() {
    setError(null);
    empezar(async () => {
      const r = await onLimpiar();
      if (r.error) setError(r.error);
    });
  }

  return (
    <div className="flex flex-col items-end gap-1">
      <AlertDialog>
        <AlertDialogTrigger
          render={
            <Button
              variant="ghost"
              size="sm"
              disabled={enCurso}
              className="h-7 gap-1.5 px-2 text-xs text-muted-foreground transition-colors hover:text-destructive"
            />
          }
        >
          <Eraser aria-hidden className="size-3.5" />
          {enCurso ? "Limpiando…" : "Limpiar todo"}
        </AlertDialogTrigger>

        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>¿Limpiar {que}?</AlertDialogTitle>
            <AlertDialogDescription className="leading-relaxed">
              Se {cuantos === 1 ? "borra el que tiene" : `borran los ${cuantos} que tiene`}.
              No se puede deshacer, y el paciente deja de ver{cuantos === 1 ? "lo" : "los"} en
              la app.
              {advertencia && ` ${advertencia}`}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              onClick={limpiar}
              className="bg-destructive text-white hover:bg-destructive/90"
            >
              Limpiar {que}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {error && (
        <p role="alert" className="text-xs text-destructive">
          {error}
        </p>
      )}
    </div>
  );
}
