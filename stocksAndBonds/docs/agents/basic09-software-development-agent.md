# Project Instructions: NitrOS-9 Basic09 Examples

These instructions govern how to build, edit, review, and QA Basic09 code in this project. They apply to all contributors and AI agents operating on this codebase.

---

## 1. Knowledge and Assumptions

* **Treat the Basic09 Programming Language Reference Manual as the authoritative source of truth.** Before writing, modifying, or reviewing any Basic09 code, confirm that all syntax, keywords, and patterns used are either explicitly documented in the reference manual or demonstrated in existing project source files.

* **Do not assume familiarity with Basic09 based on knowledge of other BASIC dialects.** Basic09 is not GW-BASIC, QBasic, Visual Basic, or any other BASIC variant. Many patterns common in other BASICs are invalid in Basic09. If a keyword or pattern is not present in the reference manual or existing project source, treat it as unsupported until confirmed otherwise.

* **Do not invent or extrapolate syntax.** The absence of a feature in the reference documentation is strong evidence it is not supported. When in doubt, ask for clarification before generating code.

* **Consult `bestPractices.md` before writing any new procedure.** This document is the project's coding standard and must be followed for all new and modified code.

* **Consult `basic09-error-handling.md` before writing or modifying error handling logic.**

---

## 2. Source Control Discipline

* **Limit changes to the scope of the assigned task.** This is a GitHub-managed project. Pull requests and check-ins must not include unrelated refactors, formatting changes, or speculative improvements.

* **Never modify a file that is not directly required by the task.** If a related improvement is identified, log it separately rather than bundling it into the current change.

* **Preserve the formatting conventions of the file being edited.** Do not reformat surrounding code unless the task explicitly requires it.

---

## 3. Writing New Code

* **Follow `bestPractices.md` for all new procedures.** This includes declaration order, line numbering conventions, termination rules, naming conventions, and error handling structure.

* **Verify all identifiers against the reserved words list in `bestPractices.md`** before using them as variable names, TYPE attribute names, array names, or procedure names.

* **Write every procedure with an `ON ERROR GOTO` handler** unless there is a documented, explicit reason not to.

* **Test memory usage estimates before finalizing array sizes.** Basic09 has a hard 32KB variable memory limit. Arrays that appear reasonable in modern environments may exceed this limit.

* **Prefer existing utility procedures over re-implementing common logic.** Review the project's existing `.b09` files before writing new string manipulation, file I/O, or parsing logic.

* **End-of-line comment syntax (`\ !`) must be used without exception.** In Basic09, the `!` character only introduces a comment when it appears at the start of a line. An inline comment appended to a statement requires the line concatenation operator first: `statement \ ! comment`. The form `statement ! comment` is a syntax error. Before finalizing any procedure, scan every line that contains `!` not at column 1 and confirm it is preceded by `\`.

---

## 4. Editing Existing Code

* **Read the full procedure before making any change.** Basic09 procedures are compact; missing a TYPE declaration, PARAM reference, or line number dependency in an existing procedure can introduce silent errors.

* **Preserve all existing line numbers that are referenced by `GOSUB`, `ON ERROR GOTO`, or `ON...GOTO`.** Renumbering these breaks branching logic.

* **Confirm that any new variable names do not shadow or duplicate existing names within the same procedure.** Basic09 does not allow duplicate definitions.

* **Do not add `MODULE`/`ENDMODULE` wrappers.** These are not valid Basic09 syntax.

---

## 5. Test Procedure Code

* **When writing test procedures, add user-input calls to pause the output between test blocks** When a test procedure has multiple blocks of tests, the earlier results can scroll off the screen before the user can read them.  Add a call `RUN waitKey` at the end of each test block, to allow the user to review pass/fails before proceeding to the next set of test in the procedure.

---

## 6. Code Review and QA Checklist

Before submitting or approving any Basic09 code change, verify:

- [ ] No reserved word is used as a variable, type attribute, array, or procedure name. This includes lowercase or mixed case versions of the identifiers.
- [ ] All `IF` blocks have a matching `ENDIF`; all `WHILE` blocks have `ENDWHILE`; all `FOR` loops have `NEXT`; all `LOOP` blocks have `ENDLOOP`; all `REPEAT` blocks have `UNTIL`; all `EXITIF` blocks have `ENDEXIT`
- [ ] `ELSE IF` nesting is fully closed with the correct number of `ENDIF` statements
- [ ] Every procedure has an `ON ERROR GOTO` handler (or a documented exception)
- [ ] Every procedure ends with `END`
- [ ] `RETURN` is used only inside `GOSUB` subroutines, never to terminate a procedure
- [ ] `RUN` is used to call procedures, not `CALL`
- [ ] No `GOTO` or `GOSUB` crosses procedure boundaries
- [ ] `ON ERROR GOTO` and `ON...GOTO/GOSUB` targets use line numbers, not labels
- [ ] TYPE declarations appear before PARAM declarations, which appear before DIM declarations
- [ ] Any `TYPE` used as a PARAM is declared at the top of both the calling and called procedures
- [ ] No variable memory usage obviously exceeds 32KB
- [ ] All STRING variables with non-default lengths are explicitly DIMmed with a length specifier
- [ ] Line length is 79 characters or fewer (exceptions documented inline)
- [ ] All line numbers within a procedure are unique and monotonically increasing
- [ ] No `MODULE` or `ENDMODULE` statements are present
- [ ] Every end-of-line comment uses `\ !` syntax, not bare `!`
- [ ] No `DIM` or `PARAM` variable name matches any field name defined in a `TYPE` declaration within the same procedure (causes Error #076 Multiply-defined Variable)
- [ ] Avoid ERROR(ERR) inside of the 900 error handling block of a procedure.  It results in an infinite loop, returning to line 900 and throwing the same error again.  It does not propagate upwards in the call stack.
- [ ] LAND, LOR, LNOT, and LXOR calls are called like other built-in functions in Basic09. For example: LAND(m,n)

---

## 7. Documentation Standards

* **Add a procedure header comment block immediately after `PROCEDURE name`.** Include at minimum: purpose, parameters, and any non-obvious side effects.

* **Comment non-obvious logic inline.** Use `\ ! comment` for end-of-line comments, or `!` on its own line for standalone comments.

* **Keep comments factual and concise.** Avoid comments that merely restate the code.

---

## 8. File and Directory Conventions

* **Basic09 source files use the `.b09` extension.**
* **Documentation files use the `.md` extension and reside in `/docs`.**
* **Prompt and instruction files reside in `/src/prompts`.**
* **All new source procedures belong in `/src/basic`** unless a different location is explicitly specified by the task.

---

## 9. Other Agents

* **NitrOS-9 Technical Reference Agent** Agent has access to the full technical reference documentation. Can answer information about OS architecture and system calls.
* **NitrOS-9 Assembly Source Agent** Agent has access to the assembly source for the kernal and core commands of NitrOS-9.  Can dig deep into the source to understand how the OS works and troubleshoot low-level issues.
