/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_TEMPO_URL?: string
  readonly MODE: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
