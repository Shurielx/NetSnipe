import { useState } from "react";
import PageHeader from "../components/PageHeader";
import Panel from "../components/Panel";
import type { StatusData, Target } from "../types/api";

type Props = { status: StatusData; targets: Target[]; onAddTarget: (name: string, address: string) => Promise<boolean>; onStart: (target: string, rate: number, seconds: number) => void; running: boolean };

export default function PingPage({ status, targets, onAddTarget, onStart, running }: Props) {
  const gateway = String(status.gateway ?? "");
  const [target, setTarget] = useState("__GATEWAY__");
  const [custom, setCustom] = useState("");
  const [rate, setRate] = useState("2");
  const [seconds, setSeconds] = useState("30");
  const [name, setName] = useState("");
  const [address, setAddress] = useState("");
  const [adding, setAdding] = useState(false);
  const [message, setMessage] = useState("");

  const selectedTarget = target === "__CUSTOM__" ? custom.trim() : target;
  const submitTarget = async () => {
    if (!name.trim() || !address.trim()) return;
    setAdding(true);
    const saved = await onAddTarget(name.trim(), address.trim());
    setMessage(saved ? "Target saved to the local target library." : "Target could not be saved.");
    if (saved) { setName(""); setAddress(""); }
    setAdding(false);
  };

  return (
    <>
      <PageHeader eyebrow="MEASURE / 02" title="Custom latency test" description="A normal ICMP echo test for exactly one target. Use it for your router, a known game-related host or any hostname/IP you want to compare." />
      <div className="workspace-grid">
        <Panel className="workspace-main" eyebrow="TARGET" title="Choose what to ping">
          <label className="field-label">Saved or built-in target<select className="field-input select-input" value={target} onChange={(event) => setTarget(event.target.value)}><option value="__GATEWAY__">Router / gateway {gateway ? `(${gateway})` : "(not detected)"}</option>{targets.map((item) => <option key={item.id} value={item.address}>{item.name} ({item.address})</option>)}<option value="__CUSTOM__">Enter a hostname or IP...</option></select></label>
          {target === "__CUSTOM__" && <label className="field-label">Hostname or IP<input className="field-input" value={custom} onChange={(event) => setCustom(event.target.value)} placeholder="example.server.net or 203.0.113.20" /></label>}
          <div className="form-grid"><label className="field-label">Pings per second<input className="field-input" type="number" min="1" max="10" value={rate} onChange={(event) => setRate(event.target.value)} /></label><label className="field-label">Duration (seconds)<input className="field-input" type="number" min="5" max="900" value={seconds} onChange={(event) => setSeconds(event.target.value)} /></label></div>
          <button className="button button-primary button-wide" disabled={running || !selectedTarget || selectedTarget === "__GATEWAY__" && !gateway} onClick={() => onStart(selectedTarget, Math.max(1, Math.min(10, Number(rate) || 2)), Math.max(5, Math.min(900, Number(seconds) || 30)))}>{running ? "Ping running..." : "Start custom ping"}</button>
          <div className="callout callout-amber"><strong>Safety limit</strong><span>NetSnipe caps this test at 10 pings per second. Some game and cloud hosts block or rate-limit ICMP. There is no automatic server discovery.</span></div>
        </Panel>
        <Panel className="workspace-side" eyebrow="TARGET LIBRARY" title="Add custom target">
          <p className="field-help">Save a friendly name and address so the target is available next time. Saving does not ping or validate the host.</p>
          <label className="field-label">Display name<input className="field-input" value={name} onChange={(event) => setName(event.target.value)} placeholder="CS2 Frankfurt" /></label>
          <label className="field-label">Hostname or IP<input className="field-input" value={address} onChange={(event) => setAddress(event.target.value)} placeholder="server.example.net" /></label>
          <button className="button button-outline button-wide" disabled={adding || !name.trim() || !address.trim()} onClick={submitTarget}>{adding ? "Saving..." : "Add custom target"}</button>
          {message && <div className="inline-message">{message}</div>}
           <p className="safety-copy">Targets are stored locally in the NetSnipe user data folder.</p>
        </Panel>
      </div>
    </>
  );
}
