# Jira Templates

Templates for Jira issue interactions in [Atlassian Document Format (ADF)](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/) JSON format. These templates are used by the Rovo MCP backend path; the `acli` backend accepts markdown and handles ADF conversion internally.

> **ADF Reference**: Every ADF document is a JSON object with `version: 1`, `type: "doc"`, and a `content` array of block nodes. See the [ADF specification](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/) for full details.

## Table of Contents

- [Comment Templates](#comment-templates)
  - [phase-start](#phase-start)
  - [phase-completion](#phase-completion)
  - [work-start](#work-start)
  - [work-complete](#work-complete)
  - [bug-start](#bug-start)
  - [bug-complete](#bug-complete)

---

## Comment Templates

### phase-start

<!-- TODO: Phase 2 — Populate with complete ADF JSON template -->

**Context variables**: `phase` (number), `name` (phase name), `steps` (list), `deliverables` (list), `workItemId` (FEAT-XXX)

```json
{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "type": "text", "text": "🔄 Starting Phase {phase}: {name}" }]
    },
    {
      "type": "paragraph",
      "content": [
        { "type": "text", "text": "Work item: " },
        { "type": "text", "text": "{workItemId}", "marks": [{ "type": "strong" }] }
      ]
    }
  ]
}
```

### phase-completion

<!-- TODO: Phase 2 — Populate with complete ADF JSON template -->

**Context variables**: `phase` (number), `name` (phase name), `deliverables` (verified list), `commitSha` (short SHA), `workItemId` (FEAT-XXX)

```json
{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "type": "text", "text": "✅ Completed Phase {phase}: {name}" }]
    },
    {
      "type": "paragraph",
      "content": [
        { "type": "text", "text": "Work item: " },
        { "type": "text", "text": "{workItemId}", "marks": [{ "type": "strong" }] }
      ]
    }
  ]
}
```

### work-start

<!-- TODO: Phase 2 — Populate with complete ADF JSON template -->

**Context variables**: `choreId` (CHORE-XXX), `criteria` (acceptance criteria list), `branch` (branch name)

```json
{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "type": "text", "text": "🔄 Starting work on {choreId}" }]
    },
    {
      "type": "paragraph",
      "content": [
        { "type": "text", "text": "Branch: " },
        { "type": "text", "text": "{branch}", "marks": [{ "type": "code" }] }
      ]
    }
  ]
}
```

### work-complete

<!-- TODO: Phase 2 — Populate with complete ADF JSON template -->

**Context variables**: `choreId` (CHORE-XXX), `prNumber` (PR number), `criteria` (verified criteria list)

```json
{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "type": "text", "text": "✅ Completed {choreId}" }]
    },
    {
      "type": "paragraph",
      "content": [
        { "type": "text", "text": "Pull Request: #{prNumber}" }
      ]
    }
  ]
}
```

### bug-start

<!-- TODO: Phase 2 — Populate with complete ADF JSON template -->

**Context variables**: `bugId` (BUG-XXX), `severity` (level), `rootCauses` (RC-N list), `criteria` (acceptance criteria list), `branch` (branch name)

```json
{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "type": "text", "text": "🔄 Starting work on {bugId}" }]
    },
    {
      "type": "paragraph",
      "content": [
        { "type": "text", "text": "Severity: " },
        { "type": "text", "text": "{severity}", "marks": [{ "type": "strong" }] }
      ]
    }
  ]
}
```

### bug-complete

<!-- TODO: Phase 2 — Populate with complete ADF JSON template -->

**Context variables**: `bugId` (BUG-XXX), `prNumber` (PR number), `rootCauseResolutions` (RC-N resolution table), `verificationResults` (list)

```json
{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "type": "text", "text": "✅ Completed {bugId}" }]
    },
    {
      "type": "paragraph",
      "content": [
        { "type": "text", "text": "Pull Request: #{prNumber}" }
      ]
    }
  ]
}
```
