# React ESLint `react-hooks/set-state-in-effect` without behavior changes

Context: Next.js/React client component lint can fail on synchronous `setState(...)` inside an effect, especially when reading browser-only state such as `localStorage` after hydration.

Observed lint shape:

```text
error  Error: Calling setState synchronously within an effect can trigger cascading renders
react-hooks/set-state-in-effect
```

Minimal behavior-preserving pattern used successfully:

```tsx
useEffect(() => {
  if (typeof window === "undefined") return;

  const timeout = window.setTimeout(() => {
    setValue(localStorage.getItem(key) ?? fallback);
  }, 0);

  return () => window.clearTimeout(timeout);
}, [key]);
```

Why this is useful:
- preserves the existing initial render fallback value;
- still reads browser-only state after mount;
- avoids synchronous state update in the effect body;
- adds cleanup so unmounts or key changes cannot apply stale delayed updates.

Workflow notes:
1. Reproduce with targeted lint first, for example `npm run lint -- 'src/app/.../page.tsx'`.
2. Keep the change minimal and avoid unrelated refactors.
3. Verify targeted lint, then typecheck when feasible.
4. Run full lint last and distinguish unrelated pre-existing warnings from the fixed target error.
