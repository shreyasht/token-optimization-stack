# Awesome Token Optimization Stack

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com) [![Stack](https://img.shields.io/badge/Stack-Open%20Source-blue.svg)](TOKEN_OPTIMIZATION_STACK.md)

## Table of Contents

- [Stack Overview](#stack-overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [1. Graphify — Codebase Knowledge Graph](#1-graphify--codebase-knowledge-graph)
- [2. Serena — Symbol-Level Navigation & Editing](#2-serena--symbol-level-navigation--editing)
- [3. LeanCTX — Context Intelligence Layer](#3-leanctx--context-intelligence-layer)
- [4. Caveman — Output Compression Skill](#4-caveman--output-compression-skill)
- [5. Agentsview — Token & Trace Monitoring](#5-agentsview--token--trace-monitoring)
- [Recommended Setup Order](#recommended-setup-order)
- [Stacking Notes](#stacking-notes)
- [Quick Validation](#quick-validation)
- [Troubleshooting](#troubleshooting)
- [Agent Instructions](#agent-instructions)
- [References](#references)

---

## Stack Overview

| Layer | Tool | What It Does | Token Savings |
|-------|------|-------------|---------------|
| Codebase Intelligence | **Graphify** | Knowledge graph from AST parsing; agents query structure instead of reading files | 7–70x fewer input tokens |
| Codebase Intelligence | **Serena** | Symbol-level navigation and editing on top of LSP (find_symbol, rename_symbol) | ~50ms precise symbol operations |
| Input Compression | **LeanCTX** | Rust-based context layer; compressed reads, caching, agent memory | 60–90% fewer input tokens |
| Output Compression | **Caveman** | Claude Code skill that rewrites model output into terse language | ~65% fewer output tokens |
| Monitoring | **Agentsview** | Observability platform for tracking token budgets and agent traces | Visibility, not direct savings |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Your AI Coding Agent                  │
│              (Claude Code / Cursor / Codex)              │
└─────────────┬───────────────────────────────┬───────────┘
              │ queries                       │ LLM calls
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│   CODEBASE INTELLIGENCE │     │   COMPRESSION LAYER     │
│                         │     │                         │
│  Graphify (knowledge    │     │  LeanCTX (input+cache)  │
│    graph queries)       │     │  Caveman (output)       │
│  Serena (symbol-level  │     │                         │
│    edit & nav)          │     │                         │
└─────────────────────────┘     └────────────┬────────────┘
                                             │
                              ┌────────────▼────────────┐
                              │   MONITORING            │
                              │  Agentsview (budget +   │
                              │   cost tracking)        │
                              └─────────────────────────┘
```

## Prerequisites

- Python 3.10+ and pip (or [uv](https://github.com/astral-sh/uv) recommended)
- Node.js 18+ and npm
- An AI coding agent (Claude Code, Cursor, Codex, Gemini CLI, etc.)

---

## 1. Graphify — Codebase Knowledge Graph

**What:** Parses your codebase with tree-sitter (28+ languages) and builds a queryable knowledge graph. Agents query the graph instead of reading raw files.

**Why first:** The graph is a one-time build that every subsequent tool and agent session benefits from. It replaces the most expensive operation agents do — exploratory file reads.

### Install

```bash
# Recommended: uv (fastest)
uv tool install graphifyy

# Alternative: pipx (handles PATH automatically on macOS/Windows)
pipx install graphifyy

# Alternative: pip
pip install graphifyy
```

### Setup

```bash
# Install the skill for your AI agent
graphify install

# Build the knowledge graph for your project
cd /path/to/your/project
graphify build .

# Verify the graph was created
graphify query "list all modules"
```

### Integration with AI agents

Graphify auto-detects and installs skills for Claude Code, Cursor, Codex, Gemini CLI, GitHub Copilot CLI, and 15+ other agents during `graphify install`.

For Claude Code specifically:
```bash
# The skill is installed to ~/.claude/skills/graphify/
# Verify with:
ls ~/.claude/skills/graphify/
```

### Keeping the graph current

Add to your CI pipeline or pre-session script:
```bash
graphify build . --incremental  # Rebuilds only changed files
```

### Key commands for agents

```
graphify query "what calls authenticate_user?"
graphify query "show dependencies of src/auth/"
graphify query "identify god nodes"          # Most-connected entities
graphify impact-analysis <branch>            # PR impact analysis
```

---

## 2. Serena — Symbol-Level Navigation & Editing

**What:** An open-source coding agent toolkit that gives agents IDE-like semantic understanding. It exposes symbol-level operations (`find_symbol`, `rename_symbol`, `insert_after_symbol`) instead of raw file reading.

**Why:** Instead of grepping for strings and replacing lines via diffs, agents can navigate and edit code precisely by symbol, massively reducing context usage and minimizing syntax errors.

### Install

```bash
# Recommended: uv tool install (matches upstream instructions)
uv tool install serena-agent

# Alternative: pip
pip install serena-agent
```

### Configure for AI Agents

Serena runs as an MCP server, automatically hooking into your local LSP (Python, TS, Rust, Go, etc.).

**Claude Code / Cursor / Cline / Roo Code:**
Add to your MCP settings file:
```json
{
  "mcpServers": {
    "serena": {
      "command": "serena",
      "args": ["serve"],
      "env": {}
    }
  }
}
```

### Usage (Agent Commands)

Once attached, agents should prefer these tools over grep/sed:
- `find_symbol`: Locate definitions across the codebase
- `find_referencing_symbols`: Find where a class/function is used
- `rename_symbol`: Safely refactor across files
- `insert_after_symbol`: Semantically add code without line-number guesswork

> **Note on pure LSP:** If you want raw LSP tools (like standard go-to-def) without Serena's editing layer, you can use the lightweight [mcp-language-server](https://github.com/isaacphi/mcp-language-server).

---

## 3. LeanCTX — Context Intelligence Layer

**What:** A single Rust binary that controls what AI agents read, compresses context, caches repeated reads (~13 tokens on re-read), manages agent memory, and provides 76 MCP tools.

**Why:** 60–90% fewer tokens. Compressed git status drops from ~800 to ~120 tokens.

### Install

```bash
# Universal install script — pinned to a release tag, not a floating branch
curl -fsSL https://raw.githubusercontent.com/yvgude/lean-ctx/v3.9.19/install.sh | sh

# Homebrew
brew tap yvgude/lean-ctx && brew install lean-ctx

# Cargo (from source)
cargo install lean-ctx
```

**Verify without piping to shell:** each release publishes `SHA256SUMS`, a detached signature (`SHA256SUMS.sig`), a cert (`SHA256SUMS.pem`), and an SBOM. Download the binary for your platform plus `SHA256SUMS` from the [releases page](https://github.com/yvgude/lean-ctx/releases), then:
```bash
sha256sum -c SHA256SUMS --ignore-missing
```

### Setup

```bash
# One-command setup: installs hooks, MCP registration, starts daemon
lean-ctx setup

# Verify everything is connected
lean-ctx doctor
```

`lean-ctx setup` will:
- Snapshot existing config files (for rollback)
- Install shell hooks
- Write MCP server registration for your detected editors
- Install agent hooks
- Start the daemon
- Probe the MCP server connection

### Auto-detected editors

LeanCTX auto-configures for Cursor, Claude Code, CodeBuddy, GitHub Copilot, Windsurf, VS Code, Zed, and others. No manual MCP config needed.

---

## 4. Caveman — Output Compression Skill

**What:** Claude Code skill that instructs the model to rewrite its responses in terse, information-dense language. ~65% fewer output tokens on average; some responses drop 80%+.

**Why:** Shorter output feeds back into conversation history. Every token saved in output saves that token again on every subsequent step.

### Install

```bash
# One-line install — pinned to a release tag, not a floating branch
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/v2.1.0/install.sh | bash

# Alternative: npm
npm install -g @caveman-ai/cli && caveman setup --install

# Alternative: Claude plugin marketplace
claude plugin marketplace add JuliusBrussee/caveman
claude plugin install caveman@caveman
```

Restart Claude Code after installation.

**Verify without piping to shell:** each release publishes `checksums.txt` and a detached signature (`checksums.txt.keysig`) alongside the platform binaries. Download the binary for your platform plus `checksums.txt` from the [releases page](https://github.com/JuliusBrussee/caveman/releases), then:
```bash
sha256sum -c checksums.txt --ignore-missing
```

### Usage

```
/caveman full       # Default compression (recommended starting point)
/caveman lite       # Light trimming
/caveman ultra      # Maximum density
/caveman off        # Disable

/caveman-commit     # Minimal commit messages
/caveman-review     # One-line PR feedback
/caveman-compress   # Compress a memory file or CLAUDE.md section
```

### Verify

Run a verbose prompt with and without Caveman enabled. Compare output token counts in the Claude Code status bar or via Agentsview.

---

## 5. Agentsview — Token & Trace Monitoring

**What:** Open-source observability and tracing platform specifically designed for AI coding agents. Captures real-time token spend per turn, full tool execution trees, context bloat breakdowns, and latency per provider.

**Why:** You can't optimize what you can't measure. Agentsview exposes exactly which tool calls, AST queries, or file reads are dominating your context window before they compound into massive token bills.

### Install

```bash
# Recommended: install via pip / uv
pip install agentsview
```

### Configure

Initialize Agentsview in your project workspace:

```bash
# Create local .agentsview config
agentsview init

# (Optional) Set your monitoring endpoint if using a centralized server
export AGENTSVIEW_ENDPOINT=http://localhost:8080
```

### Integration with AI agents

**Mode 1: CLI Agent Wrapper (Claude Code, Aider, Codex)**
```bash
# Wrap agent command to intercept and trace token telemetry
agentsview wrap claude

# Or launch directly with active session tracing
agentsview run aider
```

**Mode 2: MCP Server (Cursor, Windsurf, Claude Desktop)**
Add Agentsview to your MCP server configuration:
```json
{
  "mcpServers": {
    "agentsview": {
      "command": "agentsview",
      "args": ["mcp"],
      "env": {}
    }
  }
}
```

### Key Features & Dashboard

- **Turn-by-Turn Token Inspector:** Identifies repetitive system prompt injections and payload bloat.
- **Budget Threshold Alerts:** Set hard caps (e.g. `agentsview budget --max-session 100k`) to stop runaway agent loops.
- **Tool Call Tracing:** Measures execution latency and token payload per MCP / tool interaction.
- **Cost Analytics:** Tracks spend breakdown across models (Anthropic, OpenAI, local Ollama).

### Verify

```bash
# Verify daemon and agent hooks are running
agentsview doctor

# Open real-time web dashboard
agentsview dashboard --port 3000
```

---

## Recommended Setup Order

The tools are listed above in dependency order. Here's the recommended sequence:

1. **Graphify** — Build the knowledge graph first. Every subsequent session benefits.
2. **Serena** — Add symbol-level navigation and editing. Complements Graphify's structural queries.
3. **LeanCTX** — Add context caching, compressed reads, and agent memory.
4. **Caveman** — Compress output tokens. Independent of input-side tools.
5. **Agentsview** — Start monitoring to see where tokens actually go.

## Stacking Notes

- **Graphify + Serena** complement each other: Graphify for "what depends on X?" (structural), Serena for precise symbol editing and navigation.
- **Caveman** is independent of all input-side tools — it only affects output. Always safe to add.

## Quick Validation

After setting up the full stack, run a representative task and compare:

```bash
# Before stack (baseline)
# Note: total tokens from your agent's status bar or API response headers

# After stack
# Compare: input tokens, output tokens, total cost, task completion time
```

Expected improvements on a large codebase (10K+ files):
- Input tokens: reduction from Graphify + LeanCTX (magnitude depends on task — verify per-tool via `BENCHMARKING.md`'s ablation methodology rather than assuming these figures)
- Output tokens: ~65% reduction (Caveman)
- Navigation speed: 10–100x faster (Serena/LSP)

## Troubleshooting

| Problem | Likely Cause | Fix |
|---------|-------------|-----|
| Graphify build fails | Unsupported file types in repo | Add to `.graphifyignore` |
| LeanCTX daemon not starting | Port conflict | Check `lean-ctx doctor` output |
| Caveman not activating | Skill not in Claude Code skills dir | Re-run install, restart Claude Code |

## Agent Instructions

> **For AI agents reading this document:** This is a token optimization stack. When setting up a new environment, install tools in the order listed under "Recommended Setup Order." Run each verification step before proceeding to the next tool. If a tool fails to install, skip it and continue — the tools are independent and any subset provides value. After setup, prefer Graphify queries and Serena symbol tools over raw file reads. LeanCTX and Caveman require no behavioral changes — they work transparently once installed.

## References

- [Graphify](https://github.com/Graphify-Labs/graphify) — Codebase knowledge graph
- [Serena](https://github.com/oraios/serena) — Semantic symbol-level editing via LSP/MCP
- [LeanCTX](https://github.com/yvgude/lean-ctx) — Context intelligence layer
- [Caveman](https://github.com/JuliusBrussee/caveman) — Output token compression skill
- [Agentsview](https://github.com/kenn-io/agentsview) — Token budget monitoring and tracing
