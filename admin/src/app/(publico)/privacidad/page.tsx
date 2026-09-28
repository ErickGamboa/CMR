import type { Metadata } from "next";
import Link from "next/link";

import {
  Correo,
  Lista,
  Parrafo,
  Prosa,
  Seccion,
  Titulo,
} from "@/components/prosa";
import { CORREO_SOPORTE } from "@/lib/contacto";

export const metadata: Metadata = {
  title: "Política de privacidad · CMR Control Metabólico",
  description:
    "Qué información recolecta la app CMR Control Metabólico, cómo se usa y cómo se protege.",
};

export default function Privacidad() {
  return (
    <Prosa>
      <Titulo actualizado="27 de septiembre de 2026">
        Política de privacidad
      </Titulo>

      <Parrafo>
        CMR Control Metabólico («la app», «CMR») es una aplicación para que los
        pacientes de la clínica den seguimiento a su tratamiento de control
        metabólico. Esta política explica qué información recolectamos, cómo la
        usamos y cómo la protegemos.
      </Parrafo>

      <Seccion titulo="1. Quién ofrece esta app">
        <Parrafo>
          CMR la opera el equipo clínico que te atiende. La app funciona junto
          con un panel administrativo que usa tu doctor(a) para dar seguimiento
          a tu caso; ambos comparten la misma base de datos, protegida para que
          cada paciente solo pueda ver su propia información.
        </Parrafo>
      </Seccion>

      <Seccion titulo="2. Qué información recolectamos">
        <Parrafo>
          <strong className="font-medium text-foreground">
            Al crear tu cuenta:
          </strong>
        </Parrafo>
        <Lista>
          <li>Nombre y apellidos</li>
          <li>Correo electrónico</li>
          <li>Cédula (opcional)</li>
          <li>Teléfono (opcional)</li>
          <li>Fecha de nacimiento (opcional)</li>
          <li>
            Contraseña, guardada cifrada. Nunca la vemos en texto plano.
          </li>
        </Lista>

        <Parrafo>
          <strong className="font-medium text-foreground">
            Información clínica que tu doctor(a) registra sobre tu tratamiento:
          </strong>
        </Parrafo>
        <Lista>
          <li>Citas: fecha, hora, profesional y especialidad</li>
          <li>
            Composición corporal: peso, porcentaje de grasa, grasa visceral,
            grasa perdida y músculo ganado
          </li>
          <li>Resultados de laboratorio: exámenes y valores</li>
          <li>Recomendaciones clínicas escritas por tu doctor(a)</li>
          <li>
            Prescripciones: suplementos, péptidos y medicamentos, con dosis y
            frecuencia
          </li>
          <li>Plan de alimentación asignado</li>
        </Lista>

        <Parrafo>
          <strong className="font-medium text-foreground">
            Información que vos mismo registrás en la app:
          </strong>
        </Parrafo>
        <Lista>
          <li>
            Mediciones de presión arterial y glicemia en casa, si tu doctor(a)
            activa el módulo de Mapeo
          </li>
        </Lista>

        <Parrafo>
          <strong className="font-medium text-foreground">
            Lo que no recolectamos:
          </strong>{" "}
          no accedemos a tu cámara, tus fotos, tu ubicación ni tus contactos —
          la app no pide ninguno de esos permisos. No usamos herramientas de
          analítica, publicidad ni rastreo de ningún tipo.
        </Parrafo>
      </Seccion>

      <Seccion titulo="3. Cómo usamos tu información">
        <Parrafo>
          Usamos tu información únicamente para darte el servicio de seguimiento
          clínico: que tu doctor(a) pueda ver tu evolución y registrar tus citas
          y resultados, y que vos puedas consultar tu plan y tus mediciones
          desde la app.
        </Parrafo>
      </Seccion>

      <Seccion titulo="4. Quién puede ver tu información">
        <Parrafo>
          Solo vos y el equipo clínico que te atiende, a través del panel
          administrativo de la clínica. El acceso está controlado en la base de
          datos: ningún otro paciente puede ver tus datos.
        </Parrafo>
        <Parrafo>
          No vendemos, alquilamos ni compartimos tu información con terceros con
          fines comerciales o publicitarios.
        </Parrafo>
        <Parrafo>
          <strong className="font-medium text-foreground">
            Enlaces externos:
          </strong>{" "}
          algunos videos educativos de la app se abren fuera, en tu navegador o
          en la app de la plataforma que los aloja. Esas plataformas tienen sus
          propias políticas de privacidad, independientes de esta.
        </Parrafo>
      </Seccion>

      <Seccion titulo="5. Dónde se almacena tu información">
        <Parrafo>
          Tu información se guarda en una base de datos (Supabase/PostgreSQL)
          protegida con cifrado en tránsito (HTTPS) y con reglas de seguridad a
          nivel de fila que garantizan que cada persona solo acceda a lo suyo.
          La app no deja copias de tu información clínica en el teléfono más
          allá de lo necesario durante la sesión.
        </Parrafo>
      </Seccion>

      <Seccion titulo="6. Tu cuenta y tus datos">
        <Lista>
          <li>
            <strong className="font-medium text-foreground">
              Crear cuenta:
            </strong>{" "}
            podés crearla desde la app. Queda pendiente hasta que la clínica la
            apruebe.
          </li>
          <li>
            <strong className="font-medium text-foreground">
              Iniciar sesión:
            </strong>{" "}
            con tu correo y contraseña.
          </li>
          <li>
            <strong className="font-medium text-foreground">
              Cambiar tu contraseña:
            </strong>{" "}
            si la olvidaste, escribinos o pedilo en recepción y la clínica te
            asigna una nueva.
          </li>
          <li>
            <strong className="font-medium text-foreground">
              Eliminar tu cuenta:
            </strong>{" "}
            desde la app, en Mi cuenta → Eliminar mi cuenta. Se borran también
            todas tus citas, mediciones, resultados de laboratorio,
            prescripciones, plan de alimentación y registros de mapeo. No se
            puede deshacer.
          </li>
        </Lista>
      </Seccion>

      <Seccion titulo="7. Menores de edad">
        <Parrafo>
          Si sos menor de edad, tu cuenta y el uso de la app deben estar
          supervisados por tu encargado(a) legal, en coordinación con la
          clínica.
        </Parrafo>
      </Seccion>

      <Seccion titulo="8. Cambios a esta política">
        <Parrafo>
          Si la actualizamos, publicamos la versión nueva en esta misma página
          con su fecha.
        </Parrafo>
      </Seccion>

      <Seccion titulo="9. Contacto">
        <Parrafo>
          Si tenés preguntas sobre esta política o sobre tu información,
          escribinos a <Correo correo={CORREO_SOPORTE} />. También podés ver las{" "}
          <Link
            href="/soporte"
            className="font-medium text-foreground underline underline-offset-4"
          >
            preguntas frecuentes
          </Link>
          .
        </Parrafo>
      </Seccion>
    </Prosa>
  );
}
