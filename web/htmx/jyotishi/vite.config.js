import { defineConfig } from "vite";

export default defineConfig({
  // Proxy API calls to the Hono backend during development
  server: {
    port: 5173,
    proxy: {
      "/api": {
        target: "http://localhost:3000",
        changeOrigin: true,
      },
    },
  },
  // In production, Hono serves the built dist directly
  build: {
    outDir: "dist",
    emptyOutDir: true,
  },
});
