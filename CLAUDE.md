# CLAUDE.md — Claude Code Skills

## What This Repo Is

A collection of reusable [Claude Code skills](https://docs.anthropic.com/en/docs/claude-code/skills) — knowledge packages that make hard-won lessons from production development available across all sessions and projects.

Each skill is a self-contained directory with a `SKILL.md` (frontmatter + operating procedure), an `install.sh` script, and `topics/` files with detailed patterns.

## Skills

| Skill | Directory | What It Covers |
|---|---|---|
| `solana-wallet-dev` | `solana-wallet-skill/` | Solana wallet/payment apps in React/TypeScript with Vite — RPC selection, HD key derivation, SPL token operations, transaction lifecycle, error handling, bundler config |
| `cloudflare-deployment-dev` | `cloudflare-deployment-skill/` | Cloudflare Workers deployment — routes, tunnels, shared servers, multi-account setups, sub-path SPA serving, credential security |
| `colima-k8s` | `colima-k8s-skill/` | Local Kubernetes (K3s) and Docker on macOS via Colima — Apple Silicon + Rosetta 2, VM types, resource sizing, K3s, troubleshooting |
| `banking-naming-conventions` | `banking-naming-conventions-skill/` | Standard English naming conventions for banking domain concepts — accounts, transactions, parties, amounts, and ledger entries |

## Structure Convention

Every skill follows the same layout:

```
<skill-name>-skill/
├── SKILL.md              # Frontmatter (name, description, user-invocable) + operating procedure
├── install.sh            # Copies files to ~/.claude/skills/<skill-name>/
└── topics/
    ├── topic-a.md        # Problem → pattern → code examples → pitfalls
    ├── topic-b.md
    └── ...
```

### SKILL.md Frontmatter

```yaml
---
name: skill-name              # Used as directory name in ~/.claude/skills/
description: One-line summary  # Shown in skill listings
user-invocable: false          # true = callable via /skill-name, false = auto-activated
---
```

### Topic Files

Each topic file covers one concern:
- **The Problem** — What goes wrong and why it's not obvious
- **The Pattern** — The solution with code examples
- **Pitfalls** — Common mistakes and how to avoid them

## Installing Skills

```bash
# Install a single skill
bash solana-wallet-skill/install.sh
bash cloudflare-deployment-skill/install.sh
bash colima-k8s-skill/install.sh
bash banking-naming-conventions-skill/install.sh

# Verify installation
ls ~/.claude/skills/
```

Skills are available in all Claude Code sessions after installation. Non-invocable skills activate automatically when the topic is relevant.

## Adding a New Skill

1. Create `<name>-skill/` directory following the structure above
2. Write `SKILL.md` with frontmatter, operating procedure, quick reference, and topic file index
3. Write topic files in `topics/`
4. Write `install.sh` following the existing pattern
5. Test: `bash <name>-skill/install.sh` then verify in a new Claude Code session

### Guidelines for Skill Content

- **Source from real incidents** — every pattern should trace back to a real problem encountered in production
- **Be specific** — include exact error messages, commands, and code snippets
- **Document the "why"** — explain why the obvious approach fails, not just the fix
- **Keep topics focused** — one concern per file, ~50-150 lines each
- **No speculative content** — only include patterns that have been validated

## Origin

These skills were extracted from the [ybank.me-wallet-solana](https://github.com/carlosnetto/ybank.me-wallet-solana) project — a React/TypeScript mobile payment wallet on Solana, deployed on Cloudflare Workers. The lessons come from HISTORY.md, CLOUDFLARE.md, and CLAUDE.md in that repo.
