# 🦞 OpenClaw Multi-Agent System

**一键部署多 Agent 架构的 OpenClaw 智能助手系统**

基于 [OpenClaw](https://github.com/openclaw/openclaw) 的多 Agent 配置方案，包含 Dream 2.0 自动学习系统、ADD-only 记忆架构、微信绑定、12 个定时任务。

## 📦 这是什么？

这是一个**配置包**，不是 OpenClaw 本体。

```
OpenClaw 智能助手 = OpenClaw 本体（npm 安装） + 这个配置包（架构 + 性格 + 定时任务）
                                  ~300MB                        ~600KB
```

| 组件 | 来源 | 说明 |
|------|------|------|
| OpenClaw 本体 | `npm install -g openclaw` | 核心引擎 |
| 本配置包 | 这个仓库 | 四 Agent 架构 + Dream 2.0 + 性格模板 + 脚本 |

> 💡 类比：OpenClaw 本体是手机，这个配置包是手机壳 + 壁纸 + App 布局。一键把"手机"装扮成你的风格。

## ✨ 特性

- 🤖 **四 Agent 架构**：总管家 😎 + 小秘书 🌸 + 体验助手 🎮 + 投研助手 📊
- 🧠 **Dream 2.0**：五阶段自动学习流水线（逐字稿回放→知识提炼→规则进化→自愈→推送）
- 📝 **ADD-only 记忆架构**：借鉴 Mem0，只建新不改旧，实体标注+语义检索
- 📊 **四级查询体系**：按成本递进（内部对比→速搜→交叉验证→深度查）
- 💬 **微信绑定**：扫码即用，支持多号多 Agent 路由
- ⏰ **12 个定时任务**：Dream/监控/日报/周报/备份/安全扫描/Skill 审查
- 📝 **记忆隔离**：每个 Agent 独立记忆系统，物理隔离互不干扰
- 🔄 **规则自进化**：3天验证期→固化，连续未触发→休眠，违反→报告待裁决
- 🔧 **一键安装**：交互式脚本，只需选模型 + 扫码

## 🚀 快速开始

### 前置条件

- macOS / Linux（Windows 需 WSL2）
- Node.js >= 22
- Git

### 安装

```bash
git clone https://github.com/xiaogege6697/openclaw-triple-agent.git
cd openclaw-triple-agent
bash install.sh
```

安装脚本会引导你：
1. ✅ 自动检查依赖
2. 🧠 选择大模型并验证 API
3. 📁 自动创建目录和配置
4. 📱 [可选] 绑定微信

## 📁 目录结构

```
~/.openclaw/
├── openclaw.json              # 核心配置
├── agents/                    # Agent 运行时数据
│   ├── main/
│   ├── secretary/
│   ├── guest/
│   └── research/
├── scripts/                   # 运维脚本
│   ├── dream-collect.sh       # Dream 数据采集
│   ├── dream-run.sh           # Dream 总控
│   ├── gene-capsule.sh        # 基因胶囊备份
│   └── impact-check.sh        # 架构变更影响检查
├── extensions/
│   ├── openclaw-weixin/       # 微信插件
│   └── wecom-openclaw-plugin/ # 企业微信插件
├── workspace-main/            # 😎 总管家工作区
│   ├── SOUL.md               # 性格定义
│   ├── AGENTS.md              # 行为准则
│   ├── MEMORY.md              # 长期记忆索引
│   ├── prompts/
│   │   └── dream-main-2.0.md # Dream 2.0 prompt
│   ├── memory/               # 记忆系统
│   │   ├── YYYY-MM-DD.md     # 每日日志
│   │   ├── facts/            # ADD-only 事实库
│   │   ├── archive/          # 归档日志
│   │   ├── ideas/            # 方法论笔记
│   │   ├── weekly/           # 周记
│   │   └── entities.json     # 实体标注
│   └── transcripts/main/     # 逐字稿（实时写入）
├── workspace-secretary/       # 🌸 小秘书工作区
│   ├── SOUL.md
│   ├── memory/
│   ├── scripts/              # 天气查询等脚本
│   └── skills/calendar/      # 日程管理 Skill
├── workspace-guest/           # 🎮 体验助手工作区
└── workspace-research/        # 📊 投研助手工作区
```

## 🧠 Dream 2.0 系统

借鉴人类大脑睡眠机制设计的自动学习系统，每天凌晨运行：

| 阶段 | 灵感来源 | 功能 |
|------|---------|------|
| Phase 1 | 海马体回放 | 逐字稿回放，提炼经验/规则/偏好 |
| Phase 2 | 记忆巩固 | 知识提炼，ADD-only facts 写入 |
| Phase 3 | 突触可塑性 | 规则进化，3天验证→固化 |
| Phase 4 | 类淋巴清除 | 系统自愈，分级处理（自动/待确认/只报告） |
| Phase 5 | 意识恢复 | 汇报推送，微信播报 |

详细设计见 [docs/dream-system.md](docs/dream-system.md)。

### 规则生命周期

```
新经验 → [验证第1天] → [验证第2天] → [验证第3天] → [固化]
                                                      ↓ 被违反
                                              [⚠️ 冲突] → 人工裁决
                                                      ↓ 连续未触发
                                              [💤 休眠] → 场景恢复时自动激活
```

## 🔧 支持的模型

| 提供商 | 模型 | 说明 |
|--------|------|------|
| 智谱 GLM | GLM-5.1 / glm-4.7 | 主力推荐，套餐内免费 |
| OpenAI | gpt-4o-mini / gpt-4o | 按 token 计费 |
| 本地 Ollama | nomic-embed-text | 仅用于 embedding，不用于推理 |
| 自定义 | 任何 OpenAI 兼容 API | 取决于提供商 |

**Fallback 链**：GLM-5.1 → glm-5 → glm-4.7（自动降级，保证可用性）

## ⏰ 定时任务（12 个）

### main agent（8 个）

| 任务 | 时间 | 说明 |
|------|------|------|
| monitoring-hourly | 每小时 | 系统健康检查（异常才推送） |
| main-dream | 02:30 | Dream 2.0 五阶段学习 |
| security-scan | 周三 03:00 | 安全巡检 |
| gene-capsule | 04:00 | 全量备份 |
| memory-maintenance | 周日 03:30 | 记忆维护+归档 |
| dashboard-daily | 20:00 | 每日状态报告 |
| weekly-report | 周日 20:00 | 周报汇总 |
| skills-audit | 每月1号 03:00 | Skill 审查 |

### secretary agent（4 个）

| 任务 | 时间 | 说明 |
|------|------|------|
| secretary-dream | 02:00 | 轻量记忆整理 |
| secretary-morning | 07:00 | 早安+天气+穿搭建议 |
| secretary-goodnight | 23:00 | 晚安提醒 |
| skills-healthcheck | 周一 09:00 | 健康检查 |

## 📱 微信绑定

支持通过 `openclaw-weixin` 插件将微信接入 Agent 系统：

```bash
openclaw channels login --channel openclaw-weixin
```

### 多 Agent 路由

绑定多个微信 bot 后，通过 binding 配置路由：
```json
{
  "bindings": [{
    "type": "route",
    "agentId": "secretary",
    "match": { "channel": "openclaw-weixin", "accountId": "<小号bot-accountId>" }
  }]
}
```
- 大号微信 → main 😎（默认）
- 小号微信 → secretary 🌸（binding 优先）

## 🛠 自定义

详见 [docs/customization-guide.md](docs/customization-guide.md)

- 修改 Agent 性格：编辑 `SOUL.md`
- 添加新 Agent：在 `openclaw.json` 的 agents.list 中添加
- 自定义 Dream：编辑 `prompts/dream-main-2.0.md`
- 切换模型：`openclaw configure --section model`
- 添加 Skills：放到对应 workspace 的 `skills/` 目录

## 🏗 架构演进时间线

| 日期 | 里程碑 |
|------|--------|
| 04-01 | 系统搭建，双 Agent 分工，cron 体系建立 |
| 04-10 | Agent 串台问题修复，物理隔离落地 |
| 04-14 | 首次开源发布（openclaw-triple-agent） |
| 04-15 | Dream 2.0 上线（8阶段→5阶段精简） |
| 04-25 | ADD-only 事实库落地，Memory 架构定型 |
| 04-26 | 逐字稿架构回归（agent 实时写入，不依赖事后提取） |
| 04-28 | 四级查询体系、规则检查点机制 |
| 05-08 | Dream 播报推送修复、架构文档全面更新 |

## ⚠️ 注意事项

- **安全**：请在私密环境中运行，不要公开 API Key
- **记忆**：所有记忆文件永久保留，归档不删除
- **备份**：gene-capsule 每日自动备份，建议同时推送到 GitHub 私有仓库
- **Windows 用户**：需先安装 [WSL2](https://learn.microsoft.com/zh-cn/windows/wsl/install)

## 📄 许可

MIT

---

*Made with 🦞 by OpenClaw Multi-Agent System*
