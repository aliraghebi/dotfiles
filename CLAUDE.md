# Claude Code Configuration — dotfiles CLI

@PROJECT.md

## Behavioral Rules (Always Enforced)

- Do what has been asked; nothing more, nothing less
- NEVER create files unless absolutely necessary for the goal
- ALWAYS prefer editing an existing file to creating a new one
- NEVER proactively create documentation or README files unless explicitly requested
- ALWAYS read a file before editing it
- NEVER commit secrets, credentials, or .env files

## Project Overview

Personal dotfiles manager for macOS and Ubuntu/Linux.
Repo lives at `~/.dotfiles`. Single CLI entry point at `bin/dotfiles`.
This is a **pure Bash project** — no npm, no Node, no build step.

## Build & Test

```bash
# Run the full test suite
bash tests/run_all.sh

# Run a specific test file
bash tests/test_<module>.sh

# Smoke-test a command manually
dotfiles install <app>
dotfiles config <app>
dotfiles remove <app>
dotfiles list
```

- ALWAYS run `bash tests/run_all.sh` after making changes to any `lib/*.sh` file
- NEVER use `npm test`, `npm run build`, or any npm command — this is not an npm project

## Ruflo Agent Orchestration

### When to use agents

Use Ruflo swarm/agents for tasks that span multiple files or modules concurrently:
- Adding a new app (meta.sh + install.sh + config.sh + tests in parallel)
- Refactoring a lib file + updating all affected tests simultaneously
- Auditing all `apps/` for consistency across meta.sh structure

For small single-file edits, use Claude Code directly — no swarm needed.

### Swarm setup for this project

```bash
npx @claude-flow/cli@latest swarm init --topology hierarchical --max-agents 6 --strategy specialized
```

- Topology: **hierarchical** (anti-drift, tight coordination)
- Max agents: **6** (sufficient for this repo's scope)
- Keep a shared memory namespace for all agents

### Agent roles relevant to this project

| Role | When to use |
|------|-------------|
| `coder` | Implementing new app modules or lib functions |
| `tester` | Writing or updating `tests/test_*.sh` files |
| `reviewer` | Checking bash compatibility, coding standards |
| `researcher` | Exploring existing app structure before making changes |

### Concurrency rules

- All related operations in ONE message — batch file reads, writes, and Bash calls together
- Spawn ALL agents in ONE message with full instructions via Agent tool
- Use `run_in_background: true` for all Agent tool calls
- After spawning, STOP — do NOT check status repeatedly, wait for results
- ALWAYS use CLI tools AND Agent tool together in ONE message for complex work

### 3-Tier Model Routing

| Tier | Model | Use for |
|------|-------|---------|
| 1 | Direct edit (no LLM) | Simple variable renames, formatting fixes |
| 2 | Haiku | Simple lib function additions, meta.sh edits |
| 3 | Sonnet/Opus | Architecture decisions, reconciliation logic, state machine changes |

## Memory

```bash
# Store a discovered pattern
npx @claude-flow/cli@latest memory store --key "pattern-<name>" --value "..." --namespace patterns

# Search before implementing something new
npx @claude-flow/cli@latest memory search --query "bash symlink reconcile"
```

Always search memory before implementing patterns that may have been solved before
(e.g. backup logic, OS detection edge cases).

## Security Rules

- NEVER hardcode paths that assume a specific username
- NEVER write to the repo tree from tests — always use `mktemp -d`
- Always validate file paths to prevent directory traversal in link operations
- Use `$SUDO_USER` (not `$HOME`) when resolving user home under sudo

## Key MCP Tools

Use `ToolSearch("keyword")` to discover available tools at runtime.

```
ToolSearch("memory search")   → memory_store, memory_search, memory_search_unified
ToolSearch("swarm")           → swarm_init, swarm_status, swarm_health
ToolSearch("agent")           → agent_spawn, agent_list, agent_status
ToolSearch("hooks")           → hooks_session-start, hooks_post-task
```

## Quick Ruflo Setup (first time)

```bash
claude mcp add ruflo -- npx -y @claude-flow/cli@latest mcp start
npx @claude-flow/cli@latest daemon start
npx @claude-flow/cli@latest doctor --fix
```

## Support

- Ruflo docs: https://github.com/ruvnet/ruflo
- Project repo: https://github.com/aliraghebiii/dotfiles