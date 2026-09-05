import Link from "next/link";
import { accountLinks } from "@/config/site";
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
    title: "Recursos",
    links: [
      ["Cómo funciona", "/#como-funciona"],
      ["Preguntas frecuentes", "/faq"],
      ["Seguridad", "/security"],
      ["Contacto", "/contact"],
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
        <nav aria-label="Cuenta">
          <h2>Cuenta</h2>
          <a href={accountLinks.login}>Iniciar sesión</a>
          <a href={accountLinks.signup}>Crear cuenta</a>
        </nav>
      </div>
      <div className="container footer-bottom">
        <p>© 2026 StudyBook AI. Todos los derechos reservados.</p>
        <p>Aprendizaje y enseñanza, conectados por IA.</p>
      </div>
    </footer>
  );
}
