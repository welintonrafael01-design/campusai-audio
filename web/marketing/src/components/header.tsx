import Link from "next/link";
import { ArrowRight, Menu } from "lucide-react";
import { accountLinks, primaryNavigation } from "@/config/site";
import { Brand } from "./brand";

export function Header() {
  return (
    <header className="site-header">
      <div className="container header-inner">
        <Brand />
        <nav className="desktop-nav" aria-label="Navegación principal">
          {primaryNavigation.map((item) => (
            <Link href={item.href} key={item.href}>
              {item.label}
            </Link>
          ))}
        </nav>
        <div className="header-actions">
          <a className="header-login" href={accountLinks.login}>
            Iniciar sesión
          </a>
          <a className="button button-small" href={accountLinks.signup}>
            Comenzar gratis
            <ArrowRight aria-hidden="true" size={16} />
          </a>
        </div>
        <details className="mobile-nav">
          <summary aria-label="Abrir navegación">
            <Menu aria-hidden="true" size={23} />
          </summary>
          <nav aria-label="Navegación móvil">
            {primaryNavigation.map((item) => (
              <Link href={item.href} key={item.href}>
                {item.label}
              </Link>
            ))}
            <span className="mobile-nav-divider" aria-hidden="true" />
            <a href={accountLinks.login}>Iniciar sesión</a>
            <a className="mobile-nav-cta" href={accountLinks.signup}>
              Comenzar gratis
            </a>
          </nav>
        </details>
      </div>
    </header>
  );
}
