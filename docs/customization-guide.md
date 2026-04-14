# 自定义指南

## 修改 Agent 性格

编辑对应 workspace 的 `SOUL.md`：
- main: `~/.openclaw/workspace-main/SOUL.md`
- secretary: `~/.openclaw/workspace-secretary/SOUL.md`
- guest: `~/.openclaw/workspace-guest/SOUL.md`

SOUL.md 是 Agent 的"灵魂文件"，定义了它的性格、语气、行为准则。

## 修改 Agent 身份

编辑 `IDENTITY.md`：
```markdown
# IDENTITY.md
- **Name:** 你的Agent名
- **Creature:** AI 搭档
- **Vibe:** 直接、有主见
- **Emoji:** 😎
```

## 添加更多 Agent

在 `openclaw.json` 的 `agents.list` 中添加：
```json
{
  "id": "new-agent",
  "name": "新Agent",
  "identity": { "name": "新助手", "emoji": "🤖" },
  "model": { "primary": "your-model", "fallbacks": [] },
  "workspace": "$HOME/.openclaw/workspace-new"
}
```

然后创建 workspace：
```bash
mkdir -p ~/.openclaw/workspace-new
# 复制模板文件...
```

## 配置 Binding 路由

在 `openclaw.json` 的 `bindings` 中添加路由规则：
```json
{
  "type": "route",
  "agentId": "new-agent",
  "match": {
    "channel": "openclaw-weixin",
    "accountId": "你的新bot-accountId"
  }
}
```

## 自定义 Dream

编辑 `~/.openclaw/cron/jobs.json` 中对应 dream 任务的 prompt。
参考 `docs/dream-system.md` 了解各阶段设计。

## 切换模型

```bash
openclaw configure --section model
```

或直接编辑 `openclaw.json` 的 `agents.defaults.model.primary`。
