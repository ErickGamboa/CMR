import {
  ArrowRight,
  ArrowUpRight,
  Atom,
  CalendarCheck,
  Check,
  Dna,
  Droplets,
  FlaskConical,
  Sparkles,
  Wind,
  type LucideIcon,
} from "lucide-react";
import type { Metadata } from "next";
import { Poppins } from "next/font/google";
import Image from "next/image";
import Link from "next/link";

import { Reels, type Reel } from "@/components/inicio/reels";
import { Logo } from "@/components/logo";
import {
  CORREO_SOPORTE,
  INSTAGRAM_CLINICA,
  INSTAGRAM_DOCTOR,
  WHATSAPP,
} from "@/lib/contacto";

import doctorBrazos from "../../public/inicio/doctor-brazos.jpg";
import doctorGris from "../../public/inicio/doctor-gris.jpg";
import doctorSillon from "../../public/inicio/doctor-sillon.jpg";

/**
 * La portada pública de la clínica.
 *
 * Al revés que el resto del sitio, esta sí es para buscadores. El panel ya no
 * empieza acá: su login vive en /admin y a propósito no hay ningún enlace que
 * lleve hasta él.
 *
 * Los textos salen del material de la clínica (misión, visión y los videos
 * del doctor). Se agenda por WhatsApp o Instagram —no por llamada—; no hay
 * dirección porque la clínica no la dio.
 */
export const metadata: Metadata = {
  title: "CMR · Control Metabólico y Regenerativo",
  description:
    "Medicina metabólica y regenerativa en Costa Rica. Abordaje integral de patologías crónicas y metabólicas con péptidos, exosomas, células madre, ozono, hidrógeno molecular y sueroterapia funcional.",
  robots: { index: true, follow: true },
};

// La misma letra que usa la clínica en sus publicaciones: así la página y el
// Instagram se sienten de la misma casa. Solo para títulos; el cuerpo sigue
// en Geist como el resto del sitio.
const display = Poppins({
  subsets: ["latin"],
  weight: ["400", "600", "700"],
});

const TERAPIAS: { nombre: string; texto: string; icono: LucideIcon }[] = [
  {
    nombre: "Péptidos",
    texto:
      "Cadenas cortas de aminoácidos que actúan como mensajeros del cuerpo, para apoyar la reparación y la regulación metabólica.",
    icono: FlaskConical,
  },
  {
    nombre: "Exosomas",
    texto:
      "Las vesículas con que las células se comunican entre sí, usadas para favorecer la regeneración de los tejidos.",
    icono: Sparkles,
  },
  {
    nombre: "Células madre",
    texto:
      "Terapia biológica avanzada orientada a restaurar la función de los tejidos desde su origen.",
    icono: Dna,
  },
  {
    nombre: "Ozono",
    texto:
      "Ozonoterapia médica como apoyo en el manejo de procesos inflamatorios y enfermedades crónicas.",
    icono: Wind,
  },
  {
    nombre: "Hidrógeno molecular",
    texto:
      "Un antioxidante selectivo para ayudar a reducir el estrés oxidativo que acelera el deterioro celular.",
    icono: Atom,
  },
  {
    nombre: "Sueroterapia funcional",
    texto:
      "Vitaminas, minerales y nutrientes por vía intravenosa, formulados según lo que tu cuerpo necesita.",
    icono: Droplets,
  },
];

const REELS: Reel[] = [
  {
    clave: "voluntad",
    tema: "Sobrepeso",
    titulo: "Tener sobrepeso no es falta de fuerza de voluntad",
  },
  {
    clave: "bajar-de-peso",
    tema: "Entrevista",
    titulo: "¿Por qué no logro bajar de peso?",
  },
  {
    clave: "fajas",
    tema: "Mitos",
    titulo: "¿Las fajas ayudan a quemar grasa?",
  },
  {
    clave: "diabetes",
    tema: "Diabetes",
    titulo: "Si tienes diabetes, este video es para ti",
  },
  {
    clave: "menopausia",
    tema: "Hormonas",
    titulo: "¿Es normal engordar en la menopausia?",
  },
  {
    clave: "musculo",
    tema: "Longevidad",
    titulo: "Lo que hagas hoy decide cómo llegas a la vejez",
  },
];

