# Chore: Add Finalizing Workflow Skill

## Chore ID

`CHORE-023`

## GitHub Issue

[#70](https://github.com/lwndev/lwndev-marketplace/issues/70)

## Category

`refactoring`

## Description

Add a lightweight `finalizing-workflow` skill to the lwndev-sdlc plugin that merges the current PR, checks out main, fetches, and pulls — reducing the repetitive end-of-workflow git sequence to a single slash command.

## Affected Files

- `plugins/lwndev-sdlc/skills/finalizing-workflow/SKILL.md` (new)
- `plugins/lwndev-sdlc/README.md`
- `CLAUDE.md`
- `package-lock.json` (audit fix)
- `.husky/pre-commit` (audit-level threshold)

## Acceptance Criteria

- [x] Skill directory `plugins/lwndev-sdlc/skills/finalizing-workflow/` exists with a valid `SKILL.md`
- [x] SKILL.md has correct YAML frontmatter (name, description) and prompt instructions
- [x] Skill identifies the current branch and its associated PR before merging
- [x] Skill merges the PR via `gh pr merge`, checks out `main`, fetches, and pulls
- [x] Skill handles edge cases: no PR for current branch, merge conflicts, dirty working directory
- [x] Plugin validates successfully (`npm run validate`)
- [x] Plugin README updated to list the new skill in the workflow chains
- [x] CLAUDE.md updated to reflect the new skill in workflow chains and skill listing
- [x] `npm audit fix` resolves all high/critical vulnerabilities
- [x] Pre-commit hook updated to `--audit-level=high` (remaining 28 moderate are unfixable transitive deps in jest/eslint/ai-skills-manager)

## Completion

**Status:** `Pending`

**Completed:** YYYY-MM-DD

**Pull Request:** [#N](https://github.com/lwndev/lwndev-marketplace/pull/N)

## Notes

- This is the terminal step in all three SDLC workflow chains (features, chores, bugs)
- The skill prompt should be minimal since it's a deterministic sequence
- Merge strategy (merge commit, squash, rebase) should use repo defaults unless made configurable
- Skill should confirm intent before executing the merge
