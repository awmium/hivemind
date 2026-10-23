<!-- brain:start -->
# Brain — global memory (all projects)

The consolidated master of my persistent memory lives at:
`C:\CHANGE-ME\Brain\`
(index: `BRAIN.md` there). The per-project auto-memory dirs stay the harness-loaded
working copies; a SessionEnd hook mirrors them into `Brain\projects\` automatically
and keeps every deleted or overwritten note, from projects/ and global/ alike, in
`Brain\archive\` as `<note> (deleted|replaced YYYY-MM-DD).md`.

**Recall:** when context is missing — who I am, machine quirks, standing
preferences, a project this session's auto-memory doesn't cover — check
`Brain\global\` and the relevant `Brain\projects\<name>\` folder before asking
or guessing. `Brain\BRAIN.md` lists what global/ holds.
If the current Brain does not have it, or I ask what was known before or what
changed, search `Brain\archive\` (`archive-log.txt` lists every entry by date).
Present anything found there as historical: say when it was deleted or
replaced, and never treat it as current without checking.

**Write:**
- A fact that applies across projects (user, machine, standing feedback,
  cross-project reference) goes to `Brain\global\` as its canonical home, using
  the standard memory frontmatter (name, description, metadata.type). Also save
  it to the session's auto-memory if it's useful there; if copies exist in both,
  update global/ first and refresh the copy.
- Project-specific memories go to the session's auto-memory dir as usual — the
  hook mirrors them; never hand-write into `Brain\projects\` (it is /MIR'd and
  manual edits there get overwritten or deleted).
<!-- brain:end -->
