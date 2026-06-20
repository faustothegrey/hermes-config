# Dual-Peer Autonomous Loop Protocol

Full protocol for cron-driven dual-peer advancement. This is the master document that the orchestrator cron job follows.

## Protocol

```
1. READ both project notes (Obsidian Markdown, one per peer)
2. READ the Research Queue (Hermes/Research Queue.md) — consume one item per peer
3. CHECK health of both peers (mcp_hermes_peers + heartbeat logs)
4. DECIDE — pick ONE small step for EACH peer
5. EXECUTE both steps (SSH for deployment, call_peer for API-level tasks)
6. **VERIFY peer side-effects — do not trust self-reports.** After a peer says "file created at path X", confirm via the appropriate method: shared filesystem → `read_file`/`ls -la` locally; separate host → check `get_peer_run` output for explicit success evidence. See "Peer self-reports" pitfall below for details.
7. DOCUMENT both in their Obsidian notes (Operation Log section)
8. ARCHIVE to Knowledge Base — write Obsidian note in Hermes/Knowledge/ (use absolute path `/home/fausto/Documents/Obsidian Vault/Hermes/Knowledge/`)
9. UPDATE Research Queue — mark consumed items
10. SEND ONE RECAP EMAIL covering both peers via himalaya (retry once on transient DNS failure)
11. SELF-REGULATE — one step per peer per wake-up
```

## Call for content (Research Queue)

The user provides input via an Obsidian Markdown file: `[[Hermes/Research Queue.md]]`. The loop reads this file at every tick before deciding what to do.

### Queue format

```markdown
## Da fare

- [ ] https://www.youtube.com/watch?v=VIDEO_ID — descrizione del video
- [ ] web "query di ricerca da eseguire"
- [ ] web "altra query"

## In corso

- [ ] ...

## Completati

- [x] web "già fatto"
```

- `https://www.youtube.com/watch?v=...` → peer105: fetch transcript via Node.js, produce digest
- `web "query"` → peer106 (or orchestrator fallback): web_search → web_extract → summary
- One item consumed per tick. If both types available in the queue, the loop alternates.
- Item gets moved from "Da fare" → "In corso" at start of execution → "[x]" in "Completati" on success.
- If the queue is empty, the loop continues with autonomous initiative: finding videos via search, choosing research topics independently.

### Queue empty-state detection

When the Research Queue's "Da fare" section contains only:
```markdown
- [ ] ...
```
that is a **placeholder ellipsis**, not a genuine task. Skip it and proceed with autonomous initiative. Do not attempt to process it.

To detect emptiness programmatically:
```python
import re
da_fare_items = re.findall(r'- \[ \] (.+)', queue_text)
genuine_items = [i for i in da_fare_items if i.strip() != '...']
if not genuine_items:
    print("QUEUE_EMPTY")
```

### Autonomous initiative — finding content when queue is empty

When the queue is empty, both peers need topics chosen autonomously. Use this decision tree:

**For Peer105 (find a video):**
1. Consider the running theme from previous sessions (e.g., SBCs, RISC-V, edge AI)
2. Search for YouTube videos: `web_search("topic YouTube review 2026")` — pick terms that match the existing doc trail
3. From results, find the video that's most review/analysis oriented (avoid short clips, trailers)
4. Verify transcript availability on peer105: `ssh root@192.168.178.105 "node -e '...fetchTranscript(videoId)...'"`
5. Only proceed if transcript returns OK with segments

**For Peer106 (choose a research topic):**
1. Best approach: **complement peer105's topic**. If peer105 just processed a RISC-V video, research the RISC-V SBC ecosystem from web sources
2. Second best: continue the running theme (SBC market, edge AI, embedded ML)
3. Third: search for a new connected topic that bridges to the next possible video topic

