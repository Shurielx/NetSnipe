import type { BackendResult, JsonRecord, ProgressEvent } from "../types/api";

type PendingRequest = {
  resolve: (value: BackendResult) => void;
  reject: (reason: Error) => void;
};

type WebViewMessage = {
  type?: string;
  id?: string;
  payload?: BackendResult | ProgressEvent;
};

const pending = new Map<string, PendingRequest>();
const progressListeners = new Set<(event: ProgressEvent) => void>();
const webview = (window as Window & { chrome?: { webview?: { postMessage: (value: unknown) => void; addEventListener: (type: string, listener: (event: MessageEvent) => void) => void } } }).chrome?.webview;

if (webview) {
  webview.addEventListener("message", (event) => {
    const message = event.data as WebViewMessage;
    if (message.type === "progress") {
      progressListeners.forEach((listener) => listener((message.payload ?? {}) as ProgressEvent));
      return;
    }

    if (message.type === "result" && message.id) {
      const request = pending.get(message.id);
      if (!request) return;
      pending.delete(message.id);
      request.resolve((message.payload ?? {}) as BackendResult);
    }
  });
}

export const bridge = {
  available: Boolean(webview),

  run(action: string, args: JsonRecord = {}): Promise<BackendResult> {
    if (!webview) {
      return Promise.reject(new Error("The local desktop bridge is unavailable. Start NetSnipe through run.bat."));
    }

    const id = crypto.randomUUID();
    return new Promise<BackendResult>((resolve, reject) => {
      pending.set(id, { resolve, reject });
      webview.postMessage({ type: "run", id, action, args });
    });
  },

  onProgress(listener: (event: ProgressEvent) => void): () => void {
    progressListeners.add(listener);
    return () => progressListeners.delete(listener);
  },

  cancel(): void {
    webview?.postMessage({ type: "cancel" });
  },
};
