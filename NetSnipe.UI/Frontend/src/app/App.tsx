import { useEffect, useState } from "react";
import AppShell, { type Page } from "../components/AppShell";
import ProgressPanel from "../components/ProgressPanel";
import ResultSummary, { asRecord } from "../components/ResultSummary";
import DashboardPage from "../pages/DashboardPage";
import DiagnosticsPage from "../pages/DiagnosticsPage";
import PingPage from "../pages/PingPage";
import DnsPage from "../pages/DnsPage";
import BufferbloatPage from "../pages/BufferbloatPage";
import ProfilesPage from "../pages/ProfilesPage";
import MonitorPage from "../pages/MonitorPage";
import { api } from "../services/api";
import { bridge } from "../services/bridge";
import type { BackendResult, JsonRecord, ProgressEvent, StatusData, Target } from "../types/api";

function asTargets(result: BackendResult | null): Target[] {
  const data = asRecord(result?.data);
  return Array.isArray(data.targets) ? data.targets as Target[] : [];
}

export default function App() {
  const [page, setPage] = useState<Page>("dashboard");
  const [status, setStatus] = useState<StatusData>({});
  const [targets, setTargets] = useState<Target[]>([]);
  const [monitorRunning, setMonitorRunning] = useState(false);
  const [monitorLatest, setMonitorLatest] = useState("");
  const [running, setRunning] = useState(false);
  const [activeAction, setActiveAction] = useState("");
  const [progress, setProgress] = useState<ProgressEvent | null>(null);
  const [result, setResult] = useState<BackendResult | null>(null);
  const [error, setError] = useState("");

  useEffect(() => bridge.onProgress(setProgress), []);

  const refreshStatus = async () => {
    try {
      const response = await api.status();
      if (response.success) setStatus(asRecord(response.data) as StatusData);
      else setError(response.error ?? "Status refresh failed.");
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Status bridge unavailable.");
    }
  };

  const refreshTargets = async () => {
    try {
      const response = await api.targets();
      if (response.success) setTargets(asTargets(response));
    } catch { /* The main error is shown by the status call when the bridge is unavailable. */ }
  };

  const refreshMonitor = async () => {
    try {
      const response = await api.monitorStatus();
      const data = asRecord(response.data);
      setMonitorRunning(Boolean(data.running));
      const latest = await api.run("MonitorLatest");
      const latestData = asRecord(latest.data);
      setMonitorLatest(String(latestData.latest ?? ""));
    } catch { /* A stopped monitor or unavailable bridge is represented by the page state. */ }
  };

  useEffect(() => {
    const bootstrap = async () => {
      await refreshStatus();
      await refreshTargets();
      await refreshMonitor();
    };
    void bootstrap();
  }, []);

  const execute = async (action: string, args: JsonRecord = {}, title = action): Promise<BackendResult | null> => {
    setRunning(true);
    setActiveAction(action);
    setProgress(null);
    setResult(null);
    setError("");
    try {
      const response = await api.run(action, args);
      setResult(response);
      if (!response.success) setError(response.error ?? `${title} failed.`);
      if (action === "Status" && response.success) setStatus(asRecord(response.data) as StatusData);
      if (action === "ListTargets" && response.success) setTargets(asTargets(response));
      if (action === "AddTarget" && response.success) await refreshTargets();
      if (action === "RemoveTarget") await refreshTargets();
      if (action === "StartMonitor" || action === "StopMonitor" || action === "MonitorStatus") await refreshMonitor();
      if (["ApplyProfile", "OptimizeProfile", "RestoreLatest"].includes(action)) await refreshStatus();
      return response;
    } catch (cause) {
      const message = cause instanceof Error ? cause.message : `${title} failed.`;
      setError(message);
      setResult({ action, success: false, error: message });
      return null;
    } finally {
      setRunning(false);
    }
  };

  const addTarget = async (name: string, address: string) => {
    const response = await execute("AddTarget", { TargetName: name, TargetAddress: address }, "Add custom target");
    return Boolean(response?.success);
  };

  const applyProfile = async (profile: string, channelWidth: string) => {
    const accepted = window.confirm(`Create a backup and apply the ${profile} profile?\n\nNo settings are changed if you cancel.`);
    if (!accepted) return;
    if (profile === "Gaming Balanced") {
      await execute("OptimizeProfile", { Profile: profile, ChannelWidth: channelWidth, DiagnosticSeconds: 15 }, "Gaming profile measurement");
    } else {
      await execute("ApplyProfile", { Profile: profile, ChannelWidth: channelWidth }, "Apply profile");
    }
  };

  const pageContent = () => {
    switch (page) {
      case "diagnostics": return <DiagnosticsPage running={running && activeAction === "Diagnostics"} onStart={(seconds) => void execute("Diagnostics", { DiagnosticSeconds: seconds }, "Diagnostics")} />;
      case "ping": return <PingPage status={status} targets={targets} running={running && activeAction === "PingTest"} onAddTarget={addTarget} onStart={(target, rate, seconds) => void execute("PingTest", { PingTarget: target, PingRate: rate, PingSeconds: seconds }, "Custom ping")} />;
      case "dns": return <DnsPage running={running && activeAction === "DnsTest"} onStart={() => void execute("DnsTest", {}, "DNS test")} />;
      case "bufferbloat": return <BufferbloatPage running={running && activeAction === "Bufferbloat"} onStart={(downloadMb, seconds) => void execute("Bufferbloat", { BufferbloatDownloadMb: downloadMb, BufferbloatSeconds: seconds }, "Bufferbloat test")} />;
      case "profiles": return <ProfilesPage running={running && (activeAction === "ApplyProfile" || activeAction === "OptimizeProfile")} onApply={applyProfile} />;
      case "monitor": return <MonitorPage running={monitorRunning} latest={monitorLatest} onRefresh={() => void refreshMonitor()} onStart={() => void execute("StartMonitor", {}, "Start monitor")} onStop={() => void execute("StopMonitor", {}, "Stop monitor")} />;
      default: return <DashboardPage status={status} targets={targets} monitorRunning={monitorRunning} onRefresh={() => void refreshStatus()} onOpen={setPage} />;
    }
  };

  return (
    <AppShell page={page} onNavigate={setPage} adapter={String(status.adapter ?? "Detecting...")} status={error ? "Attention" : running ? "Running" : "Ready"}>
      {pageContent()}
      {error && <div className="global-error"><strong>Action unavailable</strong><span>{error}</span></div>}
      {running && <ProgressPanel progress={progress} running onCancel={() => bridge.cancel()} />}
      {!running && result && <div className="operation-result"><ResultSummary result={result} action={activeAction} /></div>}
    </AppShell>
  );
}
