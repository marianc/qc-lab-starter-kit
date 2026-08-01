import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    allowedHosts: true,
    proxy: {
      '/api': {
        target: 'http://localhost:5010', // blazor, dotnetapi
        // target: 'http://localhost:5000', // express, go
        // target: 'http://localhost:8080', // spring boot
        // target: 'http://localhost:8000', // fastapi
        changeOrigin: true,
        secure: false,
      },
    },
  },
})
