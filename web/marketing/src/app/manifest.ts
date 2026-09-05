import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "StudyBook AI",
    short_name: "StudyBook AI",
    description: "Un documento. Todo tu aprendizaje.",
    start_url: "/",
    display: "standalone",
    background_color: "#08152e",
    theme_color: "#08152e",
    icons: [
      {
        src: "/brand-mark.png",
        sizes: "1024x1024",
        type: "image/png",
      },
    ],
  };
}
