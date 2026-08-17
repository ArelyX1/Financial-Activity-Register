# Admin Register

Panel de administración de Incasur S.A.C. — login animado con Astro + React.

## Stack

- **Astro 7** — framework de contenido
- **React 19** — componentes de UI (vía `@astrojs/react`)

## Dependencias de edición / animación

| Paquete | Versión | Uso |
| :------ | :------ | :--- |
| [`motion`](https://motion.dev) | ^13 | Animaciones del login (logo, morfing de tiles, transiciones) — sucesor de Framer Motion |
| [`gsap`](https://gsap.com) | ^3 | Animaciones avanzadas (scroll, timelines) disponibles para futuras secciones |
| [`three`](https://threejs.org) | ^0.185 | Motor 3D |
| [`@react-three/fiber`](https://r3f.docs.pmnd.rs) | ^9 | Renderer declarativo de Three.js para React |
| [`@react-three/drei`](https://drei.docs.pmnd.rs) | ^10 | Helpers de R3F (partículas, flotación) |
| [`@fontsource-variable/inter`](https://fontsource.org) | ^5 | Fuente `Inter Variable` (cuerpo) |
| [`@fontsource-variable/plus-jakarta-sans`](https://fontsource.org) | ^5 | Fuente `Plus Jakarta Sans Variable` (títulos) |

## Paleta (tema Flutter heredado)

| Token | Valor | Uso |
| :---- | :---- | :--- |
| `--color-primary` | `#CFDC28` | Fondo principal (amarillo lima) |
| `--color-secondary` | `#12667F` | Texto y botones (azul petróleo) |
| `--color-tertiary` | `#C65B5B` | Errores / acentos |
| `--color-on-primary` | `#12667F` | Texto sobre fondo primario |
| `--color-on-secondary` | `#FFFFFF` | Texto sobre botones |

Paleta completa en `src/styles/global.css`.

## Estructura (screaming + hexagonal)

```text
src/
├── pages/
│   └── index.astro                  # composition root
├── styles/
│   └── global.css                   # design tokens + reset
└── login/                           # feature
    ├── domain/login.ts              # entidades + port (AuthenticationPort)
    ├── application/login-service.ts # caso de uso (mock)
    └── adapters/
        └── react/
            ├── Login.tsx            # orquestador (logo → morfing → form)
            ├── Login.module.css     # estilos scoped
            ├── MorphTiles.tsx       # animación de tiles (pop-art)
            └── BackgroundScene.tsx  # fondo 3D (Three.js / R3F)
```

## Comandos

| Comando          | Acción                                  |
| :--------------- | :-------------------------------------- |
| `npm install`    | Instala dependencias                    |
| `npm run dev`    | Dev server en `localhost:4321`          |
| `npm run build`  | Build de producción en `./dist/`        |
| `npm run preview`| Previsualiza el build                   |
