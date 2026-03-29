#!/usr/bin/env bash
set -euo pipefail

SDLC_DIR=".sdlc/workflows"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Ensure jq is available
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed. Install with: brew install jq" >&2
  exit 1
fi

# --- Helpers ---

state_file() {
  echo "$PROJECT_ROOT/$SDLC_DIR/$1.json"
}

ensure_dir() {
  mkdir -p "$PROJECT_ROOT/$SDLC_DIR"
}

now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

validate_id() {
  local id="$1"
  if [[ ! "$id" =~ ^(FEAT|CHORE|BUG)-[0-9]{3,}$ ]]; then
    echo "Error: Invalid ID \"$id\". Expected format: FEAT-NNN, CHORE-NNN, or BUG-NNN (e.g., FEAT-003, CHORE-028, BUG-001)" >&2
    exit 1
  fi
}

read_state() {
  local file
  file="$(state_file "$1")"
  if [[ ! -f "$file" ]]; then
    echo "Error: No state file found for \"$1\" at $file" >&2
    exit 1
  fi
  # Validate required fields (NFR-5)
  if ! jq -e '.id and .type and .status and .steps and .currentStep' "$file" &>/dev/null; then
    echo "Error: State file for \"$1\" is malformed or missing required fields (id, type, status, steps, currentStep). Consider deleting $file and restarting the workflow." >&2
    exit 1
  fi
  cat "$file"
}

write_state() {
  local id="$1" json="$2"
  local file
  file="$(state_file "$id")"
  echo "$json" | jq '.' > "$file"
}

# --- Step sequence builders ---

feature_pre_phase_steps() {
  jq -n '[
    {"name":"Document feature requirements","skill":"documenting-features","context":"main","status":"pending"},
    {"name":"Review requirements (standard)","skill":"reviewing-requirements","context":"fork","status":"pending"},
    {"name":"Create implementation plan","skill":"creating-implementation-plans","context":"fork","status":"pending"},
    {"name":"Pause: Plan approval","skill":null,"context":"pause","status":"pending"},
    {"name":"Document QA test plan","skill":"documenting-qa","context":"main","status":"pending"},
    {"name":"Reconcile test plan","skill":"reviewing-requirements","context":"fork","status":"pending"}
  ]'
}

chore_steps() {
  jq -n '[
    {"name":"Document chore","skill":"documenting-chores","context":"main","status":"pending"},
    {"name":"Review requirements (standard)","skill":"reviewing-requirements","context":"fork","status":"pending"},
    {"name":"Document QA test plan","skill":"documenting-qa","context":"main","status":"pending"},
    {"name":"Reconcile test plan","skill":"reviewing-requirements","context":"fork","status":"pending"},
    {"name":"Execute chore","skill":"executing-chores","context":"fork","status":"pending"},
    {"name":"Pause: PR review","skill":null,"context":"pause","status":"pending"},
    {"name":"Reconcile post-review","skill":"reviewing-requirements","context":"fork","status":"pending"},
    {"name":"Execute QA","skill":"executing-qa","context":"main","status":"pending"},
    {"name":"Finalize","skill":"finalizing-workflow","context":"fork","status":"pending"}
  ]'
}

bug_steps() {
  jq -n '[
    {"name":"Document bug","skill":"documenting-bugs","context":"main","status":"pending"},
    {"name":"Review requirements (standard)","skill":"reviewing-requirements","context":"fork","status":"pending"},
    {"name":"Document QA test plan","skill":"documenting-qa","context":"main","status":"pending"},
    {"name":"Reconcile test plan","skill":"reviewing-requirements","context":"fork","status":"pending"},
    {"name":"Execute bug fix","skill":"executing-bug-fixes","context":"fork","status":"pending"},
    {"name":"Pause: PR review","skill":null,"context":"pause","status":"pending"},
    {"name":"Reconcile post-review","skill":"reviewing-requirements","context":"fork","status":"pending"},
    {"name":"Execute QA","skill":"executing-qa","context":"main","status":"pending"},
    {"name":"Finalize","skill":"finalizing-workflow","context":"fork","status":"pending"}
  ]'
}

feature_post_phase_steps() {
  jq -n '[
    {"name":"Create PR","skill":null,"context":"fork","status":"pending"},
    {"name":"Pause: PR review","skill":null,"context":"pause","status":"pending"},
    {"name":"Reconcile post-review","skill":"reviewing-requirements","context":"fork","status":"pending"},
    {"name":"Execute QA","skill":"executing-qa","context":"main","status":"pending"},
    {"name":"Finalize","skill":"finalizing-workflow","context":"fork","status":"pending"}
  ]'
}

