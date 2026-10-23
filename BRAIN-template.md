---
title: Brain — Claude Memory
---

# Brain — Claude Memory

Consolidated master of Claude's persistent memory across all projects on this
machine. The per-project auto-memory dirs under
C:\Users\CHANGE-ME\.claude\projects\*\memory\ remain the harness-loaded working
copies; this folder is the human-browsable, OneDrive-synced master and backup.

## Layout

- **global/** — memories that apply across every project: who I am, machine
  facts, standing feedback, cross-project references. Written directly by
  Claude or by me. Canonical home for any fact that is not project-specific.
- **projects/** — one folder per project, a machine-managed mirror of that
  project's auto-memory dir. Do not edit here; edit the source auto-memory dir
  and the mirror follows.
- **archive/** — append-only history, never pruned. Every note that disappears
  or changes, in projects/ or global/, keeps its previous version here as
  `<note> (deleted|replaced YYYY-MM-DD).md`; archive-log.txt lists every entry
  by date. Written only by the hook.
- **.state/** — the hook's last-seen copy of global/, used only to detect what
  changed. Hidden; never read or edit it.
- **last-backup.txt** — timestamp, scope and archived count of the most recent
  sync.

## How it syncs

A SessionEnd hook in C:\Users\CHANGE-ME\.claude\settings.json runs
C:\Users\CHANGE-ME\.claude\scripts\brain-backup.ps1 at the end of every Claude
Code session. It robocopy /MIR's each non-empty project memory dir into
projects/, so projects/ always shows only current memory. Before anything is
deleted or overwritten, its previous version is copied into archive/. global/
is never modified by the hook, only compared against .state/ so its deletions
and edits land in archive/ too.

Recall order: current folders first; archive/ only when the current Brain lacks
the fact or the question is about what was known before.

To give a new project a friendly folder name, extend the $friendlyNames table
in brain-backup.ps1; unknown projects fall back to their raw sanitized name.

## Rules (also in the global CLAUDE.md)

- A memory that applies across projects lives canonically in global/. If a
  per-project copy exists, update global/ first and refresh the copy.
- projects/ is written only by the hook. global/ is written only by Claude or me.
- Each memory file keeps the standard frontmatter (name, description,
  metadata.type) so it works both here and in auto-memory.

## Global index

(list the files in global/ here, one line each, as you add them)
