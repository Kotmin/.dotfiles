---
name: issue-resolve
description: Fetch and complete a single GitHub issue end to end in an isolated worktree, test it, rebase onto dev (dev wins conflicts), merge, and clean up. Decision/status log is posted as comments on the issue itself. Trigger phrases: "build and complete issue #<n>", "resolve issue <n> from gh", "do issue <n>".
version: 1.0.0
disable-model-invocation: true
---

# issue-resolve Skill

Completes one GitHub issue in isolation and merges it into `dev`, with the issue thread itself as the decision/status log.

## When This Skill Applies

- "build and complete issue #<n> from gh"
- "resolve issue <n>"
- "do issue <n> in a worktree"

## Parameters

- `[issue-number]` — required. Reject non-numeric input.
- `[base-branch]` — default `dev`.

## Authorization

Invoking this skill is pre-authorization to push commits and merge into `[base-branch]` without a per-action confirmation prompt.

## Execution Steps

1. Validate `[issue-number]` is numeric. Fetch it: `gh issue view "[issue-number]" --json title,body,labels,comments`, run from the repo root (absolute path).
2. Post a starting comment on the issue (`gh issue comment "[issue-number]"`) noting work has begun. This comment thread is the log for this run — post subsequent decisions and status updates there as they happen, not to a local file.
3. Fetch latest `[base-branch]`. Create a worktree for branch `issue-[issue-number]-<slug>` off it, via `Agent(isolation: "worktree")` or `EnterWorktree`.
4. Implement the fix described by the issue.
5. If the env is needed for testing and not already up, bring the dockerized stack up (absolute path to the compose file, quoted vars); run tests; if you brought it up solely for this run, shut it back down after.
6. Fetch latest `[base-branch]` again and rebase the feature branch onto it. On conflict, `[base-branch]`'s hunks win.
7. Diff the rebased branch against `[base-branch]` to find files actually touched by this work. Stage and commit only those files as one or more atomic commits — never `git add -A`. Skip `.env`, `.git/`, keys, and other sensitive files even if changed; flag instead of committing.
8. Fast-forward merge into `[base-branch]` and push.
9. Post a closing comment on the issue summarizing what shipped and the commit list; reference `Closes #[issue-number]` if the work fully resolves it.
10. Remove the worktree.
11. If a genuine blocking ambiguity comes up (a decision only the user can make, not a test failure), post it as a comment on the issue and stop — this is single-unit work, there's no next milestone to fall through to.

## Constraints

- All shell variables quoted (`"$VAR"`), all script/compose paths absolute.
- Worktree and file operations stay within the repo root — never traverse outside it.
- No comments in generated code unless the user explicitly asked for them.
- Commit messages describe the change; do not mention Claude or this skill.
- If `gh issue comment` fails (no remote/no access), fall back to a repo-tracked log at `.claude/issue-resolve/issue-[issue-number].md` and say so.
