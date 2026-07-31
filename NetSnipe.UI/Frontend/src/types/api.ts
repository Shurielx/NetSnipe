export type JsonRecord = Record<string, unknown>;

export type StatusData = {
  adapter?: string;
  description?: string;
  status?: string;
  link_speed?: string;
  gateway?: string;
  signal?: number | string;
  band?: string;
  channel?: string;
  backup_count?: number | string;
};

export type Target = {
  id: string;
  name: string;
  address: string;
};

export type Measurement = {
  target?: string;
  sent?: number;
  received?: number;
  loss_percent?: number;
  min_ms?: number | null;
  average_ms?: number | null;
  max_ms?: number | null;
  median_ms?: number | null;
  p95_ms?: number | null;
  jitter_ms?: number | null;
  samples?: LatencySample[];
};

export type LatencySample = {
  elapsed_seconds?: number;
  latency_ms?: number | null;
};

export type BackendResult = {
  action?: string;
  success?: boolean;
  data?: JsonRecord | null;
  error?: string | null;
  report_json?: string;
  report_html?: string;
};

export type ProgressEvent = {
  action?: string;
  target?: string;
  elapsed_seconds?: number;
  total_seconds?: number;
  sent?: number;
  received?: number;
  loss_percent?: number;
  last_latency_ms?: number | null;
};