export default function Inicio() {
  return (
    <div className="flex min-h-dvh flex-col bg-white text-[#10102e]">
      <Cabecera />
      <main className="flex-1">
        <Portada />
        <Cinta />
        <Enfoque />
        <Terapias />
        <Doctor />
        <Videos />
        <Vision />
        <App />
        <Contacto />
      </main>
      <Pie />
    </div>
  );
}

/* ------------------------------------------------------------------------ */

function Cabecera() {
  return (
    <header className="sticky top-0 z-30 border-b border-black/5 bg-white/80 backdrop-blur-md">
      <div className="mx-auto flex h-16 max-w-7xl items-center gap-6 px-4 sm:px-6">
        <Link
          href="/"
          aria-label="Inicio"
          className="flex shrink-0 items-center gap-3"
        >
          <Logo variante="marca" alto={26} prioridad />
          <span className="hidden text-[0.65rem] font-medium uppercase leading-tight tracking-[0.22em] text-[#62a1a6] sm:block">
            Control metabólico
            <br />& regenerativo
          </span>
        </Link>

        <nav className="ml-auto hidden items-center gap-7 text-sm text-[#5b5f73] md:flex">
          <a href="#enfoque" className="transition-colors hover:text-[#090972]">
            Enfoque
          </a>
          <a href="#terapias" className="transition-colors hover:text-[#090972]">
            Terapias
          </a>
          <a href="#doctor" className="transition-colors hover:text-[#090972]">
            El doctor
          </a>
          <a href="#videos" className="transition-colors hover:text-[#090972]">
            Videos
          </a>
        </nav>

        <a
          href="#contacto"
          className="ml-auto inline-flex items-center gap-2 rounded-full bg-[#090972] px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-[#13138f] md:ml-0"
        >
          Agendar
          <ArrowRight className="size-4" />
        </a>
      </div>
    </header>
  );
}

