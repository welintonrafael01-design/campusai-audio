import Link from "next/link";
import { Brand } from "./brand";

const footerGroups = [
  {
    title: "Producto",
    links: [
      ["Funciones", "/features"],
      ["Estudiantes", "/students"],
      ["Docentes", "/teachers"],
      ["Planes", "/pricing"],
    ],
  },
  {
    title: "Ayuda",
    links: [
      ["Preguntas frecuentes", "/faq"],
      ["Contacto", "/contact"],
      ["Seguridad", "/security"],
    ],
  },
  {
    title: "Legal",
    links: [
      ["Privacidad", "/privacy"],
      ["Términos", "/terms"],
      ["Eliminar cuenta", "/account-deletion"],
    ],
  },
] as const;

export function Footer() {
  return (
    <footer className="site-footer">
      <div className="container footer-grid">
        <div className="footer-intro">
          <Brand />
          <p>
            Documentos que se convierten en experiencias de aprendizaje claras,
            prácticas y accesibles.
          </p>
        </div>
        {footerGroups.map((group) => (
          <nav aria-label={group.title} key={group.title}>
            <h2>{group.title}</h2>
            {group.links.map(([label, href]) => (
              <Link href={href} key={href}>
                {label}
              </Link>
            ))}
          </nav>
        ))}
      </div>
      <div className="container footer-bottom">
        <p>© {new Date().getFullYear()} StudyBook AI.</p>
        <p>Sitio público en preparación para lanzamiento.</p>
      </div>
    </footer>
  );
}
