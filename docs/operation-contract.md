# OpenClaw Triple Agent Operation Contract

## Project Identity

This repository is a deployable OpenClaw configuration package for a multi-agent personal assistant system. Its core value is not the exact scripts or personality files; its core is a recoverable topology: isolated agents, explicit routing, ADD-only memory, Dream review, and operations scripts that can be inspected before use.

## Narrow Waist

Keep these contracts stable:

1. **Generated config stays local**: `~/.openclaw/openclaw.json`, API keys, channel IDs, gateway tokens, cookies, and QR/login state are never committed.
2. **Agent isolation**: each agent keeps its own workspace, memory, prompts, and operational role.
3. **ADD-only memory**: logs and facts are appended or superseded, not silently rewritten.
4. **Dream is advisory**: rule evolution reports evidence and conflicts; hard rules require human acceptance when they affect safety, identity, or data.
5. **Install is reversible**: before copying or overwriting, preserve existing files or document the backup path.

## Flexible Layer

Model providers, cron schedules, plugin implementations, prompt wording, and script internals can change as long as the narrow waist remains intact.

## Stop Lines

Stop and inspect before running, committing, or deploying when:

- a file contains API keys, account IDs, gateway auth tokens, cookies, QR/login artifacts, or private transcripts,
- a script writes outside `~/.openclaw/` without explicit user approval,
- a routing change can send private messages to the wrong agent,
- Dream output proposes new hard rules without evidence and review,
- a generated backup contains private memory or channel credentials.

## Minimal Verification

```bash
bash -n install.sh
find scripts -maxdepth 2 -name '*.sh' -print0 | xargs -0 -I{} bash -n {}
python3 -m json.tool config/openclaw.json.template >/tmp/openclaw-template.json
rg -n "api[_-]?key|secret|token|cookie|password|bearer|sk-[A-Za-z0-9]" .
```

The sensitive-keyword scan is expected to match documentation and template placeholders. Treat any real credential-like value as a blocker.
