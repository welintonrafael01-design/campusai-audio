import Link from "next/link";
import { ArrowUpRight, Menu } from "lucide-react";
import { primaryNavigation, siteConfig } from "@/config/site";
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
        <a className="button button-small" href={siteConfig.urls.app}>
          Abrir la app
          <ArrowUpRight aria-hidden="true" size={17} />
        </a>
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
            <a href={siteConfig.urls.app}>Abrir la app</a>
          </nav>
        </details>
      </div>
    </header>
  );
}
