#!/bin/bash
# dream-collect.sh — 梦境数据采集脚本
# 一次性收集所有 dream 需要的数据，输出到 stdout
# AI 只需读一次结果文件即可完成总结

set -euo pipefail
TODAY=$(date +%Y-%m-%d)
WS="$HOME/.openclaw/workspace-main"

echo "=========================================="
echo "🌙 Dream 数据采集 $TODAY"
echo "=========================================="
echo ""

echo "=== P1 系统巡检 ==="
echo "--- Gateway ---"
openclaw gateway status 2>&1 | head -5
echo ""
echo "--- 磁盘 ---"
df -h / | tail -1
echo ""
echo "--- Ollama ---"
curl -s --max-time 5 http://localhost:11434/api/tags 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{len(d.get(\"models\",[]))} models loaded')" 2>&1 || echo "Ollama 未响应"
echo ""
echo "--- Cron 状态 ---"
openclaw cron list 2>&1 | grep -E "^(ID|monitoring|dashboard|gene-capsule|main-dream|secretary|security|weekly|skills|transcript)" || true
echo ""
echo "--- GitHub ---"
gh auth status 2>&1 | head -3 || echo "gh 未配置"
echo ""
echo "--- 跨 Agent ---"
tail -5 "$HOME/.openclaw/workspace-secretary/memory/tidy.log" 2>/dev/null || echo "无小秘书日志"
echo ""

echo "=== P2 记忆状态 ==="
echo "--- MEMORY.md 行数 ---"
wc -l "$WS/MEMORY.md" 2>/dev/null || echo "无"
echo ""
echo "--- 最近3天日志 ---"
for i in 0 1 2; do
    d=$(date -j -v-${i}d +%Y-%m-%d 2>/dev/null || date -d "$i days ago" +%Y-%m-%d 2>/dev/null)
    f="$WS/memory/${d}.md"
    if [ -f "$f" ]; then
        echo "  $d: $(wc -l < "$f") 行, $(du -sh "$f" | cut -f1)"
    else
        echo "  $d: 不存在"
    fi
done
echo ""
echo "--- 待归档文件（>7天）---"
find "$WS/memory" -maxdepth 1 -name "2026-*.md" -mtime +7 2>/dev/null | sort | while read f; do
    echo "  $(basename "$f")"
done
echo ""

echo "=== P4 Bug 追踪 ==="
grep -n "⚠️\|📌\|🚫" "$WS/MEMORY.md" 2>/dev/null || echo "无已知 bug"
echo ""

echo "=== P5 项目巡检 ==="
echo "--- GitHub 仓库 ---"
gh repo list --limit 10 2>&1 | head -10 || echo "gh 未配置"
echo ""
echo "--- 基因胶囊最新 ---"
ls -lt "$HOME/.openclaw"/gene-capsule-*.tar.gz 2>/dev/null | head -3 || echo "无胶囊"
echo ""

echo "=== P6 临时文件 ==="
echo "--- /tmp 大文件 ---"
find /tmp -name "*.log" -size +5M 2>/dev/null | head -5 || echo "无"
echo ""
echo "--- workspace 磁盘 ---"
du -sh "$WS/" 2>/dev/null
du -sh "$HOME/.openclaw/" 2>/dev/null
echo ""

echo "=== P7 前瞻 ==="
echo "--- PAT 到期 ---"
echo "到期日: 2026-05-11"
echo "剩余: $(( ( $(date -j -f "%Y-%m-%d" "2026-05-11" +%s 2>/dev/null || date -d "2026-05-11" +%s) - $(date +%s) ) / 86400 )) 天"
echo ""
echo "--- 异常 cron ---"
openclaw cron list 2>&1 | grep -i "error\|fail\|timeout" || echo "无异常"
echo ""

echo "=== P8 监控历史 ==="
echo "--- 今日监控日志 ---"
cat "$WS/memory/monitoring/$(date +%Y-%m-%d).md" 2>/dev/null || echo "无监控日志"
echo ""
echo "--- 近3天监控异常汇总 ---"
for i in 0 1 2; do
    d=$(date -j -v-${i}d +%Y-%m-%d 2>/dev/null || date -d "$i days ago" +%Y-%m-%d 2>/dev/null)
    f="$WS/memory/monitoring/${d}.md"
    if [ -f "$f" ]; then
        alerts=$(grep -c "❌\|ALERT" "$f" 2>/dev/null || echo 0)
        echo "  $d: $(grep -c "^##" "$f" 2>/dev/null || echo 0) 次检查, $alerts 个异常"
    fi
done
echo ""

echo "=== 采集完成 ==="
