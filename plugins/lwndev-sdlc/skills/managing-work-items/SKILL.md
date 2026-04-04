---
name: managing-work-items
description: Centralizes issue tracker operations (GitHub Issues, Jira) into a single delegatable skill. Handles fetch and comment operations with automatic backend detection from issue reference format. Use when the orchestrator needs to fetch issue data, post status comments, generate PR body issue links, or extract issue references from requirement documents.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
argument-hint: "<operation> <issue-ref> [--type <comment-type>] [--context <json>]"
---

# Managing Work Items

Centralized issue tracker operations for GitHub Issues and Jira, invoked by the orchestrator at workflow integration points.

## When to Use This Skill

- Orchestrator needs to fetch issue data to pre-fill a requirements document
- Orchestrator needs to post a status comment (phase start, phase completion, work start, work complete, bug start, bug complete) on an issue
- Orchestrator needs to generate the PR body issue link (`Closes #N` or `PROJ-123`)
- Orchestrator needs to extract the issue reference from a requirement document's `## GitHub Issue` section

This skill is invoked by the orchestrator -- not directly by users. All operations are supplementary to the workflow and must never block workflow progression on failure.

## Arguments

The skill accepts the following invocation syntax:

```
managing-work-items <operation> <issue-ref> [--type <comment-type>] [--context <json>]
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `<operation>` | Yes | One of: `fetch`, `comment`, `pr-link`, `extract-ref` |
| `<issue-ref>` | Yes (for `fetch`, `comment`, `pr-link`) | Issue reference: `#N` (GitHub) or `PROJ-123` (Jira) |
| `--type` | Yes (for `comment`) | Comment type: `phase-start`, `phase-completion`, `work-start`, `work-complete`, `bug-start`, `bug-complete` |
| `--context` | Yes (for `comment`) | JSON string with template variables |

### Operations

| Operation | Description | Example |
|-----------|-------------|---------|
| `fetch` | Retrieve issue details (title, body, labels, state, assignees) | `managing-work-items fetch #119` |
| `comment` | Post a formatted comment using type-specific templates | `managing-work-items comment #119 --type phase-start --context '{"phase": 1, "name": "GitHub Backend"}'` |
| `pr-link` | Generate the auto-close syntax for a PR body | `managing-work-items pr-link #119` |
| `extract-ref` | Extract issue reference from a requirement document | `managing-work-items extract-ref requirements/features/FEAT-012.md` |

## Backend Detection (FR-1)

Automatically detect the issue tracker backend from the issue reference format:

| Format | Pattern | Backend |
|--------|---------|---------|
| `#N` | `#` followed by one or more digits | GitHub Issues (via `gh` CLI) |
| `PROJ-123` | Alphabetic/alphanumeric project key + `-` + digits | Jira (via tiered fallback) |
| Empty/absent | No reference provided | Skip all operations gracefully |

### Detection Logic

1. **Parse the issue reference**:
   - If it matches `^#(\d+)$` -- GitHub Issues. Extract the number `N`.
   - If it matches `^([A-Z][A-Z0-9]*)-(\d+)$` -- Jira. Extract the project key and issue number.
   - If the reference is empty, null, or absent -- log an info message ("No issue reference provided, skipping issue operations") and return immediately.
2. **Route to the appropriate backend** based on the detected format.

## GitHub Issues Backend (FR-2)

All GitHub operations use the `gh` CLI. Before executing any operation, verify the CLI is available and authenticated.

### Fetch Operation

Retrieve issue details and return structured data:

```bash
gh issue view <N> --json title,body,labels,state,assignees
```

**Returns**: JSON object with `title`, `body`, `labels`, `state`, `assignees` fields.

**Usage**: Pre-fill requirements documents, verify issue exists before starting a workflow.

### Comment Operation

Post a formatted comment to the issue:

```bash
gh issue comment <N> --body "<formatted-comment>"
```

The comment body is formatted using the appropriate template from [references/github-templates.md](references/github-templates.md) based on the `--type` argument. Template variables from the `--context` JSON are substituted into the template.

