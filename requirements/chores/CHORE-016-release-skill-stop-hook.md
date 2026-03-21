# Chore: Add Stop Hook to Releasing-Plugins Skill

## Chore ID

`CHORE-016`

## GitHub Issue

[#50](https://github.com/lwndev/lwndev-marketplace/issues/50)

## Category

`configuration`

## Description

Add a Stop hook and release branch enforcement to the `releasing-plugins` skill. During the v1.3.0 release, the skill committed directly to `main` (no release branch step) and Phase 2 (tagging) was skipped entirely, causing `/plugin install` to resolve an outdated version. The Stop hook enforces completion criteria for both phases, and new skill steps ensure a release branch is created before committing.

## Affected Files

- `.claude/skills/releasing-plugins/SKILL.md`

## Acceptance Criteria

- [x] Stop hook blocks Phase 1 completion unless: release branch created, script ran, commit reviewed, branch pushed, PR opened, Phase 2 reminder given
- [x] Stop hook blocks Phase 2 completion unless: on main, tag created, tag pushed
- [x] Skill includes explicit release branch creation step before running the release script
- [x] Skill description includes Phase 2 trigger phrases ("tag the release", "finish the release")
- [x] Phase Detection section routes to correct phase on re-invocation

## Completion

**Status:** `Completed`

**Completed:** 2026-03-21

**Pull Request:** [#51](https://github.com/lwndev/lwndev-marketplace/pull/51)

## Notes

- Stop hook follows the same pattern used in `executing-qa` and `documenting-qa` skills: prompt-based evaluation using haiku model with `stop_hook_active` infinite-loop guard
- The skill is a local skill (`.claude/skills/`), not a plugin skill (`plugins/lwndev-sdlc/skills/`), so it is not subject to plugin validation
- Related issue [#49](https://github.com/lwndev/lwndev-marketplace/issues/49) tracks the separate concern of having the release *script* itself create branches automatically
