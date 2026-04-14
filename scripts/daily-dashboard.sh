#!/bin/bash
# OpenClaw 监控仪表盘 - 生成每日/每周统计报告

REPORT_DIR="$HOME/.openclaw/reports"
mkdir -p "$REPORT_DIR"

TODAY=$(date +%Y-%m-%d)
WEEK_START=$(date -v-sun +%Y-%m-%d 2>/dev/null || date -d "last sunday" +%Y-%m-%d)

# 颜色
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

# 生成每日报告
generate_daily_report() {
    local report_file="$REPORT_DIR/daily-$TODAY.md"
    local log_file="/tmp/openclaw/openclaw-$(date +%Y-%m-%d).log"

    {
        echo "# 📊 OpenClaw 每日报告"
        echo ""
        echo "**日期**: $TODAY"
        echo ""
        echo "---"
        echo ""
        echo "## 🤖 模型使用统计"
        echo ""

        if [[ -f "$log_file" ]]; then
            echo "\`\`\`"
            grep "model:" "$log_file" 2>/dev/null | sort | uniq -c | sort -rn || echo "暂无数据"
            echo "\`\`\`"
        else
            echo "暂无今日日志"
        fi

        echo ""
        echo "## ⚠️ 错误和异常"
        echo ""

        if [[ -f "$log_file" ]]; then
            local error_count=$(grep -c "ERROR\|FATAL" "$log_file" 2>/dev/null || echo 0)
            echo "**错误数量**: $error_count"
            echo ""
            echo "\`\`\`"
            grep "ERROR\|FATAL" "$log_file" 2>/dev/null | tail -5 || echo "无错误"
            echo "\`\`\`"
        fi

        echo ""
        echo "## 💾 记忆写入"
        echo ""

        local memory_file="$HOME/.openclaw/memory/$TODAY.md"
        if [[ -f "$memory_file" ]]; then
            local size=$(wc -c < "$memory_file" 2>/dev/null || echo 0)
            local lines=$(wc -l < "$memory_file" 2>/dev/null || echo 0)
            echo "**文件**: $memory_file"
            echo "**大小**: $size bytes"
            echo "**行数**: $lines"
        else
            echo "今日暂无记忆文件"
        fi

        echo ""
        echo "---"
        echo ""
        echo "*报告生成时间: $(date '+%H:%M:%S')*"
    } > "$report_file"

    echo -e "${GREEN}✓${NC} 每日报告已生成: $report_file"
}

# 生成每周报告
generate_weekly_report() {
    local report_file="$REPORT_DIR/weekly-$(date +%Y-W%V).md"

    {
        echo "# 📈 OpenClaw 每周报告"
        echo ""
        echo "**周期**: $WEEK_START 至 $TODAY"
        echo ""
        echo "---"
        echo ""
        echo "## 🎯 本周概览"
        echo ""

        # 统计本日记记录
        local memory_count=$(find "$HOME/.openclaw/memory" -name "2026-*.md" -newermt "$WEEK_START" 2>/dev/null | wc -l)
        echo "**记记录天数**: $memory_count"

        # 统计总记忆大小
        local total_size=$(find "$HOME/.openclaw/memory" -name "2026-*.md" -newermt "$WEEK_START" -exec wc -c {} + 2>/dev/null | tail -1 || echo 0)
        echo "**记忆总量**: $total_size bytes"

        echo ""
        echo "## 📊 模型使用分布"
        echo ""

        # 汇总本周所有日志
        local logs=$(find /tmp/openclaw -name "openclaw-2026-*.log" -newermt "$WEEK_START" 2>/dev/null)
        if [[ -n "$logs" ]]; then
            echo "\`\`\`"
            grep -h "model:" $logs 2>/dev/null | sort | uniq -c | sort -rn || echo "暂无数据"
            echo "\`\`\`"
        fi

        echo ""
        echo "---"
        echo ""
        echo "*报告生成时间: $(date '+%Y-%m-%d %H:%M:%S')*"
    } > "$report_file"

    echo -e "${GREEN}✓${NC} 每周报告已生成: $report_file"
}

# 主函数
main() {
    echo -e "${BLUE}=== OpenClaw 监控仪表盘 ===${NC}"
    echo ""

    generate_daily_report
    generate_weekly_report

    echo ""
    echo -e "${GREEN}报告目录: $REPORT_DIR${NC}"
}

main "$@"
