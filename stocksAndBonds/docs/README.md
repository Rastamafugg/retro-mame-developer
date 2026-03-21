# stocksAndBonds

Status: Current  
Authority: Documentation index and reading order

## Canonical Design Set

Read these files in this order when working on the game design:

1. `docs/design/stock-and-bonds-rules.md`
   Source transcription of the original Avalon Hill rules. Preserve this as the
   historical rules text. Project interpretations of ambiguous rules are
   defined in the specification.
2. `docs/design/specification.md`
   Canonical gameplay and rules-behavior document for this project.
3. `docs/design/phase-child-design.md`
   Canonical runtime architecture document for the current file-based
   phase-child implementation.
4. `docs/design/save-load-design.md`
   Canonical save format and resume-semantics document.
5. `docs/design/ui-screen-flow.md`
   Canonical UI and screen-navigation document.
6. `docs/design/ai-player-logic.md`
   Canonical AI behavior document.
7. `docs/design/ai-difficulty-tiers.md`
   Canonical AI parameterization document.

## Supporting Design Files

- `docs/design/forkio-plan.md`
  Historical transition document. Useful for rationale and some retained file
  IPC details, but not authoritative where it conflicts with the canonical set.
- `docs/design/module-phase-transition.md`
  Historical module-loading design. Keep for code division notes and measured
  memory figures only; the runtime loading model is superseded.
- `docs/design/project-timeline.md`
  Historical implementation planning artifact. Not authoritative for current
  rules or architecture.

A new Color Computer project targeting output type: **floppy**

## Project Structure

- `src/basic`: BASIC source
- `src/asm`: Assembly source
- `src/img`: Image assets
- `src/snd`: Sound/music
- `src/txt`: Text/data
- `bin`: Compiled output
- `docs`: Project documentation
- `log`: Build logs and diagnostics

## Build

Run:

```bash
./build.sh
```

Or invoke the master script with parameters.
