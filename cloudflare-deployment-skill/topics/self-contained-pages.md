# Modern Self-Contained Pages Pattern

This pattern allows for fully portable, account-agnostic Cloudflare projects that do not depend on global configuration files (like `~/.cloudflared/cert.pem` or global OAuth sessions). It is ideal for CI/CD environments and developers managing multiple Cloudflare accounts.

## Core Principles

1.  **Zero Global State:** Avoid `wrangler login` or `cloudflared login` which store state in the user's home directory.
2.  **Explicit Credentials:** Use Scoped API Tokens stored in a local `.env` file.
3.  **Local Execution:** Use `dotenv-cli` to inject environment variables directly into the deployment process.
4.  **Single-Bundle Builds:** Consolidate assets into a predictable directory structure for reliable static hosting.

## Implementation Guide

### 1. Environment Setup
Create a `.env` file in the project root (and ensure it's in `.gitignore`):

```bash
# Cloudflare API Token with "Cloudflare Pages: Edit" permissions
CLOUDFLARE_API_TOKEN=your_token_here

# Optional: Account ID if managing multiple accounts
CLOUDFLARE_ACCOUNT_ID=8a5cfa2ea39c6e7e6e049f5a3ce13aa3
```

### 2. Dependency Management
Install `dotenv-cli` to handle variable injection:

```bash
npm install --save-dev dotenv-cli
```

### 3. Build Configuration (Vite Example)
Configure `vite.config.ts` to output to a dedicated `target/` directory and simplify asset naming for "giant bundle" deployments:

```typescript
// vite.config.ts
export default defineConfig({
  build: {
    outDir: 'target',
    emptyOutDir: true,
    rollupOptions: {
      output: {
        manualChunks: undefined, // Disable chunking
        entryFileNames: `assets/[name].js`,
        chunkFileNames: `assets/[name].js`,
        assetFileNames: `assets/[name].[ext]`,
      },
    },
  },
});
```

### 4. Deployment Automation
Add a `deploy` script to `package.json` that bridges `dotenv` and `wrangler`:

```json
{
  "scripts": {
    "build": "vite build",
    "deploy": "dotenv -- npx wrangler pages deploy target --project-name your-project-name"
  }
}
```

## Advantages
- **Portability:** The project can be cloned and deployed immediately by just adding a `.env` file.
- **Security:** No shared `cert.pem` that might have over-broad permissions across multiple zones.
- **Predictability:** Always uses the project-specific project name and account ID, preventing accidental deployments to the wrong account.
- **CI/CD Ready:** This exact same command (`npm run deploy`) works in GitHub Actions or GitLab CI without modification.

## Troubleshooting
- **522 Errors:** Usually means the domain is pointed via CNAME to `.workers.dev` but not added as a "Custom Domain" in the Pages project settings. Always add the domain in the Pages UI.
- **Token Permissions:** Ensure the token has `Account: Cloudflare Pages (Edit)` and `User: Members (Read)` (to find the account).
