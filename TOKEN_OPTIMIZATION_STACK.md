# Awesome Token Optimization Stack

[![Awesome](https://awesome.re/badge.svg)](https://awesome.re)

A step-by-step guide to setting up an open-source token optimization stack for AI-assisted coding on large codebases. Designed for developers and AI agents alike — each tool includes install commands, verification steps, and configuration for common AI coding assistants.

## Stack Overview

| Layer | Tool | What It Does | Token Savings |
|-------|------|-------------|---------------|
| Codebase Intelligence | **Graphify** | Knowledge graph from AST parsing; agents query structure instead of reading files | 7–70x fewer input tokens |
| Codebase Intelligence | **LSP via MCP** | Compiler-grade navigation (go-to-def, references, diagnostics) for agents | ~50ms vs 45s grep; precise results |
| Codebase Intelligence | **Continue.dev** | Embedding-based RAG retrieval; returns relevant chunks, not whole files | 60–80% fewer input tokens |
| Input Compression | **Headroom** | Compresses tool outputs, logs, files, RAG chunks before they reach the LLM | 60–95% fewer input tokens |
| Input Compression | **LeanCTX** | Rust-based context layer; compressed reads, caching, agent memory | 60–90% fewer input tokens |
| Output Compression | **Caveman** | Claude Code skill that rewrites model output into terse language | ~65% fewer output tokens |
| Monitoring | **Agentsview** | Observability platform for tracking token budgets and agent traces | Visibility, not direct savings |
| Model Routing | **LiteLLM** | Routes subtasks to cheaper models automatically | 70–75% cost reduction |

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
│  Graphify (knowledge    │     │  Headroom (input)       │
│    graph queries)       │     │  LeanCTX (input+cache)  │
│  LSP/MCP (go-to-def,   │     │  Caveman (output)       │
│    references)          │     │                         │
│  Continue.dev (RAG      │     └────────────┬────────────┘
│    semantic retrieval)  │                  │
└─────────────────────────┘                  ▼
                              ┌─────────────────────────┐
                              │   MODEL ROUTING         │
                              │                         │
                              │  LiteLLM proxy          │
                              │  (Haiku for simple,     │
                              │   Sonnet for moderate,  │
                              │   Opus for complex)     │
                              └────────────┬────────────┘
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
- VS Code or JetBrains IDE (for Continue.dev)
- API keys for your LLM provider(s) (for LiteLLM routing)

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

## 2. LSP via MCP — Compiler-Grade Navigation for Agents

**What:** Exposes Language Server Protocol servers to AI agents via MCP (Model Context Protocol). Gives agents go-to-definition, find-references, diagnostics, and rename capabilities at compiler speed.

**Why:** Returns 23 real call sites instead of 500+ grep matches. Navigation in ~50ms vs 45 seconds.

### Option A: mcp-language-server (multi-language)

```bash
# Clone and build
git clone https://github.com/isaacphi/mcp-language-server.git
cd mcp-language-server
go build -o mcp-language-server .

# Configure for your language server in config.json
```

Add to your MCP config (e.g., Claude Code's `~/.claude/mcp.json`):
```json
{
  "mcpServers": {
    "lsp": {
      "command": "/path/to/mcp-language-server",
      "args": ["--workspace", "/path/to/your/project"],
      "env": {}
    }
  }
}
```

### Option B: LSAP Skill (agent-native)

```bash
# Download the latest release for your agent
# https://github.com/lsp-client/LSAP/releases

# For Claude Code:
# Unzip the skill into your Claude Code skills directory
unzip lsap-skill-latest.zip -d ~/.claude/skills/lsp/
```

### Option C: lsp-skill (Claude Code / Codex / Gemini CLI)

```bash
# Install from the lsp-client org
# https://github.com/lsp-client/lsp-skill
# Follow the agent-specific install instructions in the repo README
```

### Verify

In your AI agent, ask it to:
```
Find all references to the function "handleRequest"
Go to the definition of "UserService"
Show diagnostics for src/api/routes.ts
```

If the agent returns precise, fast results instead of grepping, LSP is working.

---

## 3. Continue.dev — Embedding-Based RAG Retrieval

**What:** Open-source IDE extension that indexes your codebase into embeddings and retrieves only semantically relevant chunks via `@codebase` queries.

**Why:** Instead of loading entire files, the agent gets just the relevant functions and classes. 60–80% fewer input tokens per retrieval.

> **Note:** Continue was acquired by Cursor in June 2026. The final v2.0.0 release still works fully with local models via Ollama.

### Install

**VS Code:**
1. Open VS Code → Extensions → Search "Continue" → Install
2. Or from the command line:
```bash
code --install-extension Continue.continue
```

**JetBrains:**
1. Settings → Plugins → Marketplace → Search "Continue" → Install

### Configure for local embeddings (privacy-preserving)

Edit `~/.continue/config.json`:
```json
{
  "embeddingsProvider": {
    "provider": "ollama",
    "model": "nomic-embed-text",
    "apiBase": "http://localhost:11434"
  },
  "models": [
    {
      "title": "Claude Sonnet",
      "provider": "anthropic",
      "model": "claude-sonnet-4-20250514",
      "apiKey": "YOUR_API_KEY"
    }
  ]
}
```

### Index your codebase

1. Open the Continue sidebar in VS Code
2. Click "Index codebase"
3. Wait for indexing to complete (one-time, updates incrementally)

### Usage

In the Continue chat:
```
Using @codebase, explain how authentication middleware flows in this project
@codebase find all error handling patterns
@codebase what tests cover the payment module?
```

### Setup local embeddings with Ollama

```bash
# Install Ollama if not present
curl -fsSL https://ollama.com/install.sh | sh

# Pull the embedding model
ollama pull nomic-embed-text
```

---

## 4. Headroom — Input Compression Layer

**What:** Sits between your agent and the LLM. Compresses tool outputs, logs, files, and RAG chunks using content-aware algorithms (AST-aware for code, SmartCrusher for JSON, ML model for prose). Reversible — originals cached locally.

**Why:** 60–95% fewer input tokens with no accuracy loss. The `CacheAligner` also stabilizes prompt prefixes to maximize provider-side KV cache hits.

### Install

```bash
# Full install (all compression backends)
pip install "headroom-ai[all]"

# Minimal install (core only)
pip install headroom-ai

# Granular extras
pip install "headroom-ai[proxy]"        # Proxy server
pip install "headroom-ai[ml]"           # ModernBERT text compression
pip install "headroom-ai[proxy,ml]"     # Both
```

### Setup — Choose your integration mode

**Mode 1: Wrap your agent (easiest)**
```bash
# For Claude Code
headroom wrap claude

# For Cursor
headroom wrap cursor

# For VS Code + Claude extension
pip install "headroom-ai[proxy]"
headroom wrap vscode-claude

# For Aider
headroom wrap aider
```

**Mode 2: Transparent proxy (works with any OpenAI-compatible client)**
```bash
headroom proxy --port 8787

# Point your agent/client to http://localhost:8787 instead of the LLM API
```

**Mode 3: Python library (for custom pipelines)**
```python
from headroom import compress

compressed = compress(messages, model="claude-sonnet-4-6")
# Use compressed messages in your API call
```

### Verify

```bash
# Health check
headroom doctor

# View savings after a session
headroom perf

# Live dashboard (proxy must be running)
headroom dashboard
```

---

## 5. LeanCTX — Context Intelligence Layer

**What:** A single Rust binary that controls what AI agents read, compresses context, caches repeated reads (~13 tokens on re-read), manages agent memory, and provides 76 MCP tools.

**Why:** 60–90% fewer tokens. Compressed git status drops from ~800 to ~120 tokens. Works alongside Headroom — LeanCTX operates at the agent level, Headroom at the transport level.

### Install

```bash
# Universal install script (recommended)
curl -fsSL https://leanctx.com/install.sh | sh

# Homebrew
brew tap yvgude/lean-ctx && brew install lean-ctx

# npm
npm install -g lean-ctx-bin

# Cargo (from source)
cargo install lean-ctx
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

## 6. Caveman — Output Compression Skill

**What:** Claude Code skill that instructs the model to rewrite its responses in terse, information-dense language. ~65% fewer output tokens on average; some responses drop 80%+.

**Why:** Shorter output feeds back into conversation history. Every token saved in output saves that token again on every subsequent step.

### Install

```bash
# One-line install
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash

# Alternative: npm
npm install -g @caveman-ai/cli && caveman setup --install

# Alternative: Claude plugin marketplace
claude plugin marketplace add JuliusBrussee/caveman
claude plugin install caveman@caveman
```

Restart Claude Code after installation.

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

## 7. Agentsview — Token & Trace Monitoring

**What:** Observability tool for monitoring AI agent executions, tracking token usage, costs, and providing full trace visibility for tool calls and context windows.

**Why:** You can't optimize what you can't measure. Agentsview makes token spend and agent decision-making visible as you work.

### Install

```bash
pip install agentsview
```

### Configure

```bash
# Initialize in your project
agentsview init
```

### Usage

Agentsview wraps around your agent's execution to monitor LLM calls. It provides a dashboard to see exact token usage per turn, helping you identify which parts of the context window are inflating costs.

```bash
# Run your agent through agentsview
agentsview run claude
```

---

## 8. LiteLLM — Model Routing Proxy

**What:** Unified API gateway that routes LLM requests to different models/providers based on rules. Send simple tasks to cheap models, complex tasks to expensive ones.

**Why:** Haiku costs ~30x less per token than Opus. Routing 70% of subtasks to Haiku cuts total cost to ~25–30% of all-Opus.

### Install

```bash
pip install litellm
```

### Configure

Create `litellm_config.yaml`:
```yaml
model_list:
  - model_name: fast
    litellm_params:
      model: anthropic/claude-haiku-4-5-20251001
      api_key: os.environ/ANTHROPIC_API_KEY

  - model_name: balanced
    litellm_params:
      model: anthropic/claude-sonnet-4-20250514
      api_key: os.environ/ANTHROPIC_API_KEY

  - model_name: powerful
    litellm_params:
      model: anthropic/claude-opus-4-20250514
      api_key: os.environ/ANTHROPIC_API_KEY

router_settings:
  routing_strategy: "usage-based-routing-v2"
  enable_fallbacks: true

general_settings:
  master_key: "sk-your-master-key"
```

### Start the proxy

```bash
litellm --config litellm_config.yaml --port 4000
```

### Point your agent to the proxy

Set your agent's API base to `http://localhost:4000/v1`. The proxy exposes an OpenAI-compatible API.

For Claude Code (via environment variable):
```bash
export ANTHROPIC_BASE_URL=http://localhost:4000/v1
```

### Verify

```bash
# Test the proxy
curl http://localhost:4000/v1/models

# Check spend tracking
curl http://localhost:4000/spend/logs
```

---

## Recommended Setup Order

The tools are listed above in dependency order. Here's the recommended sequence:

1. **Graphify** — Build the knowledge graph first. Every subsequent session benefits.
2. **LSP via MCP** — Add compiler-grade navigation. Complements Graphify's structural queries.
3. **Continue.dev** — Add semantic RAG retrieval for questions Graphify's graph doesn't cover.
4. **Headroom** — Wrap your agent to compress all input. Stacks with everything above.
5. **LeanCTX** — Add context caching and agent memory. Complements Headroom.
6. **Caveman** — Compress output tokens. Independent of input-side tools.
7. **Agentsview** — Start monitoring to see where tokens actually go.
8. **LiteLLM** — Route to cheaper models once you understand your workload patterns.

## Stacking Notes

- **Graphify + LSP** complement each other: Graphify for "what depends on X?" (structural), LSP for "go to definition of X" (precise navigation).
- **Graphify + Continue.dev** complement each other: Graphify for structural queries, Continue for semantic similarity ("code similar to this pattern").
- **Headroom + LeanCTX** are both input-side but operate at different layers. Headroom compresses at the transport level (between agent and LLM API). LeanCTX compresses at the agent level (what the agent reads from disk). They stack.
- **Headroom CacheAligner + prompt caching** stack: CacheAligner stabilizes prompt prefixes so provider-side KV cache hits increase.
- **Caveman** is independent of all input-side tools — it only affects output. Always safe to add.
- **LiteLLM** sits below everything else as the routing layer. It's transparent to all tools above it.

## Quick Validation

After setting up the full stack, run a representative task and compare:

```bash
# Before stack (baseline)
# Note: total tokens from your agent's status bar or API response headers

# After stack
# Compare: input tokens, output tokens, total cost, task completion time
```

Expected improvements on a large codebase (10K+ files):
- Input tokens: 70–90% reduction (Graphify + Headroom + LeanCTX)
- Output tokens: ~65% reduction (Caveman)
- Cost per session: 75–90% reduction (compression + routing)
- Navigation speed: 10–100x faster (LSP)

## Troubleshooting

| Problem | Likely Cause | Fix |
|---------|-------------|-----|
| Graphify build fails | Unsupported file types in repo | Add to `.graphifyignore` |
| Headroom proxy not compressing | Wrong port or agent not pointed at proxy | Run `headroom doctor` |
| LeanCTX daemon not starting | Port conflict | Check `lean-ctx doctor` output |
| Caveman not activating | Skill not in Claude Code skills dir | Re-run install, restart Claude Code |
| LiteLLM routing to wrong model | Config mismatch | Check `litellm_config.yaml` model names |
| Continue.dev indexing slow | Large repo, no `.continueignore` | Add ignore patterns for `node_modules`, `dist`, etc. |

## Agent Instructions

> **For AI agents reading this document:** This is a token optimization stack. When setting up a new environment, install tools in the order listed under "Recommended Setup Order." Run each verification step before proceeding to the next tool. If a tool fails to install, skip it and continue — the tools are independent and any subset provides value. After setup, prefer Graphify queries and LSP navigation over raw file reads. Use `@codebase` for semantic questions. The compression layers (Headroom, LeanCTX, Caveman) require no behavioral changes — they work transparently once installed.

## References

- [Graphify](https://github.com/Graphify-Labs/graphify) — Codebase knowledge graph
- [LSAP](https://github.com/lsp-client/LSAP) — Language Server Agent Protocol
- [mcp-language-server](https://github.com/isaacphi/mcp-language-server) — LSP via MCP
- [Continue.dev](https://github.com/continuedev/continue) — Open-source coding assistant with RAG
- [Headroom](https://github.com/chopratejas/headroom) — Context compression layer
- [LeanCTX](https://github.com/yvgude/lean-ctx) — Context intelligence layer
- [Caveman](https://github.com/JuliusBrussee/caveman) — Output token compression skill
- [Agentsview](https://github.com/agentsview/agentsview) — Token budget monitoring and tracing
- [LiteLLM](https://github.com/BerriAI/litellm) — Model routing proxy
