const { YoutubeTranscript } = require("youtube-transcript");
const { writeFileSync, existsSync, mkdirSync } = require("fs");
const { join } = require("path");

const videoId = process.argv[2] || "StYdYsPAp_g";
const outputDir = process.argv[3] || "/tmp/peer105";
const outBase = join(outputDir, "transcript-" + videoId);

async function main() {
  console.error("[peer105] Fetching transcript for video:", videoId);
  console.error("[peer105] URL: https://www.youtube.com/watch?v=" + videoId);

  const segments = await YoutubeTranscript.fetchTranscript(videoId);
  console.error("[peer105] Fetched", segments.length, "segments");

  const cleanText = segments
    .map(s => s.text.replace(/&#39;/g, "'").replace(/&amp;/g, "&").replace(/&quot;/g, '"'))
    .join(" ")
    .replace(/\s+/g, " ")
    .trim();

  if (!existsSync(outputDir)) mkdirSync(outputDir, { recursive: true });

  writeFileSync(outBase + ".json", JSON.stringify({
    videoId,
    url: "https://www.youtube.com/watch?v=" + videoId,
    fetchedAt: new Date().toISOString(),
    segmentCount: segments.length,
    charCount: cleanText.length,
    segments: segments.map(s => ({ text: s.text, duration: s.duration, offset: s.offset }))
  }, null, 2));

  writeFileSync(outBase + ".txt", cleanText);

  console.log(JSON.stringify({
    status: "ok",
    videoId,
    url: "https://www.youtube.com/watch?v=" + videoId,
    segments: segments.length,
    chars: cleanText.length
  }));
}

main().catch(err => {
  console.error("[peer105] ERROR:", err.message);
  process.exit(1);
});
