#!/usr/bin/env node
// Peer105 YouTube Transcript Fetcher
// Usage: node /root/peer105-fetch-transcript.mjs <videoId> [outputDir]
// Default video: Top SBC Picks in 2026 — ties into peer106's ARM SBC research

import { YoutubeTranscript } from 'youtube-transcript';
import { writeFileSync } from 'fs';
import { join } from 'path';

const videoId = process.argv[2] || 'StYdYsPAp_g';
const outputDir = process.argv[3] || '/tmp/peer105';

async function main() {
  console.error(`[peer105] Fetching transcript for video: ${videoId}`);
  console.error(`[peer105] URL: https://www.youtube.com/watch?v=${videoId}`);
  
  const segments = await YoutubeTranscript.fetchTranscript(videoId);
  
  // Build clean text (no timestamps)
  const cleanText = segments
    .map(s => s.text.replace(/&#39;/g, "'").replace(/&amp;/g, "&").replace(/&quot;/g, '"'))
    .join(' ')
    .replace(/\s+/g, ' ')
    .trim();
  
  const result = {
    videoId,
    url: `https://www.youtube.com/watch?v=${videoId}`,
    fetchedAt: new Date().toISOString(),
    segmentCount: segments.length,
    charCount: cleanText.length,
    segments: segments.map(s => ({ text: s.text, duration: s.duration, offset: s.offset })),
    cleanText
  };

  // Ensure output dir
  try { writeFileSync(join(outputDir, '.exists'), ''); } catch {}
  
  // Write full JSON
  const jsonPath = join(outputDir, `transcript-${videoId}.json`);
  writeFileSync(jsonPath, JSON.stringify(result, null, 2));
  
  // Write clean text
  const txtPath = join(outputDir, `transcript-${videoId}.txt`);
  writeFileSync(txtPath, cleanText);
  
  console.error(`[peer105] JSON: ${jsonPath} (${result.segmentCount} segments)`);
  console.error(`[peer105] Text: ${txtPath} (${result.charCount} chars)`);
  
  // Print summary to stdout for parsing
  console.log(JSON.stringify({
    status: 'ok',
    videoId,
    url: result.url,
    segments: result.segmentCount,
    chars: result.charCount,
    snippet: cleanText.substring(0, 200) + '...'
  }));
}

main().catch(err => {
  console.error(`[peer105] ERROR: ${err.message}`);
  process.exit(1);
});
