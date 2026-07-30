import { bridge } from "./bridge";
import type { BackendResult, JsonRecord } from "../types/api";

export const api = {
  run(action: string, args?: JsonRecord): Promise<BackendResult> {
    return bridge.run(action, args);
  },
  status: () => bridge.run("Status"),
  targets: () => bridge.run("ListTargets"),
  monitorStatus: () => bridge.run("MonitorStatus"),
};
