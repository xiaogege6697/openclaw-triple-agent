#!/bin/bash
# OpenClaw 应急机制 - 自动故障恢复

LOG_FILE="/tmp/openclaw-emergency-$(date +%Y%m%d).log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" | tee -a "$LOG_FILE"
}

# 应急重启 Gateway
emergency_restart_gateway() {
    log "EMERGENCY" "Gateway 异常，尝试重启..."

    # 停止现有进程
    launchctl bootout gui/$(id -u)/ai.openclaw.gateway 2>/dev/null
    pkill -9 -f openclaw-gateway 2>/dev/null
    sleep 2

    # 重新安装
    /opt/homebrew/bin/openclaw gateway install --force >/dev/null 2>&1

    # 等待启动
    sleep 3

    if lsof -i :18789 >/dev/null 2>&1; then
        log "SUCCESS" "Gateway 重启成功"
        echo "✅ Gateway 已重启" > ~/.openclaw/shared/notifications/gateway-recovered.txt
        return 0
    else
        log "ERROR" "Gateway 重启失败"
        return 1
    fi
}

# 检查并恢复记忆文件
check_memory_integrity() {
    local memory_file="$HOME/.openclaw/memory/$(date +%Y-%m-%d).md"

    if [[ -f "$memory_file" ]]; then
        local size=$(wc -c < "$memory_file" 2>/dev/null || echo 0)

        # 如果文件异常小，从备份恢复
        if [[ $size -lt 100 ]]; then
            log "WARN" "记忆文件异常，尝试从备份恢复..."

            local backup=$(ls -t ~/.openclaw/workspace/backups/memory-*.tar.gz 2>/dev/null | head -1)
            if [[ -n "$backup" ]]; then
                tar -xzf "$backup" -C ~/.openclaw/memory/ 2>/dev/null
                log "SUCCESS" "记忆文件已恢复"
            fi
        fi
    fi
}

# 检查配置文件完整性
check_config_integrity() {
    local config="$HOME/.openclaw/openclaw.json"

    if ! jq empty "$config" 2>/dev/null; then
        log "ERROR" "配置文件损坏，从备份恢复..."

        local backup=$(ls -t ~/.openclaw/openclaw.json.bak.* 2>/dev/null | head -1)
        if [[ -n "$backup" ]]; then
            cp "$backup" "$config"
            log "SUCCESS" "配置文件已恢复"

            # 重启 Gateway 使配置生效
            /opt/homebrew/bin/openclaw gateway restart >/dev/null 2>&1
        fi
    fi
}

# 清理异常会话
cleanup_corrupted_sessions() {
    local session_dir="$HOME/.openclaw/agents/main/sessions"

    if [[ -d "$session_dir" ]]; then
        # 查找并标记损坏的会话文件
        find "$session_dir" -name "*.jsonl" -size 0 -exec mv {} {}.corrupted \; 2>/dev/null

        log "INFO" "已清理损坏的会话文件"
    fi
}

# 主应急检查
main() {
    log "INFO" "=== OpenClaw 应急检查开始 ==="

    local issues_found=0

    # 检查 Gateway
    if ! lsof -i :18789 >/dev/null 2>&1; then
        log "ALERT" "Gateway 未运行"
        emergency_restart_gateway
        ((issues_found++))
    fi

    # 检查记忆完整性
    check_memory_integrity

    # 检查配置完整性
    check_config_integrity

    # 清理损坏会话
    cleanup_corrupted_sessions

    log "INFO" "=== 应急检查完成，发现问题: $issues_found ==="
}

main "$@"
