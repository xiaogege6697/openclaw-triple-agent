# 🦞 OpenClaw Triple Agent

**一键部署三 Agent 架构的 OpenClaw 智能助手系统**

基于 [OpenClaw](https://github.com/openclaw/openclaw) 的三 Agent 配置方案，包含完整的做梦系统、记忆管理、微信绑定、定时任务。

## 📦 这是什么？

这是一个**配置包**，不是 OpenClaw 本体。

```
OpenClaw 智能助手 = OpenClaw 本体（npm 安装） + 这个配置包（架构 + 性格 + 定时任务）
                                  ~300MB                        ~568KB
```

| 组件 | 来源 | 说明 |
|------|------|------|
| OpenClaw 本体 | `npm install -g openclaw` | 核心引擎，~300MB |
| 本配置包 | 这个仓库，~568KB | 三 Agent 架构 + 性格模板 + 脚本 |

install.sh 会**自动检测并安装 OpenClaw 本体**，你不需要手动操作。

> 💡 类比：OpenClaw 本体是手机，这个配置包是手机壳 + 壁纸 + App 布局。一键把"手机"装扮成你的风格。

## ✨ 特性

- 🤖 **三 Agent 架构**：主助手 😎 + 小秘书 🌸 + 体验助手 🎮
- 🧠 **做梦系统**：借鉴神经科学的 8 阶段自动巡检（记忆巩固/海马体回放/前瞻模拟）
- 💬 **微信绑定**：扫码即用，支持多号多 Agent 路由
- ⏰ **12 个定时任务**：dream/日报/周报/备份/安全扫描
- 📝 **记忆隔离**：三个 Agent 各自独立的记忆系统
- 🔧 **一键安装**：交互式脚本，只需选模型 + 扫码

## 🚀 快速开始

### 前置条件

- macOS / Linux
- Node.js >= 20
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

### 仅需 2 步人工操作

1. **选模型 + 填 API Key**（脚本会验证连通性）
2. **微信扫码**（可选，不绑定也能用 CLI 聊天）

## 📁 目录结构

```
~/.openclaw/
├── openclaw.json              # 核心配置
├── cron/jobs.json             # 12 个定时任务
├── scripts/                   # 运维脚本
├── extensions/openclaw-weixin/  # 微信插件
├── workspace-main/            # 😎 主助手工作区
│   ├── SOUL.md               # 性格定义
│   ├── AGENTS.md              # 行为准则
│   ├── MEMORY.md              # 长期记忆
│   └── memory/                # 每日日志
├── workspace-secretary/       # 🌸 小秘书工作区
│   └── ...
└── workspace-guest/           # 🎮 体验助手工作区
    └── ...
```

## 🧠 做梦系统

借鉴人类大脑睡眠机制设计的自动巡检系统，每天凌晨运行：

| 阶段 | 灵感来源 | 功能 |
|------|---------|------|
| P1 系统巡检 | — | Gateway/磁盘/Ollama/MiMo/跨Agent |
| P2 记忆整理 | N3 慢波睡眠 | 短期→长期记忆转移 |
| P3 海马体回放 | Sharp-wave ripple | ⭐重要标记优先处理 |
| P4 Bug 追踪 | — | 扫描已知问题状态 |
| P5 项目巡检 | — | GitHub/本地仓库状态 |
| P6 清除 | 类淋巴系统 | 清理临时文件 |
| P7 前瞻模拟 | REM 预测编码 | 风险预警、趋势预测 |
| P8 汇报 | — | 微信推送报告 |

详细设计见 [docs/dream-system.md](docs/dream-system.md)。

## 🔧 支持的模型

| 提供商 | 模型 | 费用 |
|--------|------|------|
| 智谱 GLM | glm-4.7-flash / GLM-5.1 | 免费（套餐内） |
| 小米 MiMo | mimo-v2-pro | ¥7/¥21 per M tokens |
| OpenAI | gpt-4o-mini / gpt-4o | 按 token 计费 |
| 本地 Ollama | qwen2.5 / llama3 | 免费（本地运行） |
| 自定义 | 任何 OpenAI 兼容 API | 取决于提供商 |

## ⏰ 定时任务

| 任务 | 时间 | 说明 |
|------|------|------|
| main-dream | 02:30 | 主助手做梦巡检 |
| secretary-dream | 02:00 | 小秘书做梦巡检 |
| 每日报告 | 08:00 | 系统状态日报 |
| weekly-report | 周一 09:00 | 周报 |
| gene-capsule | 04:00 | 全量备份 |
| security-scan | 06:00 | 安全扫描 |
| skills-audit | 03:00 | Skills 健康检查 |
| transcript-backup | 01:00 | 会话备份 |

## 📱 微信绑定

### 方式一：微信公众号测试号（推荐新手）

1. 访问 [微信测试号平台](https://mp.weixin.qq.com/debug/cgi-bin/sandbox?t=sandbox/login)
2. 扫码登录获取 appId 和 appSecret
3. 运行 `openclaw configure --section channels` 填入
4. 扫码关注测试号
5. 发消息即可开始聊天

### 方式二：正式公众号

需要已认证的服务号，配置过程类似但需要部署回调服务器。

### 多 Agent 路由

绑定多个微信 bot 后，通过 binding 配置路由：
```json
{
  "bindings": [{
    "type": "route",
    "agentId": "secretary",
    "match": { "channel": "openclaw-weixin", "accountId": "小号bot-ID" }
  }]
}
```
未匹配的消息默认走 main。

## 🛠 自定义

详见 [docs/customization-guide.md](docs/customization-guide.md)

- 修改 Agent 性格：编辑 `SOUL.md`
- 添加新 Agent：在 `openclaw.json` 的 agents.list 中添加
- 自定义 Dream：编辑 cron/jobs.json 中的 prompt
- 切换模型：`openclaw configure --section model`

## ⚠️ 注意事项

- **测试版本**：基于 OpenClaw 2026.3.13 开发，其他版本可能需要微调
- **微信插件**：需额外 `npm install`，安装脚本会自动处理
- **API 费用**：根据选择的模型提供商，可能产生费用
- **安全**：请在私密环境中运行，不要公开 API Key

## 📄 许可

MIT

---

*Made with 🦞 by OpenClaw Triple Agent*
