# 四 Agent 架构说明

## 概览

```
┌─────────────────────────────────────────────────────────────┐
│                    OpenClaw Gateway                          │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  main    │  │secretary │  │  guest   │  │ research │  │
│  │  😎🔑   │  │  🌸      │  │   🎮     │  │   📊     │  │
│  │ 总管家   │  │ 小秘书   │  │ 体验助手 │  │ 投研助手 │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
│       │             │                                       │
│  ┌────┴─────────────┴───────────────────────────────────┐  │
│  │              Binding Router                          │  │
│  │     accountId → agentId 消息路由                      │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                  │
│  ┌───────────────────────┴──────────────────────────────┐  │
│  │              Channel Layer                           │  │
│  │     微信(多号) / 飞书 / Discord / CLI                │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Dream 2.0 引擎                          │  │
│  │  逐字稿回放 → 知识提炼 → 规则进化 → 自愈 → 推送    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              记忆系统                                │  │
│  │  逐字稿 / 日志 / Facts(ADD-only) / 索引 / 实体标注  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 四个 Agent

| Agent | 职责 | Workspace | 状态 |
|-------|------|-----------|------|
| **main 😎🔑** | 系统运维、技术执行、总管家（管理其他 Agent） | workspace-main | 活跃 |
| **secretary 🌸** | 日程管理、生活助手、情感陪伴、天气提醒 | workspace-secretary | 活跃 |
| **guest 🎮** | 临时访客、功能体验 | workspace-guest | 空置 |
| **research 📊** | 投研分析、深度调研 | workspace-research | 规划中 |

### 总管家职责

main agent 同时担任"总管家"角色：
- 维护 Agent 花名册（AGENT-REGISTRY.md）
- 管理所有 Agent 的 cron 运行状态
- 代偿简单问题，引导专业问题路由
- 监控各 Agent 健康状态

## 记忆隔离

四个 Agent 的 workspace 完全物理隔离：
- 各自独立的 MEMORY.md、SOUL.md、USER.md、AGENTS.md
- 各自独立的 memory/ 日志目录
- 各自独立的 Dream 系统
- 一个 Agent 不能读取另一个的记忆

## Binding 路由

通过 `bindings` 配置实现微信多号路由：
```json
{
  "bindings": [{
    "type": "route",
    "agentId": "secretary",
    "match": {
      "channel": "openclaw-weixin",
      "accountId": "<小号-bot-accountId>"
    }
  }]
}
```
- 大号微信消息 → main 😎（默认路由）
- 小号微信消息 → secretary 🌸（binding 匹配优先）

## 消息路由规则

```
消息进入 Gateway
    ↓
检查 bindings 规则
    ↓ 匹配到
    → secretary agent（小号微信）
    ↓ 未匹配
    → main agent（默认，大号微信/飞书/CLI）
```

## 记忆架构

### main（三层体系，完整版）

| 层级 | 文件 | 说明 |
|------|------|------|
| 原始记录 | `transcripts/main/YYYY-MM-DD.md` | 逐字稿，agent 每轮对话后实时写入 |
| 工作记忆 | `memory/YYYY-MM-DD.md` | 当日日志摘要 |
| 长期记忆 | `MEMORY.md` | 索引文件，指向 facts |
| 事实库 | `memory/facts/YYYY-MM-DDTHHMM-topic.md` | ADD-only，只建新不改旧 |
| 实体标注 | `memory/entities.json` | 人物/系统/事件实体关联 |
| 归档 | `memory/archive/` | >7天日志自动归档 |

**ADD-only 原则**（借鉴 Mem0）：
- 新记忆只创建新文件，不修改已有 facts
- 矛盾信息在新 fact 中标注引用旧 fact
- 过期内容标记 `status: expired`，不删除

### secretary（轻量版）

| 层级 | 文件 | 说明 |
|------|------|------|
| 日志 | `memory/YYYY-MM-DD.md` | 日志+逐字稿合一 |
| 长期记忆 | `MEMORY.md` | 精简版 |
| 心情 | `memory/mood-tracker.md` | 情绪追踪 |
| 归档 | `memory/archive/` | 自动归档 |

**渐进式复杂度**：不同 Agent 按需配置记忆架构，不搞一刀切。

## Dream 2.0 系统

详见 [dream-system.md](dream-system.md)。

## Skills 分配

### main（~15 个 Skills）
- **生活类**：calendar, weather, social-reader
- **研究类**：hv-analysis（横纵分析法）, zhangxuefeng-skill（思维框架）
- **开发类**：coding-agent, github, gh-issues, skill-creator
- **工具类**：pptx, reimburse, webleon
- **安全类**：clawsec-feed, clawsec-scanner, clawsec-nanoclaw

### secretary（1 个 Skill）
- **生活类**：calendar

## Cron 定时任务（12 个）

### main agent（8 个）

| 任务 | 时间 | 说明 |
|------|------|------|
| monitoring-hourly | 每小时（±5min） | 系统健康检查，异常才推送 |
| main-dream | 02:30 | Dream 2.0 五阶段学习 |
| security-scan | 周三 03:00 | 安全巡检（Gateway/磁盘/敏感信息） |
| gene-capsule | 04:00 | 基因胶囊全量备份 |
| memory-maintenance | 周日 03:30 | 记忆维护+归档 |
| dashboard-daily | 20:00 | 每日状态报告 |
| weekly-report | 周日 20:00 | 周报汇总 |
| skills-audit | 每月1号 03:00 | Skill 审查清理 |

### secretary agent（4 个）

| 任务 | 时间 | 说明 |
|------|------|------|
| secretary-dream | 02:00 | 轻量记忆整理+归档 |
| secretary-morning | 07:00 | 早安问候+天气+穿搭建议 |
| secretary-goodnight | 23:00 | 晚安提醒 |
| skills-healthcheck | 周一 09:00 | 健康检查 |

## 资源复用

| 资源 | 复用方式 |
|------|----------|
| 模型 | 全局共享 GLM-5.1 + fallback 链 |
| 向量检索 | 共享 Ollama nomic-embed-text |
| 备份 | main 备份脚本自动包含所有 workspace |
| Gateway | 统一 Gateway 实例 |
| Channel | 共享微信插件 |
| **隔离项** | 记忆、人格、Skills、定时任务按 Agent 独立 |
