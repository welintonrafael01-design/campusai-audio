import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Página no encontrada",
};

export default function NotFound() {
  return (
    <section className="status-page">
      <div className="container status-page-inner">
        <p className="eyebrow">Error 404</p>
        <h1>Esta página no está en tu biblioteca.</h1>
        <p>La dirección puede haber cambiado o todavía no estar disponible.</p>
        <Link className="button" href="/">
          Volver al inicio
        </Link>
      </div>
    </section>
  );
}