## Comment Type Routing (FR-5)

Map the `--type` argument to the correct template and populate it with context data:

| Comment Type | Template | Context Variables |
|-------------|----------|-------------------|
| `phase-start` | Phase start template | `phase` (number), `name` (phase name), `steps` (list), `deliverables` (list), `workItemId` (FEAT-XXX) |
| `phase-completion` | Phase completion template | `phase` (number), `name` (phase name), `deliverables` (verified list), `commitSha` (short SHA), `workItemId` (FEAT-XXX) |
| `work-start` | Work start template | `choreId` (CHORE-XXX), `criteria` (acceptance criteria list), `branch` (branch name) |
| `work-complete` | Work complete template | `choreId` (CHORE-XXX), `prNumber` (PR number), `criteria` (verified criteria list) |
| `bug-start` | Bug start template | `bugId` (BUG-XXX), `severity` (level), `rootCauses` (RC-N list), `criteria` (acceptance criteria list), `branch` (branch name) |
| `bug-complete` | Bug complete template | `bugId` (BUG-XXX), `prNumber` (PR number), `rootCauseResolutions` (RC-N resolution table), `verificationResults` (list) |

### Rendering Process

1. Look up the template in [references/github-templates.md](references/github-templates.md) (for GitHub) or [references/jira-templates.md](references/jira-templates.md) (for Jira) based on the `--type` value.
2. Parse the `--context` JSON to extract template variables.
3. Substitute variables into the template (replace `<PLACEHOLDER>` with actual values, expand list placeholders into formatted lists).
4. Post the rendered comment via the appropriate backend.

## PR Body Issue Link Generation (FR-6)

Generate the appropriate auto-close syntax for PR bodies based on the detected backend:

| Backend | Output | Effect |
|---------|--------|--------|
| GitHub | `Closes #N` | Auto-closes the issue when the PR is merged |
| Jira | `PROJ-123` | Jira auto-transition relies on the branch name containing the issue key |
| No reference | Empty string | No issue link in PR body |

**Usage**: The orchestrator calls `pr-link` at PR creation to get the correct syntax, then includes it in the PR body's "Related" section.

## Issue Reference Extraction from Documents (FR-7)

Extract the issue reference from a requirement document by reading the `## GitHub Issue` section (or `## Issue` / `## Issue Tracker` for future compatibility):

### Extraction Logic

1. Read the requirement document.
2. Find the `## GitHub Issue` section (also check `## Issue` and `## Issue Tracker`).
3. Parse the section content for issue reference patterns:
   - `[#N](URL)` -- extract `#N` (GitHub)
   - `[PROJ-123](URL)` -- extract `PROJ-123` (Jira)
4. Return the first match found, or `null` if the section is empty or missing.

**Example document section**:
```markdown
## GitHub Issue
[#119](https://github.com/lwndev/lwndev-marketplace/issues/119)
```

**Extracted reference**: `#119`

## Jira Backend (FR-3) -- Tiered Fallback

Jira support uses a tiered fallback approach. The tiers are checked in order; the first available backend is used:

1. **Tier 1 -- Rovo MCP**: Check if the `rovo` MCP server is available. If present, use Rovo MCP tools (`getJiraIssue`, `addCommentToJiraIssue`). Comments must be in Atlassian Document Format (ADF) JSON -- see [references/jira-templates.md](references/jira-templates.md).
2. **Tier 2 -- Atlassian CLI (`acli`)**: Check if `acli` is on PATH (`which acli`). If present, use `acli jira workitem` subcommands. `acli` accepts markdown and handles ADF conversion internally.
3. **Tier 3 -- Skip**: If neither backend is available, log a warning ("No Jira backend available (Rovo MCP not registered, acli not found). Skipping Jira operations.") and skip without failing.

> **Note**: Jira backend operations are implemented in Phase 2. In Phase 1, detecting a Jira-format reference (`PROJ-123`) logs an info message ("Jira backend not yet implemented, skipping") and skips gracefully.

