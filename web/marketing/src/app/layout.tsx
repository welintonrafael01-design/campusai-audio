import type { Metadata, Viewport } from "next";
import { Footer } from "@/components/footer";
import { Header } from "@/components/header";
import { StructuredData } from "@/components/structured-data";
import { isPreviewDeployment, siteConfig } from "@/config/site";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(siteConfig.urls.web),
  title: {
    default: "StudyBook AI | Un documento. Todo tu aprendizaje.",
    template: "%s | StudyBook AI",
  },
  description: siteConfig.description,
  applicationName: siteConfig.name,
  alternates: { canonical: "/" },
  openGraph: {
    type: "website",
    locale: "es_DO",
    url: siteConfig.urls.web,
    siteName: siteConfig.name,
    title: "StudyBook AI | Un documento. Todo tu aprendizaje.",
    description: siteConfig.description,
  },
  twitter: {
    card: "summary",
    title: "StudyBook AI",
    description: siteConfig.description,
  },
  icons: { icon: "/brand-mark.png", apple: "/brand-mark.png" },
  robots: isPreviewDeployment
    ? {
        index: false,
        follow: false,
        noarchive: true,
        nocache: true,
      }
    : undefined,
};

export const viewport: Viewport = {
  colorScheme: "dark",
  themeColor: "#08152e",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="es">
      <body>
        <a className="skip-link" href="#main-content">
          Saltar al contenido
        </a>
        <StructuredData />
        <Header />
        <main id="main-content">{children}</main>
        <Footer />
      </body>
    </html>
  );
}