**Autonomous content pipeline (demonstrated in Loop #5):**
```
peer105: "RISC-V 2026 Update" video → digest with RVA23, K3, Jupiter 2
peer106: RISC-V SBC ecosystem research → Milk-V Jupiter 2 specs, ARM/x86/RISC-V comparison
→ Both notes reciprocally backlinked in Knowledge Base
```

### fetch.cjs output directory quirk

The Node.js fetcher script (`/root/transcript-worker/fetch.cjs`) uses its third argument as a **directory path**, not a file path. When calling:

```bash
cd /root/transcript-worker && node fetch.cjs <VIDEO_ID> /tmp/peer105
```

The output is:
```
/tmp/peer105/
  transcript-<VIDEO_ID>.json
  transcript-<VIDEO_ID>.txt
```

If you pass a path that looks like a filename (e.g., `/tmp/peer105/riscv2026_raw.json`), the script creates it as a **directory** (via `mkdirSync({recursive: true})`) and writes the transcripts *inside* it:

```
/tmp/peer105/riscv2026_raw.json/           ← this is a directory!
  transcript-z6gHC-R59lw.json
  transcript-z6gHC-R59lw.txt
```

**Always pass a directory path as the third argument**, then read the `.txt` file from inside it. Use `ls -la` on the output dir to discover the actual filenames if unsure. The `.txt` file contains the clean joined transcript text (14K+ chars typical for a full video). The `.json` file has segments with timestamps.

### Pace / speed limits

- **Peer105 (YouTube)**: max 3-4 videos per day total (across all ticks). No batch transcript fetches.
- **Peer106 (Web research)**: max ~10 articles analyzed per day. One web_search + web_extract per tick is ideal.
- **No stress tests. No batch processing. No heavy load.** These are tiny ARM machines that swap at idle.
- Each tick does ONE small step per peer — a single video transcript, a single web query. Never queue up multiple items in one tick.
- **cron job schedule**: `0 6,10,14,18,22 * * *` (every 4 hours, starting at 06:00). This gives each peer ~4h between ticks to recover from swap.

## Recap email

### Primary method (himalaya)

```bash
cat /tmp/peers-recap-N.eml | himalaya message send --account virgilio -- --
```

**Pitfall — `--account` position**: `--account` must go BEFORE the subcommand: `himalaya message send --account virgilio -- --`. Placing it after `message send` fails with `unexpected argument '--account'`.

**Pitfall — DNS/IMAP dependency**: himalaya attempts to connect to the IMAP server (imap.virgilio.it) before sending, even for SMTP-only operations. If DNS fails temporarily (transient `failed to lookup address information`), the send command fails even though the SMTP server is reachable. A retry often works, but for deterministic delivery use the Python fallback below.

### Fallback method (Python SMTP_SSL)

Use when himalaya is unreachable or DNS is flaky. A script lives under this skill at `scripts/send-recap-email.py`:

```bash
python3 /path/to/send-recap-email.py /tmp/peers-recap-N.eml \
  "Peers Loop #N — HH:MM CEST (OK)" \
  fausto.lelli@gmail.com
```

The script reads credentials from `~/.config/himalaya/virgilio.pass` and sends via SMTP_SSL on smtp.virgilio.it:465 with zero external dependencies.

Inline fallback (when the script path is unknown):

```python
python3 -c "
import smtplib, ssl
from email.mime.text import MIMEText
pw = open('/home/fausto/.config/himalaya/virgilio.pass').read().strip()
body = open('/tmp/peers-recap-N.eml').read()
msg = MIMEText(body)
msg['Subject'] = 'Peers Loop #N — HH:MM CEST (OK)'
msg['From'] = 'fausto.lelli@virgilio.it'
msg['To'] = 'fausto.lelli@gmail.com'
with smtplib.SMTP_SSL('smtp.virgilio.it', 465, context=ssl.create_default_context()) as s:
    s.login('fausto.lelli@virgilio.it', pw)
    s.send_message(msg)
"
```

## Operation Log format (Obsidian)

Under `## Operation Log` / `### YYYY-MM-DD`:
`- HH:MM TZ — **Run #N.** action description. Outcome. Next step.`

Keep entries concise — one line per run.

## Peer health check

```python
# Via MCP
mcp_hermes_peers peer_health peer=peer105
mcp_hermes_peers peer_health peer=peer106

# Heartbeat logs (last 5 entries)
~/.hermes/peer-monitor/peer105-health.jsonl
~/.hermes/peer-monitor/peer106-health.jsonl
```

## Pitfalls

### Peer self-reports are not verified facts

**Always verify side-effects after delegation returns.** Both peer105 and peer106 can return "file created and verified" while the file does not exist where expected.

**Two filesystem scenarios:**

1. **Shared filesystem** (peers on the same machine, or NFS/SSHFS mount) — Use `read_file` or `ls -la` on the orchestrator to confirm the file exists locally.

2. **Separate physical hosts** (peers at different IPs) — Each peer has its own filesystem. A file created on peer106 cannot be stat'd from the orchestrator's shell. **Verify via `get_peer_run` output instead.** The `output` field of a completed run contains the peer's final message — look for explicit success evidence like `"Nota creata: Projects/Something/..."` or `"Research Queue aggiornata"`. If the output lacks a verifiable outcome (e.g., only a generic "done"), re-run the task with the instruction to include the created file path in the final message.

   To monitor progress mid-run on long tasks (3+ minutes), use `get_peer_events` to see which tools the peer has started/completed without waiting for full completion:

   ```
   mcp_hermes_peers get_peer_events peer=peer106 run_id=RUN_ID max_events=5
   ```

   Events include tool name, preview, duration, and error status — enough to know whether the peer is stuck or making headway.

### Delegation instructions must use explicit absolute paths

When instructing a peer to create an Obsidian note, use the full absolute path `/home/fausto/Documents/Obsidian Vault/Hermes/Knowledge/` — not a relative or project-specific alias. Peers may interpret relative paths differently or write to a non-existent subdirectory without error.

**Verification when the peer is on a separate host:** Instead of a local `ls -la` (which will fail because the file is on the peer's machine), include an instruction in the delegation prompt asking the peer to "confirm the file path in your final response." The `get_peer_run` output will then contain the verifiable path. Do NOT rely on `ls -la` from the orchestrator shell for files on other machines.

### Research Queue and peer105 both writing the same file

When both peers are asked to update `Research Queue.md`, only one should be responsible for the queue update — do not instruct both peers to mark items as done. Have the orchestrator update the queue after verification.

## Decision rules

- If peer is DOWN: diagnose only, skip its task, report in email
- One step per peer per wake-up. No rushing.
- Marathon, not sprint. Steady, slow progress.
- Never break things. Diagnosis first, action second.
- Respect watchdogs — don't manually restart unless truly needed

## Constraints for very old ARM peers

- Fedora 30 aarch64, very low RAM, swap easily
- Free-tier LLM → transient 401s expected (quota exhaustion), not emergencies
- Watchdogs handle gateway-down restarts on both peers
- Python 3.7 on Fedora 30 can't run modern yt-dlp → install Python 3.9+ via dnf/pyenv
- pip install --no-deps to skip C extension deps (pycryptodomex, brotli) when gcc unavailable
- Prefer SSH for deployments, call_peer only for lightweight API queries
- dnf install can time out (180s+) on low-RAM peers — use pip with --no-deps as lighter alternative

## yt-dlp on Python 3.7 pitfall

yt-dlp 2023.11.16 is the last version for Python 3.7 but YouTube's API rejects it:
- `player_client=web`: transcript listing works, download fails (video format sb0 = images only)
- `player_client=android/ios`: HTTP 400 "Precondition check failed"
- `youtube-transcript-api 0.6.2`: returns empty XML from YouTube

**Fix A**: Install Python 3.9+ on the peer via dnf/pyenv. Heavy on low-RAM ARM (compilation).

**Fix B (preferred for constrained peers)**: Use Node.js `youtube-transcript` npm package (v1.3.1+). It uses its own HTTP fetching, bypassing Python and yt-dlp entirely. Confirmed working on Fedora 30 ARM aarch64 with Python 3.7.

### Node.js transcript fetcher — full script deployment

The one-liner test is useful but for batch processing, deploy a proper script:

1. On peer105, create a working directory and install the package locally:
```bash
mkdir -p /root/transcript-worker
cd /root/transcript-worker
npm init -y
npm install youtube-transcript@1.3.1 --save
```

2. Write a CJS script (`/root/transcript-worker/fetch.cjs`):
```js
const { YoutubeTranscript } = require("youtube-transcript");
const { writeFileSync, existsSync, mkdirSync } = require("fs");
const { join } = require("path");

const videoId = process.argv[2] || "DEFAULT_VIDEO_ID";
const outputDir = process.argv[3] || "/tmp/peer105";
const outBase = join(outputDir, "transcript-" + videoId);

async function main() {
  const segments = await YoutubeTranscript.fetchTranscript(videoId);
  const cleanText = segments
    .map(s => s.text.replace(/&#39;/g, "'").replace(/&amp;/g, "&").replace(/&quot;/g, '"'))
    .join(" ")
    .replace(/\s+/g, " ")
    .trim();

  if (!existsSync(outputDir)) mkdirSync(outputDir, { recursive: true });

  writeFileSync(outBase + ".json", JSON.stringify({
    videoId, url: "https://www.youtube.com/watch?v=" + videoId,
    fetchedAt: new Date().toISOString(),
    segmentCount: segments.length, charCount: cleanText.length,
    segments: segments.map(s => ({ text: s.text, duration: s.duration, offset: s.offset }))
  }, null, 2));

  writeFileSync(outBase + ".txt", cleanText);
}

main().catch(err => { console.error(err.message); process.exit(1); });
```

3. Run from the local directory:
```bash
cd /root/transcript-worker && node fetch.cjs <VIDEO_ID> /tmp/peer105
```

Output: `transcript-<VIDEO_ID>.json` (full JSON with segments) and `transcript-<VIDEO_ID>.txt` (clean text only).

## call_peer timeout on resource-constrained peers

`call_peer` on a free-tier peer with very low RAM (e.g. 2GB total, swapping at baseline) will time out on complex multi-step tasks. The peer's Hermes agent needs to think, call tools, process results — all while swapping. This typically times out at the default 120s limit.

**Workaround**: Route tool work through the orchestrator instead. The orchestrator has full web_search, web_extract, and processing capability. The peer's role becomes:
- Execute SSH commands for file operations (copy, run scripts)
- Store output files locally
- For research-heavy tasks, the orchestrator does web_search/web_extract directly

```python
# DON'T (times out on constrained peer):
call_peer(peer="peer106", input="Search for X, extract Y, summarize")

# DO (orchestrator does the work):
results = web_search("X")
extract = web_extract(results[0].url)
summary = produce_summary(extract)
```

## Structured digest format

When producing a video digest from a transcript, use this structured JSON shape:

```json
{
  "title": "Video Title",
  "video_url": "https://www.youtube.com/watch?v=VIDEO_ID",
  "source": "Channel Name / Author",
  "summary": "2-3 sentence summary of the video thesis",
  "key_concepts": [
    "Concept 1: short explanation",
    "Concept 2: short explanation"
  ],
  "keywords": "keyword1, keyword2, keyword3, ...",
  "buyer_takeaway": "Actionable advice for the target audience",
  "boards_mentioned": ["Board A", "Board B"]
}
```

This format is compact, parseable, and suitable for both Obsidian and email inclusion.

## Knowledge Base archival (Hermes/Knowledge/)

After producing a digest (video or research), archive it as an Obsidian note in `/home/fausto/Documents/Obsidian Vault/Hermes/Knowledge/`.

### Template (video digest)

Use the template at `Hermes/Knowledge/.template-digest.md`:

```yaml
---
source: "peer105"
type: "digest"
video_id: ""
topic: ""
tags: []
date_processed: "{{date}}"
---
```

Frontmatter fields: `source` (peer105/peer106), `type` (digest/research), `video_id` (YouTube ID for digests), `topic`, `tags`, `date_processed`.

### File naming convention

- Video digest: `YYYY-MM-DD — Title.md`
- Research note: `YYYY-MM-DD — Research — Topic.md`

### Note structure

Video digest note:
- Summary, Key Concepts (numbered list or table), Boards Mentioned (table), Keywords (comma-separated), Takeaway
- Backlink a eventuali ricerche correlate: `- [[Hermes/Knowledge/YYYY-MM-DD — Research — Topic.md]]`

Research note:
- Query, Key Findings (bullets), Benchmarks (table if applicable), Key Takeaways
- Backlink al video digest originale: `- [[Hermes/Knowledge/YYYY-MM-DD — Title.md]]`

### Rolling window on peer105

Peer105 keeps only the last 7 days of digests locally in `~/transcript-worker/digests/`:
```bash
find ~/transcript-worker/digests/ -mtime +7 -delete
```
This runs on every loop tick as part of the archival step.

### Template file

Stored at `Hermes/Knowledge/.template-digest.md` — the cron loop uses its structure to format new entries.

## Cross-peer video→research validation pattern

When peer105 processes a YouTube video that makes claims about a product/topic, peer106 can independently validate:

1. peer105: fetch transcript → produce digest (identifying key claims/products)
2. orchestrator: note the topic(s) from the digest
3. peer106 (or orchestrator fallback): search for independent reviews/specs of the same topic
4. Compare: does the video's claims match independent research?
5. Document in peer106's Operation Log as cross-peer work

This is a Phase 3 pattern that can start as early as Phase 1 once both peers have basic capability.