## Graceful Degradation (NFR-1)

Issue tracker operations are supplementary -- they must **never** block workflow progression. All failure modes degrade gracefully:

| Failure | Behavior |
|---------|----------|
| `gh` CLI not installed or not on PATH | Log warning: "GitHub CLI (`gh`) not found on PATH. Skipping GitHub issue operations." Skip operation. |
| `gh` not authenticated | Log warning: "GitHub CLI not authenticated. Run `gh auth login` to enable issue tracking." Skip operation. |
| Network unavailable | Log warning: "Network request failed. Skipping issue operation." Skip operation. |
| Rate limited | Log warning: "GitHub API rate limit reached. Skipping issue operation." Skip operation. Do not retry. |
| Issue does not exist | Log warning: "`gh issue view` returned not found for #N. Skipping." Skip operation. |
| Jira backend unavailable | Fall through tiered selection (Rovo MCP -> acli -> skip). Log which tier was attempted. |
| MCP tool invocation failure | Log error with tool name and response. Fall through to `acli` tier. |
| Rovo MCP authorization error | Log "Rovo MCP authorization failed -- check OAuth consent or API token configuration." Fall through to `acli`. |

### Implementation Pattern

Wrap every external command in a try/catch (or check exit code) pattern:

```bash
# Example: GitHub comment with graceful degradation
if ! command -v gh &>/dev/null; then
  echo "Warning: gh CLI not found. Skipping issue comment."
  return
fi

if ! gh auth status &>/dev/null 2>&1; then
  echo "Warning: gh CLI not authenticated. Run 'gh auth login'. Skipping issue comment."
  return
fi

if ! gh issue comment <N> --body "<comment>" 2>&1; then
  echo "Warning: Failed to post issue comment. Continuing workflow."
fi
```

## Error Handling (NFR-2)

| Error Type | Response |
|-----------|----------|
| Command failure (non-zero exit) | Log error with full command output. Skip operation. Continue workflow. |
| Authentication error (GitHub) | Log: "GitHub CLI not authenticated -- run `gh auth login`". Skip. |
| Authentication error (Jira/Rovo MCP) | Log: "Rovo MCP authorization failed -- check OAuth consent or API token configuration". Fall through to `acli`. |
| Authentication error (Jira/acli) | Log: "Atlassian CLI not authenticated -- check `acli` credentials configuration". Skip. |
| Rate limiting | Log warning. Skip. Do not retry. |
| Timeout | Log warning with timeout duration. Skip. |
| MCP server disconnection | Log error with tool name. Fall through to `acli`. |

## Idempotency (NFR-3)

- **Comment operations are safe to retry.** Posting the same comment twice results in a duplicate comment, which is acceptable -- better than a missing comment.
- **Fetch operations are inherently idempotent** -- reading issue data has no side effects.
- **PR link generation is pure computation** -- no side effects, always returns the same result for the same input.
- **If a workflow is re-run or resumed**, issue operations can be re-executed without concern. The orchestrator does not need to track which operations have already been performed.

## Workflow

```
1. Receive invocation: <operation> <issue-ref> [--type <type>] [--context <json>]
2. Detect backend from issue reference format (FR-1)
3. If no reference provided → log info, return
4. If GitHub (#N):
   a. Verify gh CLI available and authenticated
   b. Execute operation (fetch/comment) via gh CLI
   c. On failure → log warning, skip, return
5. If Jira (PROJ-123):
   a. Check Tier 1 (Rovo MCP) → if available, execute via MCP tools
   b. Check Tier 2 (acli) → if available, execute via acli CLI
   c. Tier 3 → log warning, skip, return
6. Return result (fetch data, confirmation, or skip notice)
```

## References

- **GitHub comment templates**: [github-templates.md](references/github-templates.md) - Consolidated templates for all six comment types, plus commit messages, PR body, and issue creation
- **Jira comment templates**: [jira-templates.md](references/jira-templates.md) - Jira templates in ADF JSON format (Phase 2 content)
