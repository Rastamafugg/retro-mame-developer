# Stocks And Bonds Agent Instructions

These instructions apply to all work under `stocksAndBonds/`.

## First Reads

Before writing, editing, or reviewing Basic09 code, read these documents in
this order:

1. `docs/agents/basic09-software-development-agent.md`
2. `docs/reference/bestPractices.md`
3. `docs/reference/basic09-error-handling.md`
4. `docs/design/module-phase-transition.md` when module ownership or runtime
   loading is relevant
5. `docs/reference/Basic09 Programming Language Reference Manual - NitrOS9 EOU.md`
   when syntax or built-in behavior must be confirmed

If the task is about NitrOS-9 syscalls rather than pure Basic09 syntax, also
read `docs/agents/nitros9-reference-manual-agent.md` before proposing an
implementation approach.

If a syscall detail appears ambiguous or undocumented, use
`docs/agents/nitros9-assembly-source-agent.md` as the source-verification guide.

## Core Basic09 Rules

- Do not assume syntax from other BASIC dialects.
- Do not invent Basic09 syntax, keywords, or control-flow forms.
- Follow `bestPractices.md` for declaration order, line numbering, naming,
  comments, and procedure structure.
- Consult `basic09-error-handling.md` before changing error handling.
- Write every procedure with `ON ERROR GOTO` unless the project docs document an
  explicit exception.
- Preserve referenced line numbers used by `GOSUB`, `ON ERROR GOTO`, and
  `ON...GOTO/GOSUB`.
- Use `RUN` to call procedures, not `CALL`.
- Do not add `MODULE` or `ENDMODULE`; they are not valid Basic09 syntax here.
- End-of-line comments must use `\\ ! comment`, never bare `!` after code.

## Project Layout

- `src/basic/`
  Primary location for Basic09 source.
- `docs/`
  Project documentation and design notes.
- `docs/agents/`
  Tasking and workflow instructions for coding and research.
- `docs/prompts/`
  Prompt templates and worked request examples.
- `docs/reference/`
  Coding standards, manuals, and technical references.

## Implementation Expectations

- Review the full procedure before editing a `.b09` file.
- Reuse existing utility procedures and established TYPE definitions when
  possible.
- Check new identifiers against the reserved-word guidance in
  `docs/reference/bestPractices.md`.
- Keep line lengths and formatting consistent with project standards.
- For test procedures with multiple output blocks, add `RUN waitKey` between
  blocks so results remain readable.
- Keep changes narrowly scoped; do not bundle unrelated cleanup.

## When Helping With Syscalls

- Treat the Technical Reference Manual workflow in
  `docs/agents/nitros9-reference-manual-agent.md` as authoritative.
- Use the project's `SysCall` shim and `Register` TYPE conventions already used
  in existing `.b09` source.
- Treat carry in `regs.cc` and the error code in `regs.b` according to the
  documented project pattern; confirm exact details in source and docs before
  coding.
