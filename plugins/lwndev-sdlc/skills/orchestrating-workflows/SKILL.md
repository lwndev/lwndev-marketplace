---
name: orchestrating-workflows
description: Orchestrate full SDLC workflow chains (feature, chore, bug) end-to-end by sequencing sub-skill invocations, managing state across pause points, and isolating per-step context via Agent tool forking.
argument-hint: "<title-or-issue> or <ID>"
compatibility: Requires jq and a bash-compatible shell
---

# Orchestrating Workflows

Placeholder — full orchestration logic will be added in Phase 2.

## When to Use This Skill

- User wants to run a full SDLC workflow chain (feature, chore, or bug) end-to-end
- User says "orchestrate workflow", "run full workflow", or "start workflow chain"

## Arguments

- **When argument is provided**: If the argument matches an existing workflow ID (e.g., `FEAT-003`), resume that workflow. If it's a free-text title or `#N` issue reference, start a new feature workflow.
- **When no argument is provided**: Ask the user for a feature title, GitHub issue, or existing workflow ID to resume.

## Quick Start

1. Parse argument to determine new workflow vs resume
2. For new workflows: run `documenting-features` in main context, read allocated ID
3. Initialize state via `scripts/workflow-state.sh init {ID} feature`
4. Execute steps sequentially, forking sub-skills via Agent tool
5. Pause at plan approval and PR review checkpoints
6. Resume via re-invocation with the workflow ID

## Verification Checklist

- [ ] All steps executed in correct order
- [ ] State file reflects current progress
- [ ] Artifacts exist for completed steps
- [ ] Sub-skills were not modified

## Relationship to Other Skills

This skill orchestrates all other skills in the lwndev-sdlc plugin. It sequences:
`documenting-features` → `reviewing-requirements` → `creating-implementation-plans` → `documenting-qa` → `reviewing-requirements` → `implementing-plan-phases` → `reviewing-requirements` → `executing-qa` → `finalizing-workflow`