# --- Commands ---

cmd_init() {
  local id="$1" type="$2"
  validate_id "$id"
  ensure_dir

  local file
  file="$(state_file "$id")"

  # Idempotent: if state file exists, return current state
  if [[ -f "$file" ]]; then
    cat "$file"
    return 0
  fi

  local steps
  case "$type" in
    feature) steps="$(feature_pre_phase_steps)" ;;
    chore)   steps="$(chore_steps)" ;;
    bug)     steps="$(bug_steps)" ;;
    *)
      echo "Error: Unknown type \"$type\". Expected: feature, chore, or bug" >&2
      exit 1
      ;;
  esac

  local state
  state=$(jq -n \
    --arg id "$id" \
    --arg type "$type" \
    --arg now "$(now_iso)" \
    --argjson steps "$steps" \
    '{
      id: $id,
      type: $type,
      currentStep: 1,
      status: "in-progress",
      pauseReason: null,
      steps: $steps,
      phases: { total: 0, completed: 0 },
      prNumber: null,
      branch: null,
      error: null,
      startedAt: $now,
      lastResumedAt: null,
      completedAt: null
    }')

  write_state "$id" "$state"
  echo "$state" | jq '.'
}

cmd_status() {
  local id="$1"
  validate_id "$id"
  read_state "$id" | jq '.'
}

