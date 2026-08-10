---
name: feedback-loop
description: Autonomous multi-milestone dev loop. Main thread acts as branch-master over git worktrees and subagents, cycling build->test->verify->push->document per milestone, batching blocking questions instead of stalling. Trigger phrases: "run in feedback loop mode", "branch master mode", "milestone loop", "run the milestones one by one".
version: 1.0.0
disable-model-invocation: true
---

# feedback-loop Skill

Autonomous milestone loop. One branch-master instance (the invoking thread) is mandatory and owns all merges/pushes; per-milestone work happens in isolated worktrees.

## When This Skill Applies

- "run in feedback loop mode"
- "act as branch master, run these milestones"
- "loop through milestones: build, test, push"

## Parameters

- `[milestones]` — ordered list of goals, or a path to a plan file. Required. If absent, ask for it before proceeding — do not invent milestones.
- `[base-branch]` — target branch merges land on. Default: current branch.
- `[docs-target]` — where per-milestone documentation is written. If unspecified, ask once at start; do not guess a docs location.

## Authorization

Invoking this skill is pre-authorization to push commits and merge into `[base-branch]` without a per-action confirmation prompt. This overrides the default push-confirmation behavior for the duration of the loop only.

## Execution Steps

1. Register each milestone as a task (`TaskCreate`) so progress is visible.
2. For each milestone, in order:
   a. Spawn an implementation subagent with `Agent(isolation: "worktree")`, scoped to that one milestone, branched off the latest `[base-branch]`.
   b. Subagent builds, runs the project's actual test/verify commands (discover from the repo — package.json, Makefile, etc; never assume a command exists), and reports pass/fail plus a diff summary.
   c. Branch-master reviews the result. Reject and re-spawn on the same milestone if build/tests fail; do not merge failing work.
   d. On success: rebase the worktree branch onto the latest `[base-branch]` (fetch first). On conflict, `[base-branch]`'s hunks win.
   e. Diff the rebased branch against `[base-branch]` to determine which files actually changed for this milestone. Stage and commit only those files, as one or more atomic commits — never `git add -A`. Skip `.env`, `.git/`, keys, and other sensitive files even if they appear changed; flag instead of committing.
   f. Fast-forward merge into `[base-branch]` and push.
   g. Append a short entry to `[docs-target]` describing what shipped for this milestone.
   h. Remove the worktree (`ExitWorktree` / worktree cleanup) regardless of outcome.
   i. Mark the task done (`TaskUpdate`).
3. If a milestone surfaces a blocking ambiguity (not a test failure — a decision only the user can make):
   - If the milestone maps to an existing GH issue, log the question as a comment on that issue (`gh issue comment <n>`).
   - Otherwise, append it to `.claude/feedback-loop/questions.md` in the repo (repo-tracked, create if missing).
   - Do not block the loop: mark that milestone blocked and continue to the next one.
4. After all milestones are attempted (shipped or blocked), stop and summarize: what merged, what's pending an answer, and where each question was logged.
5. On resume with answers supplied, resolve logged questions first (delete/check them off), then continue with any remaining milestones.

## Constraints

- All shell variables quoted (`"$VAR"`), all script/tool paths absolute.
- Worktree and file operations stay within the repo root that was checked out for this loop — never traverse outside it via `..` or absolute paths pointing elsewhere.
- No comments in generated code unless the user explicitly asked for them.
- Commit messages describe the change; do not mention Claude or this skill.
