#!/bin/bash
# 影响范围检查工具
# 用法: impact-check.sh "关键词或路径片段"
# 输出: 所有引用了该关键词的文件 + 行号 + 内容摘要

QUERY="$1"

if [[ -z "$QUERY" ]]; then
    echo "用法: impact-check.sh \"关键词或路径片段\""
    echo "示例: impact-check.sh \"transcripts/main\""
    echo "      impact-check.sh \"dream-learnings\""
    echo "      impact-check.sh \"memory/entities\""
    exit 1
fi

WORKSPACE="$HOME/.openclaw/workspace-main"
SCRIPTS_DIR="$HOME/.openclaw/scripts"
PROMPTS_DIR="$WORKSPACE/prompts"
FOUND=0

echo "🔍 影响范围检查: \"$QUERY\""
echo "================================"
echo ""

# 1. 扫描 scripts/
echo "📜 scripts/"
echo "------------"
if ls "$SCRIPTS_DIR"/*.sh >/dev/null 2>&1; then
    for f in "$SCRIPTS_DIR"/*.sh; do
        matches=$(grep -n "$QUERY" "$f" 2>/dev/null)
        if [[ -n "$matches" ]]; then
            FOUND=1
            echo "  📄 $(basename "$f"):"
            echo "$matches" | while IFS= read -r line; do
                # 提取行号和内容摘要
                linenum=$(echo "$line" | cut -d: -f1)
                content=$(echo "$line" | cut -d: -f2- | sed 's/^[[:space:]]*//' | cut -c1-120)
                echo "    L$linenum: $content"
            done
            echo ""
        fi
    done
fi
if [[ $FOUND -eq 0 ]] || ! ls "$SCRIPTS_DIR"/*.sh >/dev/null 2>&1; then
    echo "  （无匹配）"
    echo ""
fi

# 2. 扫描 prompts/
echo "📝 prompts/"
echo "------------"
SECTION_FOUND=0
if ls "$PROMPTS_DIR"/*.md >/dev/null 2>&1; then
    for f in "$PROMPTS_DIR"/*.md; do
        matches=$(grep -n "$QUERY" "$f" 2>/dev/null)
        if [[ -n "$matches" ]]; then
            FOUND=1
            SECTION_FOUND=1
            echo "  📄 $(basename "$f"):"
            echo "$matches" | while IFS= read -r line; do
                linenum=$(echo "$line" | cut -d: -f1)
                content=$(echo "$line" | cut -d: -f2- | sed 's/^[[:space:]]*//' | cut -c1-120)
                echo "    L$linenum: $content"
            done
            echo ""
        fi
    done
fi
if [[ $SECTION_FOUND -eq 0 ]]; then
    echo "  （无匹配）"
    echo ""
fi

# 3. 扫描 workspace 根目录的系统文件
echo "📋 系统文件 (AGENTS.md / MEMORY.md / SOUL.md / USER.md / TOOLS.md)"
echo "------------"
SECTION_FOUND=0
for f in "$WORKSPACE"/AGENTS.md "$WORKSPACE"/MEMORY.md "$WORKSPACE"/SOUL.md "$WORKSPACE"/USER.md "$WORKSPACE"/TOOLS.md; do
    if [[ -f "$f" ]]; then
        matches=$(grep -n "$QUERY" "$f" 2>/dev/null)
        if [[ -n "$matches" ]]; then
            FOUND=1
            SECTION_FOUND=1
            echo "  📄 $(basename "$f"):"
            echo "$matches" | while IFS= read -r line; do
                linenum=$(echo "$line" | cut -d: -f1)
                content=$(echo "$line" | cut -d: -f2- | sed 's/^[[:space:]]*//' | cut -c1-120)
                echo "    L$linenum: $content"
            done
            echo ""
        fi
    fi
done
if [[ $SECTION_FOUND -eq 0 ]]; then
    echo "  （无匹配）"
    echo ""
fi

# 4. 扫描 cron prompts
echo "⏰ Cron 任务"
echo "------------"
SECTION_FOUND=0
openclaw cron list 2>/dev/null | while read -r line; do
    id=$(echo "$line" | grep -oE '^[a-f0-9-]+' | head -1)
    name=$(echo "$line" | grep -oE '(main-dream|secretary-dream|research-dream|monitoring-hourly|dashboard-daily|weekly-report|secretary-morning|memory-maintenance)' | head -1)
    if [[ -z "$name" ]]; then
        name=$(echo "$line" | awk '{print $2}')
    fi
    if [[ -n "$id" ]]; then
        msg=$(openclaw cron show "$id" --json 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
msg = data.get('payload', {}).get('message', '')
if '$QUERY' in msg:
    lines = msg.split('\n')
    for i, l in enumerate(lines, 1):
        if '$QUERY' in l:
            print(f'L{i}: {l.strip()[:120]}')
" 2>/dev/null)
        if [[ -n "$msg" ]]; then
            FOUND=1
            SECTION_FOUND=1
            echo "  ⏰ cron:$name"
            echo "$msg" | while IFS= read -r l; do
                echo "    $l"
            done
            echo ""
        fi
    fi
done
# 由于子 shell 问题，SECTION_FOUND 在外层不可用，用文件标记
if [[ -f /tmp/impact-check-cron-found ]]; then
    rm /tmp/impact-check-cron-found
fi

# 用另一种方式处理 cron
openclaw cron list 2>/dev/null | head -20 | while read -r line; do
    id=$(echo "$line" | grep -oE '^[a-f0-9-]+' | head -1)
    name=$(echo "$line" | grep -oE '(main-dream|secretary-dream|research-dream|monitoring-hourly|dashboard-daily|weekly-report|secretary-morning|memory-maintenance)' | head -1)
    if [[ -z "$name" ]]; then
        name=$(echo "$line" | awk '{print $2}')
    fi
    if [[ -n "$id" ]]; then
        msg=$(openclaw cron show "$id" --json 2>/dev/null)
        if echo "$msg" | grep -q "$QUERY" 2>/dev/null; then
            touch /tmp/impact-check-cron-found
            echo "  ⏰ cron:$name"
            echo "$msg" | python3 -c "
import sys, json
data = json.load(sys.stdin)
msg = data.get('payload', {}).get('message', '')
lines = msg.split('\n')
for i, l in enumerate(lines, 1):
    if '$QUERY' in l:
        print(f'    L{i}: {l.strip()[:120]}')
" 2>/dev/null
            echo ""
        fi
    fi
done

if [[ ! -f /tmp/impact-check-cron-found ]]; then
    echo "  （无匹配）"
    echo ""
fi
rm -f /tmp/impact-check-cron-found

# 5. 扫描 openclaw.json
echo "⚙️ openclaw.json"
echo "------------"
if [[ -f "$HOME/.openclaw/openclaw.json" ]]; then
    matches=$(grep -n "$QUERY" "$HOME/.openclaw/openclaw.json" 2>/dev/null)
    if [[ -n "$matches" ]]; then
        FOUND=1
        echo "$matches" | while IFS= read -r line; do
            linenum=$(echo "$line" | cut -d: -f1)
            content=$(echo "$line" | cut -d: -f2- | sed 's/^[[:space:]]*//' | cut -c1-120)
            echo "  L$linenum: $content"
        done
        echo ""
    else
        echo "  （无匹配）"
        echo ""
    fi
else
    echo "  （文件不存在）"
    echo ""
fi

# 汇总
echo "================================"
if [[ $FOUND -eq 1 ]]; then
    echo "⚠️ 发现引用，变更前请逐项确认影响"
else
    echo "✅ 未发现引用，变更风险较低"
fi
