# Workspace Instructions

This repository contains multiple retro development projects.

## Durable Behavior Changes

- If the assistant agrees to change its own ongoing working behavior, review
  method, patching method, disclosure method, or response protocol in a
  durable way, it must update the relevant AGENTS file(s) in the same task
  unless the user explicitly says not to.
- Do not present such a behavior change as persistent or "going forward"
  unless the AGENTS update has been made.
- If the change applies repo-wide, update this root AGENTS file. If it applies
  to a specific project subtree, update that project's local AGENTS file as
  well.
- Place durable behavior-change rules near the top of the AGENTS file so they
  govern later task-specific instructions.

## Exact Line Citations

- When the user cites exact file lines or a narrow line range, identify any
  additional same-block findings separately before editing.
- Distinguish explicitly between:
  1. the exact cited issue the user asked to fix
  2. any adjacent same-block issue proposed for bundled repair
- Do not patch adjacent same-block issues unless they are disclosed first.

## Project Routing

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
- For Basic09 work, do not use generic repeated-text patches. Every edit must
  be anchored to unique local context in the named procedure or exact target
  block.
- Before responding that a Basic09 code change is complete, follow the
  project-local review/checklist instructions for that subtree and fix any
  issues found. Do not treat checklist execution as optional.
