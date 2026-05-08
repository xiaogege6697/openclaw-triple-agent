# 自定义指南

## 修改 Agent 性格

编辑对应 workspace 的 `SOUL.md`：
- main: `~/.openclaw/workspace-main/SOUL.md`
- secretary: `~/.openclaw/workspace-secretary/SOUL.md`
- guest: `~/.openclaw/workspace-guest/SOUL.md`
- research: `~/.openclaw/workspace-research/SOUL.md`

SOUL.md 是 Agent 的"灵魂文件"，定义了它的性格、语气、行为准则。Agent 每次启动都会读取它。

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

1. 在 `openclaw.json` 的 `agents.list` 中添加：
```json
{
  "id": "new-agent",
  "name": "新Agent",
  "identity": { "name": "新助手", "emoji": "🤖" },
  "model": { "primary": "your-model", "fallbacks": [] },
  "workspace": "$HOME/.openclaw/workspace-new"
}
```

2. 创建 workspace：
```bash
mkdir -p ~/.openclaw/workspace-new
# 复制模板文件（SOUL.md, AGENTS.md, USER.md, MEMORY.md, TOOLS.md, IDENTITY.md）
```

## 配置 Binding 路由

在 `openclaw.json` 的 `bindings` 中添加路由规则：
```json
{
  "bindings": [{
    "type": "route",
    "agentId": "secretary",
    "match": {
      "channel": "openclaw-weixin",
      "accountId": "<bot-accountId>"
    }
  }]
}
```
未匹配的消息默认走 main。

## 自定义 Dream 2.0

### main Dream

编辑 Dream prompt：`~/.openclaw/workspace-main/prompts/dream-main-2.0.md`

五个阶段可以独立调整：
- Phase 1：逐字稿回放的学习重点
- Phase 2：facts 提取规则和实体匹配
- Phase 3：规则进化的验证周期（默认3天）
- Phase 4：自愈操作的分级阈值
- Phase 5：汇报格式和推送方式

### secretary Dream

编辑 cron job 的 payload.message：
```bash
openclaw cron edit <secretary-dream-id>
```

### 规则验证参数

在 AGENTS.md「学来的规则」段落中，可以调整：
- 验证周期：默认连续 3 天通过 → 固化
- 休眠阈值：默认连续 3 次未触发 → 休眠
- 冲突处理：标记为 `[⚠️ 冲突]` 等待人工裁决

## 记忆架构配置

### main（完整三层）

```
transcripts/main/YYYY-MM-DD.md   ← 逐字稿（自动写入）
memory/YYYY-MM-DD.md             ← 日志摘要
memory/facts/YYYY-MM-DDTHHMM-*.md ← ADD-only 事实
MEMORY.md                         ← 索引文件
memory/entities.json              ← 实体标注
```

### secretary（轻量）

```
memory/YYYY-MM-DD.md   ← 日志+逐字稿合一
MEMORY.md              ← 长期记忆
```

### 添加实体

编辑 `memory/entities.json`，添加新实体用于 Dream 自动匹配：
```json
{
  "entities": [
    { "name": "OpenClaw", "tags": ["系统", "工具"] },
    { "name": "用户名", "tags": ["人物"] }
  ]
}
```

## 添加 Skills

将 Skill 目录放到对应 workspace 的 `skills/` 下，或使用全局 skills：
```bash
# 全局 Skills（所有 Agent 可用）
~/.openclaw/skills/

# Agent 专属 Skills
~/.openclaw/workspace-main/skills/
~/.openclaw/workspace-secretary/skills/
```

## 切换模型

```bash
openclaw configure --section model
```

或直接编辑 `openclaw.json`：
```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "zai/GLM-5.1",
        "fallbacks": ["zai/glm-4.7"]
      }
    }
  }
}
```

## 添加 Cron 任务

```bash
openclaw cron add --name "my-task" --schedule "0 8 * * *" --agent main --message "你的 prompt"
```

常用参数：
- `--schedule`：cron 表达式 + 时区（如 `0 8 * * * @ Asia/Shanghai`）
- `--agent`：指定运行的 Agent
- `--delivery`：推送方式（`none`/`announce`）
- `--light-context`：轻量上下文模式，节省 token
