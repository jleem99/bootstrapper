## Workflow Orchestration

### 0. Ouroboros Command Boundary
- `ooo interview` is clarification only. It must never create or edit files, generate Seeds, run Seeds, or execute implementation work.
- Treat `ouroboros_interview` seed-ready output as provisional. Before suggesting `ooo seed`, run the host-side closure gate: restate the goal, non-goals, constraints, and acceptance criteria, then require explicit user approval.
- Route scope, file structure, output format, tradeoff, acceptance-criteria, and execution-plan decisions to the user. Only answer repo-local factual questions from exact inspection.
- `ooo seed` is the Seed-generation path after explicit approval. `ooo run` is the execution path. Do not collapse interview, seed, and run into one step unless the user explicitly invokes `ooo auto`.

### 1. Plan Node Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions).
- If something goes sideways, STOP and re-plan immediately. Do not keep pushing.
- Use plan mode for verification steps, not just building.
- Write detailed specs upfront to reduce ambiguity.

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean.
- Offload research, exploration, and parallel analysis to subagents.
- For complex problems, throw more compute at it via subagents.
- One tack per subagent for focused execution.

### 3. Self-Improvement Loop
- After a user correction, update `tasks/lessons.md` by first mapping the correction to the closest existing rule.
- Strengthen an existing rule if it would not have prevented the mistake.
- Add a new lesson only when no existing rule covers a reusable failure mode.
- Keep `tasks/lessons.md` compact: durable rules only, no incident log.
- Review lessons at session start for relevant project.

### 4. Verification Before Done
- Never mark a task complete without proving it works.
- Diff behavior between main and your changes when relevant.
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness.

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution."
- Skip this for simple, obvious fixes. Do not over-engineer.
- Challenge your own work before presenting it.

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Do not ask for hand-holding.
- Point at logs, errors, failing tests, then resolve them.
- Zero context switching required from the user.
- Go fix failing CI tests without being told how.

## Task State File Hygiene

- `tasks/todo.md` is live state, not a transcript.
- Keep exactly one active objective in `tasks/todo.md`.
- Allowed live sections: Current Objective, Active Blockers, Next Actions, Current Verification, Current Review.
- Target max: 80 lines; hard max: 120 lines unless the user explicitly asks otherwise.
- When starting a new objective, archive or summarize the previous objective before replacing the live tracker. Use `tasks/archive/NN_<topic>.md` for archived tracker history.
- Do not append Prior Objective, repeated dispatch logs, validation transcripts, or historical review chains.
- Detailed specs belong in task files, Seeds, memos, or dedicated artifacts, not in `tasks/todo.md`.
- Archive files may retain history; the live tracker must stay small.

## Task Management

1. **Plan First**: Write a short checkable plan to `tasks/todo.md`; put detailed specs in task files, Seeds, memos, or dedicated artifacts.
2. **Verify Plan**: Check in before starting implementation.
3. **Track Progress**: Update the current checklist in place; do not append new transcript sections.
4. **Explain Changes**: High-level summary at each step.
5. **Document Results**: Maintain one concise Current Review section in `tasks/todo.md`, not one review block per subtask.
6. **Capture Lessons**: Map corrections to existing `tasks/lessons.md` rules first; add a new rule only for reusable failure modes.

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what is necessary. Avoid introducing bugs.
