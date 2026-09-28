import type { Metadata } from "next";
import Link from "next/link";

import { Correo, Parrafo, Prosa, Seccion, Titulo } from "@/components/prosa";
import { CORREO_SOPORTE } from "@/lib/contacto";

export const metadata: Metadata = {
  title: "Soporte · CMR Control Metabólico",
  description:
    "Ayuda con la app CMR Control Metabólico: crear cuenta, recuperar la contraseña y eliminar la cuenta.",
};

export default function Soporte() {
  return (
    <Prosa>
      <Titulo>Soporte</Titulo>

      <Parrafo>
        ¿Necesitás ayuda con la app? Escribinos a{" "}
        <Correo correo={CORREO_SOPORTE} /> y te respondemos lo antes posible.
      </Parrafo>

      <Seccion titulo="¿Cómo creo mi cuenta?">
        <Parrafo>
          Abrí la app y tocá «Crear una cuenta». Completá tus datos y esperá a
          que la clínica apruebe la cuenta. Mientras tanto la app te avisa que
          está pendiente.
        </Parrafo>
      </Seccion>

      <Seccion titulo="Olvidé mi contraseña, ¿qué hago?">
        <Parrafo>
          Por ahora el cambio lo hace la clínica. Escribinos a{" "}
          <Correo correo={CORREO_SOPORTE} />, o pedilo en recepción o
          directamente a tu doctor(a), y te asignamos una nueva.
        </Parrafo>
      </Seccion>

      <Seccion titulo="¿Cómo veo mis citas, mediciones o plan de alimentación?">
        <Parrafo>
          Una vez que tu cuenta esté activa, todo eso aparece dentro de la app,
          actualizado por tu doctor(a) en cada consulta. El botón de actualizar
          de la barra superior vuelve a bajar los datos en cualquier momento.
        </Parrafo>
      </Seccion>

      <Seccion titulo="¿Cómo elimino mi cuenta?">
        <Parrafo>
          Desde la app: Mi cuenta → Eliminar mi cuenta. Eso borra tu cuenta y
          toda tu información clínica de forma permanente e inmediata, y no se
          puede deshacer.
        </Parrafo>
      </Seccion>

      <Seccion titulo="¿Mis datos están seguros?">
        <Parrafo>
          Sí. Tu información viaja cifrada y solo vos y tu equipo clínico pueden
          verla. El detalle está en la{" "}
          <Link
            href="/privacidad"
            className="font-medium text-foreground underline underline-offset-4"
          >
            política de privacidad
          </Link>
          .
        </Parrafo>
      </Seccion>
    </Prosa>
  );
}
