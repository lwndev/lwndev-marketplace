# Chore: Add PR Creation to Implementing Plan Phases

## Chore ID

`CHORE-021`

## GitHub Issue

[#42](https://github.com/lwndev/lwndev-marketplace/issues/42)

## Category

`refactoring`

## Description

Enhance the implementing-plan-phases skill to create a pull request after all plan phases are complete. The executing-chores and executing-bug-fixes skills both include an explicit PR creation step with a dedicated PR template, but implementing-plan-phases currently ends at commit/push without creating a PR, leaving phases committed but unmerged.

## Affected Files

- `plugins/lwndev-sdlc/skills/implementing-plan-phases/SKILL.md` — add PR creation step to the workflow
- `plugins/lwndev-sdlc/skills/implementing-plan-phases/assets/` — new directory (to be created)
- `plugins/lwndev-sdlc/skills/implementing-plan-phases/assets/pr-template.md` — new PR template (to be created)

## Acceptance Criteria

- [x] SKILL.md includes a PR creation step after all phases are complete
- [x] A `pr-template.md` asset exists in `assets/` with a structure consistent with the executing-chores and executing-bug-fixes templates
- [x] PR template includes a link to the implementation plan document
- [x] PR template includes `Closes #N` for GitHub issue linking
- [x] Plugin validates successfully (`npm run validate`)
- [x] Workflow aligns with executing-chores and executing-bug-fixes PR creation patterns

## Completion

**Status:** `Pending`

**Completed:** YYYY-MM-DD

**Pull Request:** [#N](https://github.com/lwndev/lwndev-marketplace/pull/N)

## Notes

- The executing-chores and executing-bug-fixes PR templates share a common structure: document link, summary, changes, testing checklist, and `Closes #N` in the related section. The new template should follow this same pattern adapted for implementation plans.
- The bug-fixes template adds root cause traceability sections; the plan-phases template may want to include a phase completion summary instead.
