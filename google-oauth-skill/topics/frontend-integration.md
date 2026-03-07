# Frontend Integration (React)

## Google Login Button

Use `@react-oauth/google` with the implicit (token) flow — the browser gets an access token directly from Google, which is then sent to your backend for validation.

```tsx
import { useGoogleLogin } from '@react-oauth/google';

const login = useGoogleLogin({
  onSuccess: async (tokenResponse) => {
    const res = await fetch(`${import.meta.env.BASE_URL}api/auth/google`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',   // required for session cookie
      body: JSON.stringify({ accessToken: tokenResponse.access_token }),
    });
    if (res.ok) {
      // session cookie is now set — subsequent requests are authenticated
    }
  },
  scope: 'openid email profile',
});
```

`credentials: 'include'` is required on every API call so the browser sends and receives the session cookie.

---

## API Call Pattern

All API calls must use `import.meta.env.BASE_URL` as prefix (especially under sub-path deployments) and include `credentials: 'include'`:

```typescript
// Good — works in dev (Vite proxy) and prod (Worker proxy)
fetch(`${import.meta.env.BASE_URL}api/auth/google`, {
  method: 'POST',
  credentials: 'include',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ accessToken }),
})

// Bad — /api/auth conflicts with other apps on the same domain
fetch('/api/auth/google', ...)
```

---

## Session Check on Load

On app startup, check if the user is already authenticated:

```typescript
useEffect(() => {
  fetch(`${import.meta.env.BASE_URL}api/auth/me`, { credentials: 'include' })
    .then(res => {
      if (res.ok) return res.json();
      throw new Error('not authenticated');
    })
    .then(user => setUser(user))
    .catch(() => setUser(null));
}, []);
```

`401` → not authenticated, show login screen.
`200` → session active, restore user state.

---

## Logout

```typescript
const logout = async () => {
  await fetch(`${import.meta.env.BASE_URL}api/auth/logout`, {
    method: 'POST',
    credentials: 'include',
  });
  setUser(null);
  // clear any localStorage caches (wallet data, preferences, etc.)
  localStorage.removeItem('dt_wallets');
};
```

Server-side logout deletes the session row — the cookie becomes immediately invalid even if it hasn't expired.

---

## Displaying User Info

The Google userinfo API returns `email`, `name`, and `picture` (profile photo URL). Store these in app state and display:

```tsx
// Profile photo (replaces initials avatar)
<img src={user.picture} alt={user.name} className="rounded-full w-8 h-8" />

// Name + logout dropdown
<span>{user.name}</span>
<button onClick={logout}>Sign out</button>
```

---

## Error Handling

```typescript
try {
  const res = await fetch(`${import.meta.env.BASE_URL}api/auth/google`, { ... });
  let data: any = {};
  try { data = await res.json(); } catch {}

  if (!res.ok) {
    setError(data.error ?? `Server error (${res.status})`);
    return;
  }
  // success
} catch (e) {
  setError('Network error — check your connection');
}
```

Common error responses:
- `403 "Access restricted to: [@matera.com, @zoripay.xyz]"` → wrong email domain
- `403 "Account is suspended"` → user exists but is suspended in the DB
- `401 "Invalid access token"` → Google token expired or invalid (retry login)

---

## GoogleOAuthProvider Setup

Wrap your app with the provider, using the client ID (public — safe to embed):

```tsx
import { GoogleOAuthProvider } from '@react-oauth/google';

<GoogleOAuthProvider clientId="664908102394-xxxx.apps.googleusercontent.com">
  <App />
</GoogleOAuthProvider>
```

The client ID is not a secret. Never embed the client secret in frontend code.
