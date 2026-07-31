/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_NETSNIPE_VERSION?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
