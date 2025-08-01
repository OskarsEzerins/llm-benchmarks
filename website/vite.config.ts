import { reactRouter } from "@react-router/dev/vite";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";
import tsconfigPaths from "vite-tsconfig-paths";
import { resolve } from 'path';

export default defineConfig({
  plugins: [tailwindcss(), reactRouter(), tsconfigPaths()],
  publicDir: 'public',
  server: {
    fs: {
      allow: ['..']
    }
  },
  build: {
    rollupOptions: {
      external: []
    }
  },
  // Copy data files from the parent results directory
  assetsInclude: ['**/*.json']
});
