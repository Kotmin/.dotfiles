---
name: install-adt
description: Install agent-observability (adt) into another project — copies the .agent-observability scaffold, hook, config, and wires the Claude Code hook. Trigger phrases: "install-adt into <path>", "add adt to my project", "set up observability in <path>".
version: 1.0.0
---

# install-adt Skill

Install the `agent-observability` decision-tracing layer into another project.

## When This Skill Applies

- "install-adt into \<path\>"
- "add adt to my project"
- "set up observability in \<path\>"
- "add decision tracing to \<path\>"
- "wire the adt hook into \<path\>"

## Parameters

- `[target-path]` — absolute path to the target project root (required)

If not provided, ask for it before proceeding.

## Execution Steps

### 1. Validate target

Check that `[target-path]` exists and is a directory. If not, stop and tell the user.

```bash
test -d "[target-path]" || echo "ERROR: target path does not exist"
```

### 2. Copy the scaffold

Copy the `.agent-observability/` directory from the source repo into the target, **skipping** the `traces/` subdirectory (never copy trace data):

```bash
ADT_SOURCE="/home/kotmin/Coding/Skill-document-decission"
TARGET="[target-path]"

rsync -a --exclude='traces/**' --exclude='*.jsonl' --exclude='*.tmp' \
  "${ADT_SOURCE}/.agent-observability/" \
  "${TARGET}/.agent-observability/"
```

Also copy `AGENT_DECISIONS.md` if it does not already exist in the target:

```bash
if [ ! -f "${TARGET}/AGENT_DECISIONS.md" ]; then
  cp "${ADT_SOURCE}/AGENT_DECISIONS.md" "${TARGET}/AGENT_DECISIONS.md"
fi
```

### 3. Ensure traces directory placeholder exists

```bash
mkdir -p "${TARGET}/.agent-observability/traces"
touch "${TARGET}/.agent-observability/traces/.keep"
```

### 4. Add .gitignore entries

Append to `[target-path]/.gitignore` only if entries are not already present:

```
# agent-observability — exclude trace data, keep directory structure
.agent-observability/traces/*
!.agent-observability/traces/.keep
.agent-observability/**/*.jsonl
.agent-observability/**/*.tmp
```

Check before appending:
```bash
grep -q "agent-observability/traces/\*" "${TARGET}/.gitignore" 2>/dev/null || cat >> "${TARGET}/.gitignore" <<'GITIGNORE'

# agent-observability — exclude trace data, keep directory structure
.agent-observability/traces/*
!.agent-observability/traces/.keep
.agent-observability/**/*.jsonl
.agent-observability/**/*.tmp
GITIGNORE
```

### 5. Install the Python package

If the target project has a virtual environment, install `agent-observability` into it. Otherwise install into the active Python environment:

```bash
VENV="${TARGET}/.venv"
if [ -d "${VENV}" ]; then
  "${VENV}/bin/pip" install -e "/home/kotmin/Coding/Skill-document-decission" --quiet
else
  pip install -e "/home/kotmin/Coding/Skill-document-decission" --quiet
fi
```

### 6. Wire the Claude Code hook

Check if `[target-path]/.claude/settings.json` exists.

**If it does**, add the hook entries (use `jq` or edit manually — do not overwrite existing settings):

```json
{
  "hooks": {
    "PreToolUse": [
      { "command": "python [target-path]/.agent-observability/hooks/decision_trace.py" }
    ],
    "PostToolUse": [
      { "command": "python [target-path]/.agent-observability/hooks/decision_trace.py" }
    ]
  }
}
```

**If it does not exist**, create `.claude/settings.json` with the hook block above.

> **Note:** Always use the absolute path to `decision_trace.py` in the hook command, not a relative path. This ensures it works correctly from any working directory.

### 7. Post-install output

Print the following guidance to the user:

```
agent-observability installed into [target-path]

Files added:
  [target-path]/.agent-observability/   — scaffold (config, hooks, schemas, skills)
  [target-path]/AGENT_DECISIONS.md      — behavior contract
  [target-path]/.claude/settings.json  — hook wiring (PreToolUse / PostToolUse)

Next steps:
  1. Review .agent-observability/config.yml    — adjust flush, retention, logging level
  2. Review .agent-observability/redaction.yml — add project-specific secrets/paths
  3. Open Claude Code in [target-path] — the hook will fire automatically
  4. After a session: adt sessions / adt story <id> / adt decisions <id>

To load the decision-logging skill in Claude Code, say:
  "use skill-document-decision"
```

## Key Rules

- **Never** overwrite `AGENT_DECISIONS.md` if it already exists in the target
- **Never** overwrite `config.yml` or `redaction.yml` if already present in target
- **Never** copy `traces/` or any `.jsonl` files
- **Never** modify git config in the target repo
- Always use **absolute paths** for the hook command in `settings.json`
- Always **quote shell variables** — use `"${VAR}"` not `$VAR`
- Check for existing `.gitignore` entries before appending

## Global Setup (use from any project)

To trigger this skill from any Claude Code session (not just when open in this repo):

```bash
mkdir -p ~/.claude/skills/install-adt
cp /home/kotmin/Coding/Skill-document-decission/skills/install-adt/SKILL.md \
   ~/.claude/skills/install-adt/SKILL.md
```

After copying, say **"install-adt into /path/to/my-project"** from any Claude Code session.