function Portada() {
  return (
    <section className="relative overflow-hidden">
      <div aria-hidden className="pointer-events-none absolute inset-0">
        <div className="absolute -left-40 -top-40 size-[34rem] rounded-full bg-[#86dbfb] opacity-25 blur-3xl" />
        <div className="absolute -right-32 top-1/3 size-[30rem] rounded-full bg-[#62a1a6] opacity-20 blur-3xl" />
      </div>

      <div className="relative mx-auto grid max-w-7xl items-center gap-12 px-4 pb-16 pt-12 sm:px-6 sm:pt-16 lg:grid-cols-[1.1fr_0.9fr] lg:gap-8 lg:pb-24 lg:pt-20">
        <div className="animate-in fade-in slide-in-from-bottom-4 duration-700">
          <p className="text-xs font-semibold uppercase tracking-[0.3em] text-[#62a1a6]">
            Clínica COSME · CMR
          </p>
          <h1
            className={`${display.className} mt-5 text-[2.6rem] leading-[1.05] tracking-tight sm:text-6xl lg:text-7xl`}
          >
            Tu metabolismo
            <br />
            <span className="font-bold text-[#090972]">
              no es solo comida.
            </span>
          </h1>
          <p className="mt-6 max-w-xl text-lg leading-relaxed text-[#5b5f73]">
            Medicina metabólica y regenerativa para restaurar el equilibrio de
            tu cuerpo desde la célula. Tratamos patologías crónicas y
            metabólicas con biotecnología avanzada, respaldo científico y
            precisión clínica.
          </p>

          <div className="mt-9 flex flex-col gap-3 sm:flex-row">
            <a
              href="#contacto"
              className="inline-flex items-center justify-center gap-2 rounded-full bg-[#090972] px-7 py-3.5 font-medium text-white shadow-lg shadow-[#090972]/25 transition hover:-translate-y-0.5 hover:bg-[#13138f]"
            >
              <CalendarCheck className="size-5" />
              Agenda tu valoración
            </a>
            <a
              href="#enfoque"
              className="inline-flex items-center justify-center gap-2 rounded-full border border-[#090972]/15 bg-white/60 px-7 py-3.5 font-medium text-[#090972] backdrop-blur transition hover:border-[#090972]/40"
            >
              Conoce el enfoque
            </a>
          </div>

          <ul className="mt-10 flex flex-wrap gap-x-6 gap-y-3 text-sm text-[#5b5f73]">
            {[
              "Valoración integral",
              "Planes personalizados",
              "Seguimiento en la app CMR",
            ].map((t) => (
              <li key={t} className="flex items-center gap-2">
                <span className="flex size-5 items-center justify-center rounded-full bg-[#e7f1f2] text-[#62a1a6]">
                  <Check className="size-3.5" strokeWidth={3} />
                </span>
                {t}
              </li>
            ))}
          </ul>
        </div>

        <div className="animate-in fade-in zoom-in-95 relative mx-auto w-full max-w-md duration-1000 lg:max-w-none">
          <div className="relative aspect-[4/5] overflow-hidden rounded-[2.5rem] bg-[#a9abaf] shadow-2xl shadow-[#090972]/20">
            <Image
              src={doctorBrazos}
              alt="Dr. Roy Jiménez, de brazos cruzados"
              fill
              priority
              placeholder="blur"
              sizes="(min-width: 1024px) 40vw, 90vw"
              className="object-cover object-top"
            />
            <div className="absolute inset-x-0 bottom-0 h-1/3 bg-gradient-to-t from-[#090972]/50 to-transparent" />
          </div>

          <div className="absolute -bottom-5 -left-3 rounded-2xl bg-white/95 px-5 py-4 shadow-xl ring-1 ring-black/5 backdrop-blur sm:-left-8">
            <p className={`${display.className} font-semibold text-[#090972]`}>
              Dr. Roy Jiménez
            </p>
            <p className="text-xs text-[#5b5f73]">
              Medicina metabólica y regenerativa
            </p>
          </div>

          <a
            href={INSTAGRAM_DOCTOR}
            target="_blank"
            rel="noopener noreferrer"
            className="absolute -right-2 top-8 flex items-center gap-2 rounded-full bg-white/95 py-2 pl-2 pr-4 text-xs font-medium text-[#10102e] shadow-lg ring-1 ring-black/5 backdrop-blur transition hover:-translate-y-0.5 sm:-right-6"
          >
            <span className="flex size-7 items-center justify-center rounded-full bg-gradient-to-tr from-[#090972] to-[#62a1a6] text-white">
              <IconoInstagram className="size-3.5" />
            </span>
            @drroyjimenez
          </a>
        </div>
      </div>
    </section>
  );
}

/** Las terapias pasando en bucle, como la cinta de un laboratorio. */
function Cinta() {
  const nombres = TERAPIAS.map((t) => t.nombre);
  // Dos copias seguidas: la animación corre la mitad del ancho y el salto de
  // vuelta al inicio cae justo donde empieza la segunda, sin que se note.
  const fila = [...nombres, ...nombres];

  return (
    <div className="overflow-hidden bg-[#090972] py-5 text-white">
      <div className="cinta flex w-max gap-10">
        {fila.map((n, i) => (
          <span
            key={i}
            aria-hidden={i >= nombres.length}
            className={`${display.className} flex items-center gap-10 whitespace-nowrap text-lg font-semibold sm:text-xl`}
          >
            {n}
            <span className="size-2 rounded-full bg-[#86dbfb]" />
          </span>
        ))}
      </div>
    </div>
  );
}

