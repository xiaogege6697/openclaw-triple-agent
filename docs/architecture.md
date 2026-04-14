# 三 Agent 架构说明

## 概览

```
┌─────────────────────────────────────────────┐
│              OpenClaw Gateway               │
│                                             │
│  ┌─────────┐  ┌──────────┐  ┌───────────┐ │
│  │  main   │  │secretary │  │   guest   │ │
│  │  😎     │  │  🌸      │  │   🎮      │ │
│  │ 主助手  │  │ 小秘书   │  │ 体验助手  │ │
│  └─────────┘  └──────────┘  └───────────┘ │
│       │            │                        │
│  ┌────┴────────────┴────────────────────┐  │
│  │          Binding Router              │  │
│  │  accountId → agentId 路由            │  │
│  └──────────────────────────────────────┘  │
│                  │                          │
│  ┌───────────────┴──────────────────────┐  │
│  │          Channel Layer               │  │
│  │  微信 / Discord / 飞书 / CLI         │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

## 三个 Agent

| Agent | 职责 | Workspace |
|-------|------|-----------|
| **main 😎** | 系统运维、技术问题、日常对话 | workspace-main |
| **secretary 🌸** | 日程管理、生活助手、情感陪伴 | workspace-secretary |
| **guest 🎮** | 临时访客、功能体验 | workspace-guest |

## 记忆隔离

三个 Agent 的 workspace 完全物理隔离：
- 各自独立的 MEMORY.md、USER.md
- 各自独立的 memory/ 日志目录
- 一个 Agent 不能读取另一个的记忆

## Binding 路由

通过 `bindings` 配置实现微信多号路由：
```json
{
  "type": "route",
  "agentId": "secretary",
  "match": {
    "channel": "openclaw-weixin",
    "accountId": "小号-bot-ID"
  }
}
```
- 大号微信消息 → main 😎
- 小号微信消息 → secretary 🌸（binding 匹配优先）

## 做梦系统

每个 Agent 都有独立的"做梦"定时任务（凌晨自动执行）：

**main-dream（02:30）** 8个阶段：
1. 系统巡检
2. 记忆整理（SWS 慢波睡眠类比）
3. 海马体回放（⭐标记优先）
4. Bug 追踪
5. 项目巡检
6. 清除（类淋巴系统类比）
7. 前瞻模拟（REM 预测编码类比）
8. 记录与汇报

**secretary-dream（02:00）** 7个阶段（含情绪追踪、前瞻模拟）

两个 dream 错开 30 分钟，避免 API 并发。
