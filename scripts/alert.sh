#!/bin/bash
# OpenClaw 异常监控告警系统
# 检测 API 失败率、记忆更新、Context 占比等异常

LOG_FILE="/tmp/openclaw-alert-$(date +%Y%m%d).log"
MEMORY_DIR="$HOME/.openclaw/memory"
WORKSPACE="$HOME/.openclaw/workspace"

# 颜色输出
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

log() {
    local level="$1"
    shift
    local msg="$*"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [${level}] ${msg}" | tee -a "$LOG_FILE"
}

# 检查 API 失败率
check_api_failure_rate() {
    local log_file="/tmp/openclaw/openclaw-$(date +%Y-%m-%d).log"

    if [[ ! -f "$log_file" ]]; then
        log "INFO" "今日日志文件不存在，跳过 API 检查"
        return
    fi

    local total_requests=$(grep -c "embedded run agent end" "$log_file" 2>/dev/null | tr -d '\n' || echo 0)
    local failed_requests=$(grep -c "embedded_run_agent_end.*isError.*true" "$log_file" 2>/dev/null | tr -d '\n' || echo 0)

    # 去除空白并确保是数字
    total_requests=$(echo "$total_requests" | tr -d '[:space:]')
    failed_requests=$(echo "$failed_requests" | tr -d '[:space:]')
    total_requests=${total_requests:-0}
    failed_requests=${failed_requests:-0}

    if [[ "$total_requests" -eq 0 ]] 2>/dev/null; then
        log "INFO" "暂无 API 请求记录"
        return
    fi

    local failure_rate=$(echo "scale=2; $failed_requests * 100 / $total_requests" | bc)

    log "INFO" "API 失败率: ${failure_rate}% (${failed_requests}/${total_requests})"

    if (( $(echo "$failure_rate > 30" | bc -l) )); then
        log "${RED}ALERT${NC}" "API 失败率过高: ${failure_rate}%"
        echo "⚠️ OpenClaw API 失败率异常: ${failure_rate}%" > ~/.openclaw/shared/notifications/api-alert.txt
    fi
}

# 检查记忆文件更新
check_memory_update() {
    local latest_file=$(ls -t "$MEMORY_DIR"/2026-*.md 2>/dev/null | head -1)

    if [[ -z "$latest_file" ]]; then
        log "${YELLOW}WARN${NC}" "未找到记忆文件"
        return
    fi

    local last_update=$(stat -f "%m" "$latest_file" 2>/dev/null || stat -c "%Y" "$latest_file")
    local current_time=$(date +%s)
    local hours_since_update=$(( (current_time - last_update) / 3600 ))

    log "INFO" "距离上次记忆更新: ${hours_since_update} 小时"

    if [[ $hours_since_update -gt 24 ]]; then
        log "${RED}ALERT${NC}" "记忆文件超过 24 小时未更新"
        echo "⚠️ 记忆文件需要更新" > ~/.openclaw/shared/notifications/memory-alert.txt
    fi
}

# 检查 Gateway 状态
check_gateway_status() {
    # 优先检测端口（最可靠）
    if lsof -i :18789 >/dev/null 2>&1; then
        log "INFO" "Gateway 运行正常 (端口检测)"
        return 0
    fi

    # fallback: 进程检测（排除 grep 自身和 cron 子进程）
    if pgrep -f "openclaw.*gateway" >/dev/null 2>&1; then
        log "INFO" "Gateway 运行正常 (进程检测)"
        return 0
    fi

    log "ALERT" "Gateway 未运行"
    echo "⚠️ Gateway 未运行" > ~/.openclaw/shared/notifications/gateway-alert.txt
    return 1
}

# 生成摘要报告
generate_summary() {
    local summary_file="$HOME/.openclaw/shared/notifications/daily-summary.txt"

    {
        echo "📊 OpenClaw 每日监控摘要"
        echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "--- 系统状态 ---"
        check_gateway_status && echo "✅ Gateway: 运行中" || echo "❌ Gateway: 未运行"
        echo ""
        echo "--- API 状态 ---"
        check_api_failure_rate
        echo ""
        echo "--- 记忆状态 ---"
        check_memory_update
    } > "$summary_file"

    log "INFO" "每日摘要已生成: $summary_file"
}

# 主函数
main() {
    log "INFO" "=== OpenClaw 监控检查开始 ==="

    check_gateway_status
    check_api_failure_rate
    check_memory_update

    generate_summary

    log "INFO" "=== 监控检查完成 ==="
}

# 执行
main "$@"