function Enfoque() {
  const pilares = [
    {
      n: "01",
      titulo: "Restaurar el equilibrio celular",
      texto:
        "La salud empieza en la célula. Buscamos que tu cuerpo recupere la función que el tiempo, la inflamación o el metabolismo le han quitado.",
    },
    {
      n: "02",
      titulo: "Revertir disfunciones biológicas",
      texto:
        "Insulina, hormonas, inflamación: vamos a la causa de fondo de las enfermedades crónicas y metabólicas, no solo al síntoma.",
    },
    {
      n: "03",
      titulo: "Potenciar la longevidad saludable",
      texto:
        "No se trata solo de vivir más años, sino de llegar a ellos con energía, músculo y autonomía.",
    },
  ];

  return (
    <section id="enfoque" className="scroll-mt-20 py-20 sm:py-28">
      <div className="mx-auto max-w-7xl px-4 sm:px-6">
        <div className="grid gap-10 lg:grid-cols-[0.9fr_1.1fr] lg:gap-16">
          <div className="aparecer">
            <Etiqueta>Nuestra misión</Etiqueta>
            <h2
              className={`${display.className} mt-4 text-3xl font-semibold leading-tight tracking-tight sm:text-5xl`}
            >
              Transformar tu salud desde la{" "}
              <span className="text-[#62a1a6]">medicina regenerativa.</span>
            </h2>
          </div>
          <p className="aparecer self-end text-lg leading-relaxed text-[#5b5f73]">
            Abordamos de forma integral las patologías crónicas y metabólicas.
            Integramos biotecnología avanzada —péptidos, exosomas, células
            madre, ozono, hidrógeno molecular y sueroterapia funcional— con un
            solo objetivo: que tu cuerpo vuelva a funcionar como debe, con
            respaldo científico y precisión clínica.
          </p>
        </div>

        <div className="mt-16 grid gap-px overflow-hidden rounded-3xl border border-[#e1e6ee] bg-[#e1e6ee] md:grid-cols-3">
          {pilares.map((p) => (
            <article
              key={p.n}
              className="aparecer group bg-white p-8 transition-colors hover:bg-[#f4f7fa] sm:p-10"
            >
              <span
                className={`${display.className} text-5xl font-bold text-[#86dbfb] transition-colors group-hover:text-[#62a1a6]`}
              >
                {p.n}
              </span>
              <h3
                className={`${display.className} mt-6 text-xl font-semibold text-[#090972]`}
              >
                {p.titulo}
              </h3>
              <p className="mt-3 leading-relaxed text-[#5b5f73]">{p.texto}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

function Terapias() {
  return (
    <section
      id="terapias"
      className="scroll-mt-20 bg-[#f4f7fa] py-20 sm:py-28"
    >
      <div className="mx-auto max-w-7xl px-4 sm:px-6">
        <div className="aparecer max-w-2xl">
          <Etiqueta>Terapias</Etiqueta>
          <h2
            className={`${display.className} mt-4 text-3xl font-semibold leading-tight tracking-tight sm:text-5xl`}
          >
            Biotecnología al servicio de tu metabolismo
          </h2>
          <p className="mt-5 text-lg leading-relaxed text-[#5b5f73]">
            Cada terapia se indica después de una valoración médica y se ajusta
            a tu caso. No hay paquetes iguales para todos.
          </p>
        </div>

        <ul className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {TERAPIAS.map(({ nombre, texto, icono: Icono }) => (
            <li
              key={nombre}
              className="aparecer group relative overflow-hidden rounded-3xl bg-white p-8 ring-1 ring-[#e1e6ee] transition duration-300 hover:-translate-y-1 hover:shadow-xl hover:shadow-[#090972]/10"
            >
              <div
                aria-hidden
                className="absolute -right-10 -top-10 size-32 rounded-full bg-[#86dbfb] opacity-0 blur-2xl transition-opacity duration-500 group-hover:opacity-40"
              />
              <span className="relative flex size-12 items-center justify-center rounded-2xl bg-[#090972] text-[#86dbfb]">
                <Icono className="size-6" />
              </span>
              <h3
                className={`${display.className} relative mt-6 text-xl font-semibold text-[#090972]`}
              >
                {nombre}
              </h3>
              <p className="relative mt-3 leading-relaxed text-[#5b5f73]">
                {texto}
              </p>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}

function Doctor() {
  const temas = [
    "Sobrepeso y obesidad",
    "Diabetes y resistencia a la insulina",
    "Cambios hormonales y menopausia",
    "Masa muscular y longevidad",
  ];

  return (
    <section id="doctor" className="scroll-mt-20 py-20 sm:py-28">
      <div className="mx-auto grid max-w-7xl items-center gap-12 px-4 sm:px-6 lg:grid-cols-2 lg:gap-20">
        <div className="aparecer relative mx-auto w-full max-w-md lg:max-w-none">
          <div
            aria-hidden
            className="absolute -inset-4 -z-10 rotate-3 rounded-[2.75rem] bg-gradient-to-br from-[#86dbfb]/40 to-[#62a1a6]/30"
          />
          <div className="relative aspect-[4/5] overflow-hidden rounded-[2.5rem] bg-[#a9abaf]">
            <Image
              src={doctorSillon}
              alt="Dr. Roy Jiménez sentado en un sillón"
              fill
              placeholder="blur"
              sizes="(min-width: 1024px) 45vw, 90vw"
              className="object-cover object-top"
            />
          </div>
        </div>

        <div className="aparecer">
          <Etiqueta>Quién te atiende</Etiqueta>
          <h2
            className={`${display.className} mt-4 text-3xl font-semibold leading-tight tracking-tight sm:text-5xl`}
          >
            Dr. Roy Jiménez
          </h2>
          <p className="mt-6 text-lg leading-relaxed text-[#5b5f73]">
            Atiende a personas que llevan años luchando con su peso, con la
            diabetes o con cambios hormonales, y que ya probaron de todo. Su
            consulta parte de una idea simple:{" "}
            <strong className="font-semibold text-[#090972]">
              el sobrepeso no es falta de fuerza de voluntad.
            </strong>{" "}
            Detrás hay insulina, hormonas y un metabolismo que se puede
            entender, medir y tratar.
          </p>
          <p className="mt-4 text-lg leading-relaxed text-[#5b5f73]">
            Por eso cada tratamiento es 100&nbsp;% personalizado y se construye
            sobre tus resultados, no sobre una receta genérica.
          </p>

          <ul className="mt-8 grid gap-3 sm:grid-cols-2">
            {temas.map((t) => (
              <li
                key={t}
                className="flex items-start gap-3 rounded-2xl bg-[#f4f7fa] px-4 py-3 text-sm font-medium"
              >
                <Check
                  className="mt-0.5 size-4 shrink-0 text-[#62a1a6]"
                  strokeWidth={3}
                />
                {t}
              </li>
            ))}
          </ul>

          <a
            href={INSTAGRAM_DOCTOR}
            target="_blank"
            rel="noopener noreferrer"
            className="mt-8 inline-flex items-center gap-2 font-medium text-[#090972] underline-offset-4 hover:underline"
          >
            <IconoInstagram className="size-4" />
            Síguelo en @drroyjimenez
            <ArrowUpRight className="size-4" />
          </a>
        </div>
      </div>
    </section>
  );
}

function Videos() {
  return (
    <section id="videos" className="scroll-mt-20 bg-[#f4f7fa] py-20 sm:py-28">
      <div className="mx-auto max-w-7xl px-4 sm:px-6">
        <div className="aparecer flex flex-col justify-between gap-6 sm:flex-row sm:items-end">
          <div className="max-w-2xl">
            <Etiqueta>Hablemos claro</Etiqueta>
            <h2
              className={`${display.className} mt-4 text-3xl font-semibold leading-tight tracking-tight sm:text-5xl`}
            >
              Lo que escuchamos en consulta, explicado en un minuto
            </h2>
          </div>
          <a
            href={INSTAGRAM_DOCTOR}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex shrink-0 items-center gap-2 rounded-full border border-[#090972]/15 bg-white px-5 py-2.5 text-sm font-medium text-[#090972] transition hover:border-[#090972]/40"
          >
            Más en Instagram
            <ArrowUpRight className="size-4" />
          </a>
        </div>

        <div className="mt-12">
          <Reels reels={REELS} />
        </div>
      </div>
    </section>
  );
}

function Vision() {
  return (
    <section className="relative overflow-hidden bg-[#090972] py-24 text-white sm:py-32">
      <div aria-hidden className="pointer-events-none absolute inset-0">
        <div className="absolute -bottom-40 left-1/4 size-[36rem] rounded-full bg-[#86dbfb] opacity-20 blur-3xl" />
        <div className="absolute -right-20 -top-20 size-[24rem] rounded-full bg-[#62a1a6] opacity-30 blur-3xl" />
      </div>

      <div className="relative mx-auto max-w-5xl px-4 text-center sm:px-6">
        {/* El logo normal es azul abisal y acá desaparecería: esta es la
            versión en blanco, sacada del mismo PNG. */}
        <Image
          src="/inicio/logo-cmr-blanco.png"
          alt=""
          width={140}
          height={100}
          className="aparecer mx-auto opacity-90"
        />
        <p className="aparecer mt-10 text-xs font-semibold uppercase tracking-[0.3em] text-[#86dbfb]">
          Nuestra visión
        </p>
        <blockquote
          className={`${display.className} aparecer mt-6 text-2xl font-semibold leading-snug sm:text-4xl sm:leading-tight`}
        >
          Ser el centro de referencia en medicina metabólica y regenerativa, y{" "}
          <span className="text-[#86dbfb]">
            redefinir el estándar de atención
          </span>{" "}
          hacia un modelo que restaura la función celular y previene el
          deterioro biológico.
        </blockquote>
      </div>
    </section>
  );
}

function App() {
  const puntos = [
    "Tu plan de alimentación, siempre a mano",
    "Tus próximas citas",
    "Tus mediciones y cómo van cambiando",
    "Todo actualizado por tu doctor en cada consulta",
  ];

  return (
    <section className="py-20 sm:py-28">
      <div className="mx-auto grid max-w-7xl items-center gap-14 px-4 sm:px-6 lg:grid-cols-2">
        <div className="aparecer order-2 lg:order-1">
          <Etiqueta>App CMR</Etiqueta>
          <h2
            className={`${display.className} mt-4 text-3xl font-semibold leading-tight tracking-tight sm:text-5xl`}
          >
            Tu seguimiento no termina al salir de consulta
          </h2>
          <p className="mt-5 text-lg leading-relaxed text-[#5b5f73]">
            Como paciente de CMR tienes tu propia app. Ahí vive todo lo que
            acordaste con tu doctor, para que no dependas de la memoria ni de
            un papel.
          </p>
          <ul className="mt-8 space-y-3">
            {puntos.map((p) => (
              <li key={p} className="flex items-center gap-3">
                <span className="flex size-6 items-center justify-center rounded-full bg-[#090972] text-white">
                  <Check className="size-3.5" strokeWidth={3} />
                </span>
                {p}
              </li>
            ))}
          </ul>
        </div>

        <div className="aparecer order-1 flex justify-center lg:order-2">
          <Telefono />
        </div>
      </div>
    </section>
  );
}

/**
 * Un teléfono dibujado con CSS, con una vista de la app a modo de ilustración.
 * Los datos son de ejemplo; nada acá sale de un paciente real.
 */
function Telefono() {
  return (
    <div className="relative">
      <div
        aria-hidden
        className="absolute -inset-10 rounded-full bg-gradient-to-tr from-[#86dbfb]/40 to-[#62a1a6]/20 blur-3xl"
      />
      <div
        aria-hidden
        className="relative w-[17rem] rounded-[2.75rem] bg-[#10102e] p-3 shadow-2xl shadow-[#090972]/30"
      >
        <div className="overflow-hidden rounded-[2.1rem] bg-[#f4f7fa]">
          <div className="bg-[#090972] px-5 pb-6 pt-8 text-white">
            <p className="text-[0.65rem] uppercase tracking-[0.2em] text-[#86dbfb]">
              Hola de nuevo
            </p>
            <p className={`${display.className} mt-1 text-lg font-semibold`}>
              Tu progreso
            </p>
            <div className="mt-4 flex items-end gap-1.5">
              {[60, 52, 70, 48, 64, 40, 34].map((h, i) => (
                <span
                  key={i}
                  style={{ height: `${h}px` }}
                  className="flex-1 rounded-t-md bg-gradient-to-t from-[#62a1a6] to-[#86dbfb]"
                />
              ))}
            </div>
          </div>
          <div className="space-y-3 p-4">
            <TarjetaApp titulo="Próxima cita" valor="Jueves · 10:30 a. m." />
            <TarjetaApp titulo="Plan de alimentación" valor="Desayuno · Almuerzo · Cena" />
            <TarjetaApp titulo="Última medición" valor="Cintura −4 cm" />
          </div>
        </div>
      </div>
    </div>
  );
}

function TarjetaApp({ titulo, valor }: { titulo: string; valor: string }) {
  return (
    <div className="rounded-2xl bg-white px-4 py-3 shadow-sm ring-1 ring-black/5">
      <p className="text-[0.65rem] uppercase tracking-wider text-[#62a1a6]">
        {titulo}
      </p>
      <p className="mt-0.5 text-sm font-medium text-[#090972]">{valor}</p>
    </div>
  );
}

function Contacto() {
  return (
    <section id="contacto" className="scroll-mt-20 pb-20 sm:pb-28">
      <div className="mx-auto max-w-7xl px-4 sm:px-6">
        <div className="aparecer relative grid overflow-hidden rounded-[2.5rem] bg-gradient-to-br from-[#090972] via-[#13138f] to-[#1d5e7a] text-white lg:grid-cols-[1.2fr_0.8fr]">
          <div
            aria-hidden
            className="pointer-events-none absolute -left-20 -top-20 size-80 rounded-full bg-[#86dbfb] opacity-20 blur-3xl"
          />
          <div className="relative p-8 sm:p-14">
            <p className="text-xs font-semibold uppercase tracking-[0.3em] text-[#86dbfb]">
              Da el primer paso
            </p>
            <h2
              className={`${display.className} mt-4 text-3xl font-semibold leading-tight tracking-tight sm:text-5xl`}
            >
              Agenda tu valoración
            </h2>
            <p className="mt-5 max-w-lg text-lg leading-relaxed text-white/80">
              Escríbenos por WhatsApp y coordinamos tu primera consulta. Te ayudamos a entender tu metabolismo más a fondo.
            </p>

            <div className="mt-9 flex flex-col gap-3 sm:flex-row sm:flex-wrap">
              <a
                href={WHATSAPP}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center gap-2 rounded-full bg-white px-6 py-3.5 font-medium text-[#090972] transition hover:-translate-y-0.5 hover:bg-[#dff3fe]"
              >
                <IconoWhatsapp className="size-5" />
                Escríbenos por WhatsApp
              </a>
            </div>

            <div className="mt-6 flex flex-wrap gap-x-6 gap-y-2 text-sm text-white/75">
              <a
                href={INSTAGRAM_CLINICA}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 hover:text-white"
              >
                <IconoInstagram className="size-4" />
                @cmr.cosmeclinic
              </a>
              <a
                href={INSTAGRAM_DOCTOR}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 hover:text-white"
              >
                <IconoInstagram className="size-4" />
                @drroyjimenez
              </a>
            </div>
          </div>

          <div className="relative hidden min-h-80 lg:block">
            <Image
              src={doctorGris}
              alt="Dr. Roy Jiménez sonriendo"
              fill
              placeholder="blur"
              sizes="30vw"
              className="object-cover object-top"
            />
            <div className="absolute inset-0 bg-gradient-to-r from-[#13138f] via-transparent to-transparent" />
          </div>
        </div>
      </div>
    </section>
  );
}

function Pie() {
  return (
    <footer className="border-t border-[#e1e6ee]">
      <div className="mx-auto flex max-w-7xl flex-col gap-8 px-4 py-10 sm:px-6 md:flex-row md:items-center md:justify-between">
        <div className="flex items-center gap-4">
          <Logo variante="completo" alto={56} />
          <p className="max-w-[18rem] text-sm text-[#5b5f73]">
            Clínica COSME – CMR · Control Metabólico y Regenerativo
          </p>
        </div>

        <nav className="flex flex-wrap items-center gap-x-6 gap-y-3 text-sm text-[#5b5f73]">
          <Link href="/privacidad" className="hover:text-[#090972]">
            Privacidad
          </Link>
          <Link href="/soporte" className="hover:text-[#090972]">
            Soporte de la app
          </Link>
          <a href={`mailto:${CORREO_SOPORTE}`} className="hover:text-[#090972]">
            Escríbenos
          </a>
          <a
            href={WHATSAPP}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1.5 hover:text-[#090972]"
          >
            <IconoWhatsapp className="size-4" />
            WhatsApp
          </a>
          <a
            href={INSTAGRAM_CLINICA}
            target="_blank"
            rel="noopener noreferrer"
            aria-label="Instagram de la clínica"
            className="flex size-9 items-center justify-center rounded-full bg-[#f4f7fa] text-[#090972] transition hover:bg-[#e7f1f2]"
          >
            <IconoInstagram className="size-4" />
          </a>
        </nav>
      </div>
      <div className="border-t border-[#e1e6ee] py-5 text-center text-xs text-[#5b5f73]">
        © {new Date().getFullYear()} Clínica COSME – CMR. Todos los derechos
        reservados.
      </div>
    </footer>
  );
}

/* ------------------------------------------------------------------------ */

function Etiqueta({ children }: { children: React.ReactNode }) {
  return (
    <p className="text-xs font-semibold uppercase tracking-[0.3em] text-[#62a1a6]">
      {children}
    </p>
  );
}

function IconoWhatsapp({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden className={className}>
      <path d="M12.04 2C6.58 2 2.13 6.45 2.13 11.91c0 1.75.46 3.45 1.32 4.95L2.05 22l5.25-1.38a9.9 9.9 0 0 0 4.74 1.21c5.46 0 9.91-4.45 9.91-9.91S17.5 2 12.04 2Zm0 18.15a8.2 8.2 0 0 1-4.19-1.15l-.3-.18-3.12.82.83-3.04-.2-.31a8.23 8.23 0 1 1 6.98 3.86Zm4.52-6.16c-.25-.12-1.47-.72-1.69-.81-.23-.08-.39-.12-.56.13-.16.25-.64.81-.79.97-.14.17-.29.19-.54.06-.25-.12-1.05-.39-1.99-1.23-.74-.66-1.23-1.47-1.38-1.72-.14-.25-.02-.38.11-.51.11-.11.25-.29.37-.43.13-.15.17-.25.25-.42.08-.17.04-.31-.02-.43-.06-.12-.56-1.34-.76-1.84-.2-.48-.41-.42-.56-.43h-.48c-.17 0-.43.06-.66.31-.23.25-.86.85-.86 2.07 0 1.22.89 2.4 1.01 2.56.12.17 1.75 2.67 4.23 3.74.59.26 1.05.41 1.41.52.59.19 1.13.16 1.56.1.48-.07 1.47-.6 1.67-1.18.21-.58.21-1.07.14-1.18-.06-.1-.22-.16-.47-.28Z" />
    </svg>
  );
}

/** Lucide ya no trae logos de marcas, así que este va dibujado a mano. */
function IconoInstagram({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
      className={className}
    >
      <rect x="3" y="3" width="18" height="18" rx="5" />
      <circle cx="12" cy="12" r="4" />
      <circle cx="17.5" cy="6.5" r="0.6" fill="currentColor" />
    </svg>
  );
}
