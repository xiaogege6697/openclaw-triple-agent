# Security Notes

This repo is a configuration package. The installer may generate local files that contain API keys, gateway tokens, channel account IDs, and chat-routing state. Those generated files belong in `~/.openclaw/`, not in git.

Do not commit:

- generated `openclaw.json`,
- provider API keys,
- gateway auth tokens,
- WeChat/channel account IDs from real logins,
- QR/login artifacts,
- private transcripts,
- memory backups containing personal data.

Before pushing:

```bash
rg -n "api[_-]?key|secret|token|cookie|password|bearer|sk-[A-Za-z0-9]" .
git status --short
```

If a real credential was committed, rotate it before continuing.
