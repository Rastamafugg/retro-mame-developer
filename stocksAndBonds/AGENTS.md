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
- Do not introduce any Basic09 function, keyword, statement form, or control
  structure unless it is explicitly documented in the Basic09 reference manual
  or already demonstrated in current project source. If not verified, do not
  use it.
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
- For Basic09 control-flow fixes, edit only the named procedure range and use
  exact local context. Do not patch repeated `ENDIF` or similar closure lines
  by broad text replacement across the file.
- Do not use generic repeated-text patches for Basic09 source. Every patch must
  be anchored to unique surrounding lines inside the named procedure or exact
  target block.
- For every `IF` or `ELSE IF` added in a procedure edit, verify the matching
  closure count in that same procedure before making any further edits.
- After any control-flow edit, immediately re-read the exact edited line block
  to confirm the patch landed in the intended procedure and nowhere else.
- Reuse existing utility procedures and established TYPE definitions when
  possible.
- Check new identifiers against the reserved-word guidance in
  `docs/reference/bestPractices.md`.
- Keep line lengths and formatting consistent with project standards.
- For test procedures with multiple output blocks, add `RUN waitKey` between
  blocks so results remain readable.
- Keep changes narrowly scoped; do not bundle unrelated cleanup.
- Do not change test scenarios, reproduction conditions, player types,
  interaction model, or acceptance criteria unless the user explicitly asks for
  that change.
- If a test or harness appears flawed, preserve the requested scenario and fix
  only the defect under investigation unless the user approves a scenario
  change first.
- Do not present inferred runtime behavior, console behavior, screen behavior,
  or hardware behavior as an observed fact unless it was directly reported by
  the user or directly verified in the current task.
- When diagnosing failures from user-reported output, distinguish explicitly
  between:
  1. observed facts from the user or code
  2. hypotheses that still need confirmation
- If the observed output is insufficient to prove a cause, say that directly
  and propose checks instead of inventing an explanation.
- Before editing a diagnostic harness or repro test, state in one sentence what
  behavior or scenario must remain unchanged.
- For troubleshooting, prefer the smallest possible inline instrumentation at
  the suspected failing step over structural rewrites, helper subroutines, or
  control-flow refactors.
- Do not add new `GOSUB`, `GOTO`, helper branches, or error-routing scaffolding
  to an existing diagnostic harness unless the user explicitly asks for a
  structural refactor.
- In diagnostic harnesses, preserve existing execution order, prompts, pauses,
  and block shape unless the user explicitly asks to change them.
- Before giving a completion response for any Basic09 source change, run a
  deliberate self-review against the checklist in
  `docs/agents/basic09-software-development-agent.md` Section 6 and correct
  violations first.
- That self-review must include a targeted scan of the edited procedures for
  any newly introduced syntax, built-in names, or control-flow forms that were
  not explicitly verified against the Basic09 manual or existing project code.

## Required Workflow Step

- Before any final response that claims a Basic09 code change is done, perform
  an explicit "Section 6 Code Review and QA Checklist" pass using
  `docs/agents/basic09-software-development-agent.md`.
- This is a required workflow step, not a reminder. Do not skip it for small
  edits, refactors, helper extraction, or follow-up fixes.
- The checklist pass must be done after the final code edit, not earlier in the
  task.
- The checklist pass must review each edited procedure top to bottom against the
  Section 6 items beginning with "Before submitting or approving any Basic09
  code change, verify:"
- If any checklist item fails, fix the code first and repeat the checklist
  pass before responding.
- Do not give a completion response until that checklist pass has been done.

## When Helping With Syscalls

- Treat the Technical Reference Manual workflow in
  `docs/agents/nitros9-reference-manual-agent.md` as authoritative.
- Use the project's `SysCall` shim and `Register` TYPE conventions already used
  in existing `.b09` source.
- Treat carry in `regs.cc` and the error code in `regs.b` according to the
  documented project pattern; confirm exact details in source and docs before
  coding.