cmd_advance() {
  local id="$1"
  local artifact="${2:-}"
  validate_id "$id"

  local state
  state="$(read_state "$id")"

  local current_step total_steps current_status
  current_step=$(echo "$state" | jq -r '.currentStep')
  total_steps=$(echo "$state" | jq -r '.steps | length')
  current_status=$(echo "$state" | jq -r ".steps[$((current_step - 1))].status")

  # Idempotent: if current step is already complete, no-op
  if [[ "$current_status" == "complete" ]]; then
    echo "$state" | jq '.'
    return 0
  fi

  local now
  now="$(now_iso)"

  # Mark current step as complete
  state=$(echo "$state" | jq \
    --arg now "$now" \
    --arg artifact "$artifact" \
    --argjson idx "$((current_step - 1))" \
    '.steps[$idx].status = "complete"
     | .steps[$idx].completedAt = $now
     | if $artifact != "" then .steps[$idx].artifact = $artifact else . end')

  # Update phase completed count if this was a phase step
  local has_phase
  has_phase=$(echo "$state" | jq --argjson idx "$((current_step - 1))" '.steps[$idx] | has("phaseNumber")')
  if [[ "$has_phase" == "true" ]]; then
    state=$(echo "$state" | jq '.phases.completed += 1')
  fi

  # Advance to next step or complete
  if [[ "$current_step" -ge "$total_steps" ]]; then
    state=$(echo "$state" | jq --arg now "$now" '.status = "complete" | .completedAt = $now')
  else
    state=$(echo "$state" | jq '.currentStep += 1')
  fi

  write_state "$id" "$state"
  echo "$state" | jq '.'
}

cmd_pause() {
  local id="$1" reason="$2"
  validate_id "$id"

  local state
  state="$(read_state "$id")"
  state=$(echo "$state" | jq --arg reason "$reason" '.status = "paused" | .pauseReason = $reason')

  write_state "$id" "$state"
  echo "$state" | jq '.'
}

cmd_resume() {
  local id="$1"
  validate_id "$id"

  local state
  state="$(read_state "$id")"
  state=$(echo "$state" | jq --arg now "$(now_iso)" \
    '.status = "in-progress" | .pauseReason = null | .lastResumedAt = $now')

  write_state "$id" "$state"
  echo "$state" | jq '.'
}

cmd_fail() {
  local id="$1" message="$2"
  validate_id "$id"

  local state
  state="$(read_state "$id")"
  state=$(echo "$state" | jq --arg msg "$message" '.status = "failed" | .error = $msg')

  write_state "$id" "$state"
  echo "$state" | jq '.'
}

cmd_complete() {
  local id="$1"
  validate_id "$id"

  local state
  state="$(read_state "$id")"
  state=$(echo "$state" | jq --arg now "$(now_iso)" '.status = "complete" | .completedAt = $now')

  write_state "$id" "$state"
  echo "$state" | jq '.'
}

cmd_set_pr() {
  local id="$1" pr_number="$2" branch="$3"
  validate_id "$id"

  local state
  state="$(read_state "$id")"
  state=$(echo "$state" | jq \
    --argjson pr "$pr_number" \
    --arg branch "$branch" \
    '.prNumber = $pr | .branch = $branch')

  write_state "$id" "$state"
  echo "$state" | jq '.'
}

cmd_phase_count() {
  local id="$1"
  validate_id "$id"

  # Find the implementation plan
  local plan_file
  plan_file=$(find "$PROJECT_ROOT/requirements/implementation" -name "${id}-*.md" -type f 2>/dev/null | head -1)

  if [[ -z "$plan_file" ]]; then
    echo "Error: No implementation plan found for \"$id\" in requirements/implementation/" >&2
    exit 1
  fi

  # Count phase headings (### Phase N: Title)
  local count
  count=$(grep -cE '^### Phase [0-9]+:' "$plan_file" || true)

  if [[ "$count" -eq 0 ]]; then
    echo "Error: Implementation plan for \"$id\" contains zero phases. The plan may be malformed." >&2
    exit 1
  fi

  # Read current state
  local state
  state="$(read_state "$id")"

  local current_type
  current_type=$(echo "$state" | jq -r '.type')

  if [[ "$current_type" == "feature" ]]; then
    # Build phase steps
    local phase_steps="[]"
    for ((i = 1; i <= count; i++)); do
      phase_steps=$(echo "$phase_steps" | jq \
        --argjson phase "$i" \
        --argjson total "$count" \
        '. + [{"name": "Implement phase \($phase) of \($total)", "skill": "implementing-plan-phases", "context": "fork", "status": "pending", "phaseNumber": $phase}]')
    done

    # Get post-phase steps
    local post_steps
    post_steps="$(feature_post_phase_steps)"

    # Append phase steps and post-phase steps to existing steps
    state=$(echo "$state" | jq \
      --argjson phase_steps "$phase_steps" \
      --argjson post_steps "$post_steps" \
      --argjson total "$count" \
      '.steps = .steps + $phase_steps + $post_steps | .phases.total = $total')

    write_state "$id" "$state"
  fi

  echo "$count"
}

cmd_phase_status() {
  local id="$1"
  validate_id "$id"

  local state
  state="$(read_state "$id")"
  echo "$state" | jq '[.steps[] | select(has("phaseNumber")) | {phase: .phaseNumber, status: .status}]'
}

# --- Dispatcher ---

usage() {
  cat <<'EOF'
Usage: workflow-state.sh <command> [arguments]

Commands:
  init <ID> <type>              Create state file (type: feature, chore, bug)
  status <ID>                   Return current state as JSON
  advance <ID> [artifact-path]  Mark current step complete, advance to next
  pause <ID> <reason>           Set status to paused
  resume <ID>                   Resume from paused/failed state
  fail <ID> <message>           Set status to failed with error
  complete <ID>                 Mark workflow as complete
  set-pr <ID> <pr-number> <branch>  Record PR metadata
  phase-count <ID>              Count phases and populate state
  phase-status <ID>             Return per-phase completion status
EOF
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
shift

case "$command" in
  init)
    [[ $# -ge 2 ]] || { echo "Error: init requires <ID> <type>" >&2; exit 1; }
    cmd_init "$1" "$2"
    ;;
  status)
    [[ $# -ge 1 ]] || { echo "Error: status requires <ID>" >&2; exit 1; }
    cmd_status "$1"
    ;;
  advance)
    [[ $# -ge 1 ]] || { echo "Error: advance requires <ID>" >&2; exit 1; }
    cmd_advance "$1" "${2:-}"
    ;;
  pause)
    [[ $# -ge 2 ]] || { echo "Error: pause requires <ID> <reason>" >&2; exit 1; }
    cmd_pause "$1" "$2"
    ;;
  resume)
    [[ $# -ge 1 ]] || { echo "Error: resume requires <ID>" >&2; exit 1; }
    cmd_resume "$1"
    ;;
  fail)
    [[ $# -ge 2 ]] || { echo "Error: fail requires <ID> <message>" >&2; exit 1; }
    cmd_fail "$1" "$2"
    ;;
  complete)
    [[ $# -ge 1 ]] || { echo "Error: complete requires <ID>" >&2; exit 1; }
    cmd_complete "$1"
    ;;
  set-pr)
    [[ $# -ge 3 ]] || { echo "Error: set-pr requires <ID> <pr-number> <branch>" >&2; exit 1; }
    cmd_set_pr "$1" "$2" "$3"
    ;;
  phase-count)
    [[ $# -ge 1 ]] || { echo "Error: phase-count requires <ID>" >&2; exit 1; }
    cmd_phase_count "$1"
    ;;
  phase-status)
    [[ $# -ge 1 ]] || { echo "Error: phase-status requires <ID>" >&2; exit 1; }
    cmd_phase_status "$1"
    ;;
  *)
    echo "Error: Unknown command \"$command\"" >&2
    usage
    ;;
esac
