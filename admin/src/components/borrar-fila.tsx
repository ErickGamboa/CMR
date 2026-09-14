"use client";

import { Trash2 } from "lucide-react";
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
 * Borrar un registro, con confirmación.
 *
 * `AlertDialog` y no un botón directo: son datos clínicos, y un clic de más en
 * la fila equivocada no debería borrar nada.
 */
export function BorrarFila({
  que,
  detalle,
  onBorrar,
}: {
  /** Qué se borra, para el título: "esta medición". */
  que: string;
  /** Cuál exactamente: la fecha, el nombre. */
  detalle: string;
  onBorrar: () => Promise<{ error: string | null }>;
}) {
  const [enCurso, empezar] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function borrar() {
    setError(null);
    empezar(async () => {
      const r = await onBorrar();
      if (r.error) setError(r.error);
    });
  }

  return (
    <>
      <AlertDialog>
        <AlertDialogTrigger
          render={
            <Button
              variant="ghost"
              size="icon"
              disabled={enCurso}
              aria-label={`Borrar ${que}`}
              className="text-muted-foreground transition-colors hover:text-destructive"
            />
          }
        >
          <Trash2 className="size-4" />
        </AlertDialogTrigger>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>¿Borrar {que}?</AlertDialogTitle>
            <AlertDialogDescription className="leading-relaxed">
              {detalle}. No se puede deshacer, y el paciente deja de verlo en la
              app.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              onClick={borrar}
              className="bg-destructive text-white hover:bg-destructive/90"
            >
              Borrar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {error && (
        <p role="alert" className="text-xs text-destructive">
          {error}
        </p>
      )}
    </>
  );
}
