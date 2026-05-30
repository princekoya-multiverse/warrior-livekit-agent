import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Vite config for the Warrior B.O.S.S. frontend.
// The dev server proxies /api -> token server so the browser can fetch a
// LiveKit join token without CORS headaches during local development.
export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    port: 3000,
    proxy: {
      "/api": {
        target: process.env.TOKEN_SERVER_URL || "http://localhost:8080",
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/api/, ""),
      },
    },
  },
  preview: { host: true, port: 3000 },
});
