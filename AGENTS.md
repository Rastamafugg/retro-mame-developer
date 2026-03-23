# Workspace Instructions

This repository contains multiple retro development projects. When a task is
about NitrOS-9, Basic09, the Tandy CoCo 3, or the Stocks and Bonds game,
prefer the `stocksAndBonds` project and read its local agent instructions
before making changes.

## Project Routing

- `stocksAndBonds/`
  The active NitrOS-9 / CoCo 3 / Basic09 project. Read
  `stocksAndBonds/AGENTS.md` before editing code or docs in that subtree.
- `nitros9-examples/`
  Example/reference material. Do not change it unless the task explicitly
  targets that project.

## Working Rules

- Keep changes scoped to the user's request.
- Preserve existing formatting and line structure in source files.
- For Basic09 control-flow edits, modify only the named procedure or exact
  target block. Do not apply broad or repeated-text replacements to `IF`,
  `ELSE IF`, `ENDIF`, `WHILE`, `ENDWHILE`, `LOOP`, or `ENDLOOP` lines outside
  the intended local context.
- For `stocksAndBonds`, treat the project documentation under
  `stocksAndBonds/docs` as authoritative over general language assumptions.
- Before responding that a Basic09 code change is complete, follow the
  project-local review/checklist instructions for that subtree and fix any
  issues found. Do not treat checklist execution as optional.
- For `stocksAndBonds`, the required final Basic09 workflow step is the
  Section 6 "Code Review and QA Checklist" pass in
  `stocksAndBonds/docs/agents/basic09-software-development-agent.md`. Do not
  claim completion before performing that pass on the final edited code.
