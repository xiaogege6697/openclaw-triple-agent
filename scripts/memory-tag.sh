#!/bin/bash
# 记忆系统升级 - 标签分类系统

MEMORY_DIR="$HOME/.openclaw/memory"
TAGS_DIR="$MEMORY_DIR/tags"
WORK_DIR="$MEMORY_DIR/work"
LIFE_DIR="$MEMORY_DIR/life"
IDEAS_DIR="$MEMORY_DIR/ideas"
TASKS_DIR="$MEMORY_DIR/tasks"

# 确保目录存在
mkdir -p "$TAGS_DIR"/{work,life,ideas,tasks}

# 分析今日记忆文件并添加标签
analyze_and_tag() {
    local today_file="$MEMORY_DIR/$(date +%Y-%m-%d).md"

    if [[ ! -f "$today_file" ]]; then
        echo "今日记忆文件不存在"
        return
    fi

    # 创建标签索引
    local tag_index="$MEMORY_DIR/tags/index.md"

    {
        echo "# 记忆标签索引"
        echo ""
        echo "**更新时间**: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "## 分类"
        echo ""
        echo "- 🏢 **工作** ([work](./work/))"
        echo "- 🏠 **生活** ([life](./life/))"
        echo "- 💡 **想法** ([ideas](./ideas/))"
        echo "- ✅ **任务** ([tasks](./tasks/))"
        echo ""
        echo "## 今日标签"
        echo ""

        # 检测关键词并建议标签
        if grep -qi "会议\|项目\|工作\|客户\|合同" "$today_file"; then
            echo "- 🏢 工作"
        fi

        if grep -qi "购物\|家庭\|朋友\|娱乐\|运动" "$today_file"; then
            echo "- 🏠 生活"
        fi

        if grep -qi "想法\|建议\|创新\|改进" "$today_file"; then
            echo "- 💡 想法"
        fi

        if grep -qi "todo\|待办\|计划\|安排" "$today_file"; then
            echo "- ✅ 任务"
        fi

    } > "$tag_index"

    echo "✓ 标签索引已更新"
}

# 创建标签链接
create_tag_links() {
    local today_file="$MEMORY_DIR/$(date +%Y-%m-%d).md"

    if [[ ! -f "$today_file" ]]; then
        return
    fi

    # 在今日记忆文件末尾添加标签引用
    if ! grep -q "## 标签" "$today_file"; then
        {
            echo ""
            echo "---"
            echo ""
            echo "## 标签"
            echo ""
            echo "[返回标签索引](../tags/index.md)"
        } >> "$today_file"
    fi

    echo "✓ 标签链接已创建"
}

# 搜索特定标签
search_by_tag() {
    local tag=$1

    if [[ -z "$tag" ]]; then
        echo "请指定标签: work, life, ideas, tasks"
        return
    fi

    echo "搜索标签: $tag"
    echo ""

    case $tag in
        work)
            grep -r "会议\|项目\|工作\|客户" "$MEMORY_DIR"/2026-*.md 2>/dev/null | head -10
            ;;
        life)
            grep -r "购物\|家庭\|朋友\|娱乐" "$MEMORY_DIR"/2026-*.md 2>/dev/null | head -10
            ;;
        ideas)
            grep -r "想法\|建议\|创新\|改进" "$MEMORY_DIR"/2026-*.md 2>/dev/null | head -10
            ;;
        tasks)
            grep -r "todo\|待办\|计划\|安排" "$MEMORY_DIR"/2026-*.md 2>/dev/null | head -10
            ;;
        *)
            echo "未知标签: $tag"
            ;;
    esac
}

main() {
    case "${1:-update}" in
        update)
            analyze_and_tag
            create_tag_links
            ;;
        search)
            search_by_tag "$2"
            ;;
        *)
            echo "用法: $0 {update|search} [tag]"
            ;;
    esac
}

main "$@"
