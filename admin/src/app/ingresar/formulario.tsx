"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

import { ingresar, type EstadoIngreso } from "./acciones";

const inicial: EstadoIngreso = { error: null };

export function FormularioIngreso({ volver }: { volver: string }) {
  const [estado, enviar] = useActionState(ingresar, inicial);

  return (
    <form action={enviar} className="space-y-5">
      <input type="hidden" name="volver" value={volver} />

      <div className="space-y-2">
        <Label htmlFor="correo">Correo</Label>
        <Input
          id="correo"
          name="correo"
          type="email"
          autoComplete="username"
          placeholder="nombre@clinica.cr"
          autoFocus
          required
        />
      </div>

      <div className="space-y-2">
        <Label htmlFor="clave">Contraseña</Label>
        <Input
          id="clave"
          name="clave"
          type="password"
          autoComplete="current-password"
          required
        />
      </div>

      {estado.error && (
        <Alert variant="destructive" className="animate-in fade-in">
          <AlertDescription>{estado.error}</AlertDescription>
        </Alert>
      )}

      <Boton />
    </form>
  );
}

/**
 * Va aparte porque `useFormStatus` solo funciona dentro del formulario que
 * está enviando, no en el componente que lo declara.
 */
function Boton() {
  const { pending } = useFormStatus();

  return (
    <Button type="submit" className="w-full" disabled={pending}>
      {pending ? "Entrando…" : "Entrar"}
    </Button>
  );
}
