# Claude Code Skills

Reusable [Claude Code skills](https://docs.anthropic.com/en/docs/claude-code/skills) extracted from production projects. Each skill packages hard-won lessons into a format that Claude Code can automatically apply across sessions.

## Available Skills

### [solana-wallet-dev](solana-wallet-skill/)

Patterns for building Solana wallet and payment apps in React/TypeScript with Vite.

**Topics:** RPC selection & CORS, HD key derivation (`micro-key-producer`), SPL token operations (ATAs, transfers), transaction lifecycle (simulate → sign → send → confirm), error handling, Vite polyfill configuration, ecosystem direction (`@solana/kit` migration).

### [cloudflare-deployment-dev](cloudflare-deployment-skill/)

Patterns for deploying apps on Cloudflare Workers with tunnels, sub-path routing, and multi-account setups.

**Topics:** Worker setup & route-based deployment, tunnel creation & DNS routing, shared-server pitfalls (`config.yml` override trap), multi-account alignment, sub-path SPA deployment (Vite `base` + worker prefix stripping), credential security & rotation.

### [colima-k8s](colima-k8s-skill/)

Patterns for running local Kubernetes (K3s) and Docker on macOS via Colima.

**Topics:** Apple Silicon + Rosetta 2 setup, VM types (vz vs qemu), resource sizing, K3s cluster management, kubectl, persistent volumes, Helm, troubleshooting common errors, networking, volume mounts, certificates.

## Quick Start

```bash
git clone https://github.com/carlosnetto/claude-skills.git
cd claude-skills

# Install any or all
bash solana-wallet-skill/install.sh
bash cloudflare-deployment-skill/install.sh
bash colima-k8s-skill/install.sh
```

Skills install to `~/.claude/skills/` and are available in all Claude Code sessions. Non-invocable skills activate automatically when the topic is relevant.

## Skill Structure

```
<name>-skill/
├── SKILL.md        # Skill definition, quick reference, critical rules
├── install.sh      # Installer (copies to ~/.claude/skills/)
└── topics/         # Detailed topic files
    └── *.md        # Problem → pattern → code → pitfalls
```

## Origin

These skills were extracted from [ybank.me-wallet-solana](https://github.com/carlosnetto/ybank.me-wallet-solana) — a React/TypeScript mobile payment wallet on Solana deployed on Cloudflare Workers. Every pattern traces back to a real production incident.

## License

Apache 2.0
