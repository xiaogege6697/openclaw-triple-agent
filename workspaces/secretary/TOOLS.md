# TOOLS.md - 环境专属配置 & 技术备忘

## 模型配置
- **所有 agent 统一 fallback 链**：GLM-5.1 → mimo-v2-pro → glm-4.7
- agent 自己的配置会**覆盖**全局 defaults（替换关系，不是合并）
- cooldown 机制：429 后指数退避（1min→5min→25min→1h），冷却到期自动切回主模型

## 微信账号体系
- **大号**：绑定龙虾（main agent），accountId `YOUR_MAIN_BOT_ID`，user_id `YOUR_USER_ID@im.wechat`
- **小号**：绑定小秘书（secretary agent），accountId `YOUR_SECRETARY_BOT_ID`，user_id `YOUR_USER_ID@im.wechat`
- ⚠️ 微信 user_id 每次重新登录会变，cron delivery.to 需同步更新
- 🔴 **只用当前在线的 user_id 配置投递，旧的 ID 绝不能用于 delivery.to**
- ✅ 已配置 bindings 路由规则，大小号消息隔离

## 技能配置
- 已安装名人 Skills：张雪峰、马斯克、芒格、纳瓦尔、乔布斯、费曼、塔勒布
- 搜索策略：**一律用浏览器搜索，不依赖 Brave Search API**（已确认，无需配置 Brave API key）
- 报销技能路径：`~/.openclaw/skills/reimburse/`
- 日历脚本：`~/.openclaw/workspace-secretary/scripts/calendar-query.sh`
- 健康检查脚本：`~/.openclaw/skills/skills-healthcheck.sh`
- 调度中心：`~/.openclaw/skills/SKILL-DISPATCH.md`

## 笔记系统规范
- 文件夹：「💡 灵感」（Apple Notes）
- 命名：`💡 主题词 + 日期`（如 💡 AI科普自媒体 0409）
- 排列：状态标签 → 原文 → 整合润色 → 方案/建议
- 状态：🟡灵感中 → 🔵规划中 → 🟢执行中 → ✅完成 → ❌放弃
- **核心规则**：同一想法不论迭代几次，都放在同一页笔记里
- AppleScript 坑：中文变量名报错、set name 和 prepend body 有顺序依赖

## 关键技术备忘
- **微信 user_id 会变**：重新扫码登录后分配新 ID，cron 的 delivery.to 必须同步更新
- Watchdog 已删除（2026-04-14）：根因是 PATH 缺少 `/usr/sbin` 导致误判，修复后仍决定删掉，靠 Gateway 的 KeepAlive 自动重启足够
- 旧自动化助手 `com.openclaw.assistant.plist` 已删除（2026-04-14），功能已被 cron 系统完全取代
- GLM-5.1 偶发 429 限流，所有 agent 统一 fallback 链：GLM-5.1 → mimo-v2-pro → glm-4.7
- 播报系统自 4/7 修复 userId 后已稳定，连续多天三大核心播报全部成功
- Discord 插件随 OpenClaw 更新自动加载，每次重启 fetch failed 超时14秒，拖慢启动
- OpenClaw 版本：2026.4.9
- Mac mini 网络：DNS 解析到 198.18.x.x（代理劫持），终端/浏览器有时访问不了外网
- 权限状态：✅日历 ✅提醒事项 ✅Apple Notes ❌通讯录（未授权）

## Cron 任务清单（全部12个）

### Secretary 绑定（4个）— 走小号 YOUR_SECRETARY_BOT_ID
| 任务名 | 时间 | 用途 | 超时 | 状态 |
|--------|------|------|------|------|
| secretary-dream | 02:00 | 做梦：健康检查+记忆压缩+前瞻模拟 | 300s | ✅ |
| secretary-morning | 07:00 | 早安播报（天气+日程+穿搭） | 180s | ✅ |
| secretary-goodnight | 23:00 | 晚安播报 | 120s | ✅ |
| skills-healthcheck | 周一09:00 | 技能健康检查 | 默认 | 💤 首次待运行(4/20) |

### Main Agent 绑定（8个）— 走大号 YOUR_MAIN_BOT_ID
| 任务名 | 时间 | 用途 | 超时 | 状态 |
|--------|------|------|------|------|
| main-dream | 02:30 | 做梦：系统巡检+记忆整理+Bug追踪+项目巡检 | 300s | 💤 首次待运行(4/15) |
| transcript-backup | 每小时整点 | 会话备份 | 默认 | ✅ |
| 监控检查 | 每小时整点 | 系统监控 | 60s | ✅ |
| 每日报告 | 20:00 | 日报 | 默认 | ❌ 4/13超时 |
| weekly-report | 周日20:00 | 周报 | 180s | ✅ |
| gene-capsule | 04:00 | 基因胶囊打包 | 默认 | ❌ 4/13全模型超时 |
| security-scan | 周三03:00 | 安全扫描 | 180s | ✅ |
| skills-audit | 每月1号03:00 | 技能审计 | 120s | 💤 首次待运行(5/1) |

## 关键文件路径
- OpenClaw配置：`~/.openclaw/openclaw.json`
- Cron配置：`~/.openclaw/cron/jobs.json`
- Gateway端口：`18789`
- LaunchAgent：`~/Library/LaunchAgents/ai.openclaw.gateway.plist`（Gateway）+ `homebrew.mxcl.ollama.plist`（Ollama）
- 微信插件：`~/.openclaw/extensions/openclaw-weixin/`
- 微信数据库：`~/Library/Containers/com.tencent.xinWeChat/Data/Documents/xwechat_files/wxid_oselfo42m1x122_e10d/db_storage/`
- wechat-export-macos：`https://github.com/ydotdog/wechat-export-macos`

## 待办事项（技术类）
- [ ] 微信聊天记录导出（等主人重签微信）
- [ ] 通讯录权限（主人说后续再给）
- [x] ~~Watchdog 修复~~ → 已删除（2026-04-14），KeepAlive 足够
- [x] ~~morning-brief 超时~~ → 已删除该任务，secretary-morning 替代
- [x] ~~升级 OpenClaw CLI~~ — 主人决定暂不升级（CLI 2026.3.13 vs 配置 2026.4.9）

---
*技术细节统一放这里，不污染 MEMORY.md 📋*
