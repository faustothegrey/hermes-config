---
name: creative-web-visuals
description: "Create visual artifacts: HTML mockups, diagrams, infographics, Excalidraw, p5.js, design systems, and design briefs."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [creative, design, diagrams, html, css, p5js, excalidraw, infographics]
---

# Creative Web Visuals

Use this class-level skill when the user asks for visual/design artifacts: web mockups, diagrams, infographics, p5.js/generative sketches, Excalidraw files, architecture diagrams, DESIGN.md token specs, or design-system-inspired HTML/CSS.

## Choose the artifact type

| User asks for | Produce |
|---|---|
| System/cloud/infra diagram | Standalone HTML/SVG architecture diagram or Excalidraw JSON |
| Editable hand-drawn diagram | `.excalidraw` JSON |
| Landing page / UI / deck-like artifact | HTML/CSS artifact, usually 2-3 variants if exploring |
| Design tokens / visual identity spec | `DESIGN.md` with YAML tokens + rationale |
| Infographic / visual summary | Structured infographic with layout + style pairing |
| Generative or interactive visual art | p5.js single-file sketch or small project |
| Quick comparison before committing | Disposable sketch variants |

## Shared creative standards

- Build an actual artifact, not just a description.
- Use concrete dimensions, palette, typography, spacing, and visual hierarchy.
- Prefer a self-contained HTML file unless the requested format is explicit.
- Verify the artifact can be opened/rendered when tools allow.
- For multiple concepts, make variants visually meaningfully different rather than minor color swaps.

## Architecture diagrams

For technical architecture, use dark-themed SVG/HTML or Excalidraw depending on whether the user wants polished presentation or editable hand-drawn style.

Include: actors, data flow arrows, trust boundaries, infrastructure layers, and labels that explain responsibilities.

## Excalidraw diagrams

Write standard Excalidraw JSON. Use for architecture diagrams, flowcharts, sequence diagrams, concept maps, and collaborative whiteboard deliverables. Validate JSON before finalizing.

## Web/UI design and mockups

Use a design-process mindset:

1. Clarify or infer audience, purpose, and constraints.
2. Generate a strong visual direction.
3. Implement as HTML/CSS with real layout details.
4. Inspect in browser/screenshot if possible.

Use real design-system references when appropriate: Stripe/Linear/Vercel-style systems, modern SaaS dashboards, editorial layouts, mobile app screens, etc. Do not copy trademarks/assets unless the user asks for a parody/reference and it is safe.

## DESIGN.md token specs

When asked to create or maintain a design language for future coding agents, write a `DESIGN.md`: YAML front matter for machine-readable tokens and markdown for rationale. Validate contrast and token consistency when possible.

## Infographics

Treat infographics as information architecture plus visual style. First structure the content (hierarchy, comparisons, timeline, matrix, process, map), then choose a style (technical, kawaii, chalkboard, editorial, etc.). Dense information should still be legible.

## p5.js / generative sketches

Use p5.js for interactive visualizations, canvas animation, shaders, audio-reactive visuals, 3D/WebGL, and generative art. Include instructions to serve/open the sketch and export frames if needed.

## Artifact verification checklist

- File exists at the promised path.
- HTML/JSON/markdown parses.
- Visual hierarchy matches the prompt.
- No missing local assets or broken relative links.
- Final response includes path and usage/opening instructions.
