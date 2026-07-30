import PageHeader from "../components/PageHeader";
import Panel from "../components/Panel";

type Props = { onStart: () => void; running: boolean };

export default function DnsPage({ onStart, running }: Props) {
  return (
    <>
      <PageHeader eyebrow="MEASURE / 03" title="DNS resolution" description="This is not an ICMP ping test. It asks the DNS servers configured on the active adapter to resolve real domain names and measures their response time." />
      <div className="workspace-grid">
        <Panel className="workspace-main" eyebrow="TEST SCOPE" title="Name resolution, not server latency">
          <div className="step-list"><div><span>01</span><strong>Read configured DNS</strong><p>NetSnipe checks the DNS servers currently configured in Windows.</p></div><div><span>02</span><strong>Resolve representative names</strong><p>cloudflare.com, google.com and microsoft.com are queried through each server.</p></div><div><span>03</span><strong>Compare success and timing</strong><p>The report shows which server answered and how long resolution took.</p></div></div>
          <div className="callout callout-blue"><strong>Different from Custom ping</strong><span>DNS measures the lookup operation. It does not tell us the ICMP latency to a game server or public IP.</span></div>
        </Panel>
        <Panel className="workspace-side" eyebrow="READ-ONLY" title="Ready to test">
          <p className="lead-copy">No DNS setting will be changed. If the computer is offline, the result will show the expected resolution failures instead of hiding them.</p>
          <button className="button button-primary button-wide" disabled={running} onClick={onStart}>{running ? "DNS test running..." : "Start DNS test"}</button>
        </Panel>
      </div>
    </>
  );
}
