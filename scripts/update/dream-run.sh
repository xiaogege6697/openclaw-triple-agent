#!/bin/bash
# dream-run.sh — Dream 总控脚本
# 用途：采集系统数据+准备素材，供 dream prompt 读取
# 调用：cron 直接调用此脚本，输出 dream-context.json
# 逐字稿由 agent 实时写入 transcripts/main/{date}.md，不再需要提取步骤

set -euo pipefail

WS="$HOME/.openclaw/workspace-main"
MEMORY_DIR="$WS/memory"
TODAY=$(date +%Y-%m-%d)

# ── 1. 数据采集 ──
echo "## 采集系统数据..." >&2
collect_output="$MEMORY_DIR/dream-collect-$TODAY.md"
~/.openclaw/scripts/dream-collect.sh > "$collect_output"

# ── 2. 汇总上下文 ──
echo "## 汇总上下文..." >&2
context_file="$MEMORY_DIR/dream-context.json"

# 检查逐字稿文件是否存在
TRANSCRIPT_FILE="$WS/transcripts/main/$TODAY.md"
if [[ -f "$TRANSCRIPT_FILE" ]]; then
    TRANSCRIPT_STATUS="\"transcripts/main/$TODAY.md\""
else
    TRANSCRIPT_STATUS="null"
fi

cat > "$context_file" << EOF
{
  "date": "$TODAY",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "workspace": "$WS",
  "files": {
    "transcript": $TRANSCRIPT_STATUS,
    "collect": "dream-collect-$TODAY.md",
    "MEMORY": "MEMORY.md",
    "AGENTS": "AGENTS.md",
    "SOUL": "SOUL.md",
    "previous_dream": "memory/${TODAY}.md"
  }
}
EOF

echo "✅ Dream 准备完成: $context_file" >&2
cat "$context_file"
