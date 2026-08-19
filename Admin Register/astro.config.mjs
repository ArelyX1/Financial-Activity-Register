// @ts-check
import { defineConfig } from 'astro/config';
import react from '@astrojs/react';

// https://astro.build/config
export default defineConfig({
  integrations: [react()],
  server: {
    host: '0.0.0.0',
  },
  vite: {
    server: {
      allowedHosts: true,
      watch: {
        usePolling: true,
      },
    },
  },
});
