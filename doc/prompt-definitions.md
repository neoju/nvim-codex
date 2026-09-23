# Prompt Definitions

Command definitions live in `lua/nvimcodex/prompt/definitions/commands/` and
modifier definitions in `lua/nvimcodex/prompt/definitions/modifiers/`, one
Markdown file per entry. The filename is its token name. Header values use JSON
strings or booleans. The three prompt attributes are `primary_goal`,
`primary_output`, and `primary_boundaries`. Context comes from the selected
files or captured location.

A command may also put special instructions after the closing `---`. They
appear as `General: <text>` before the attributes in the sent prompt. The
attributes take priority if they conflict with General. For multiline special
instructions, continuation lines are indented under `General:` so they stay
distinct from the attributes. Modifiers may set only the three prompt
attributes, plus description and usage metadata; they cannot add special
instructions. A modifier's goal or output replaces the corresponding command
attribute. Boundaries accumulate in token order, so a modifier cannot remove
an existing restriction such as `Do not modify files.`

```markdown
---
des: "Answer a request without editing files"
primary_goal: "Answer the user's question."
primary_output: "A direct answer."
primary_boundaries: "Do not modify files."
---
Explain the reasoning when it helps.
```

Sent prompts place the attributes, `$skill` tokens, and file context in an
`<INSTRUCTIONS>` block, followed by the request in a `<USER_PROMPT>` block.
Each `@name` starts a task. Each `#name` attaches a modifier to the current
task without starting another task. For example, `@buffer #scoped` targets the
current file and limits edits to it. A `#name` before the first command attaches
to the first task. Separate tasks include guidance to run non-conflicting work
in parallel and consider separate worktrees for concurrent edits.

The built-in commands are `@ask`, `@buffer`, `@diagnose`, `@explain`, `@fix`,
and `@test`. The built-in modifiers are `#brief`, `#readonly`, and `#scoped`.
`@diagnose` and `@ask` keep the task read-only even when `#scoped` is attached.
`@fix` asks for diagnosis, a fix, and verification of the change.
`@test` asks for meaningful tests of the selected behavior and a report of
what they cover.

Each `$skill` applies to the task command before it, or to the first task if it
appears before any task command. The command parser always returns a task list,
including for a plain request; the formatter renders either one task or several
from that list.
