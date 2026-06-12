---
name: media-content-production
description: "Media workflows: GIF search, YouTube transcripts, audio analysis, songwriting, AI music, ASCII video, Manim, and animation pipelines."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [media, youtube, gifs, audio, music, video, manim, ascii-video]
---

# Media Content Production

Use this class-level skill for media-centric tasks: finding GIFs, extracting YouTube transcripts, summarizing videos, analyzing audio, writing songs, creating AI music prompts, producing ASCII videos, or generating explanatory animations.

## YouTube and transcript workflows

Use when the user shares a YouTube URL or asks for transcript, summary, chapters, blog post, thread, or notes.

Pattern:

1. Extract transcript with a transcript API/helper when possible.
2. Preserve timestamps for long videos or chaptered summaries.
3. Transform into the requested format: bullet summary, blog post, thread, study notes, or action list.
4. If transcript extraction fails, report the limitation and try alternate sources only if available.

## GIF search

Use Tenor or another configured GIF API for reaction GIFs and media replies. Requires a Tenor API key for the original workflow. Return a direct media URL or downloaded file path when the platform needs an attachment.

## Audio feature visualization

Use audio visualization tools such as `songsee` for spectrograms, mel/chroma/MFCC grids, loudness, self-similarity, and other feature plots. Verify `ffmpeg` support for non-WAV/MP3 formats.

## Songwriting and AI music

For lyrics and music prompts, separate creative writing from generation prompt engineering:

- Song craft: structure, hook, point of view, rhyme, meter, dynamics.
- AI music prompt: genre, era, instrumentation, vocal style, tempo, production notes, exclusions.
- Keep art rules flexible; use them as levers, not constraints.

## ASCII video and terminal-style animation

Use when the user asks for ASCII video, terminal-style animation, text-art video, Matrix-style effects, or audio-reactive ASCII output. Pipeline usually includes frame extraction, glyph mapping, palette/color treatment, audio sync, and MP4/GIF export.

## Manim/explainer animation

Use Manim for mathematical, algorithmic, or technical explanation videos. The standard is educational cinema: plan scenes, visual metaphors, transitions, timing, and narration before coding.

## Verification checklist

- Generated/downloaded media exists and is playable/openable.
- Duration, format, resolution, and file size meet the user's platform constraints.
- For summaries, distinguish transcript-backed facts from inference.
- For generated prompts, include both concise and detailed variants if helpful.
