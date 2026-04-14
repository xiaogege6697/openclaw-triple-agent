#!/bin/bash
# OpenClaw A/B 测试框架
# 用于测试不同提示词、模型、配置的效果

AB_DIR="$HOME/.openclaw/ab-tests"
mkdir -p "$AB_DIR/results"

# 创建新测试
create_test() {
    local test_name=$1
    local test_type=$2  # prompt, model, config

    if [[ -z "$test_name" ]]; then
        echo "用法: $0 create <测试名称> <类型: prompt|model|config>"
        return
    fi

    local test_file="$AB_DIR/${test_name}.json"

    {
        echo "{"
        echo "  \"name\": \"$test_name\","
        echo "  \"type\": \"$test_type\","
        echo "  \"created\": \"$(date -Iseconds)\","
        echo "  \"status\": \"created\","
        echo "  \"variants\": [],"
        echo "  \"results\": {}"
        echo "}"
    } > "$test_file"

    echo "✓ 测试已创建: $test_file"
}

# 添加测试变体
add_variant() {
    local test_name=$1
    local variant_name=$2
    local config=$3

    if [[ -z "$test_name" || -z "$variant_name" ]]; then
        echo "用法: $0 variant <测试名称> <变体名称> <配置JSON>"
        return
    fi

    local test_file="$AB_DIR/${test_name}.json"

    if [[ ! -f "$test_file" ]]; then
        echo "测试不存在: $test_name"
        return
    fi

    # 使用 jq 添加变体
    jq ".variants += [{\"name\": \"$variant_name\", \"config\": $config, \"created\": \"$(date -Iseconds)\"}]" "$test_file" > "$test_file.tmp"
    mv "$test_file.tmp" "$test_file"

    echo "✓ 变体已添加: $variant_name"
}

# 记录测试结果
record_result() {
    local test_name=$1
    local variant_name=$2
    local metric=$3
    local value=$4

    local test_file="$AB_DIR/${test_name}.json"

    if [[ ! -f "$test_file" ]]; then
        echo "测试不存在: $test_name"
        return
    fi

    # 使用 jq 记录结果
    jq ".results.\"$variant_name\".\"$metric\" = \"$value\"" "$test_file" > "$test_file.tmp"
    mv "$test_file.tmp" "$test_file"

    echo "✓ 结果已记录: $variant_name.$metric = $value"
}

# 显示测试结果
show_results() {
    local test_name=$1

    if [[ -z "$test_name" ]]; then
        echo "可用测试:"
        ls -1 "$AB_DIR"/*.json 2>/dev/null | xargs -I {} basename {} .json
        return
    fi

    local test_file="$AB_DIR/${test_name}.json"

    if [[ ! -f "$test_file" ]]; then
        echo "测试不存在: $test_name"
        return
    fi

    echo "# A/B 测试结果: $test_name"
    echo ""
    jq '.' "$test_file"
}

# 比较变体
compare_variants() {
    local test_name=$1

    if [[ -z "$test_name" ]]; then
        echo "用法: $0 compare <测试名称>"
        return
    fi

    local test_file="$AB_DIR/${test_name}.json"

    if [[ ! -f "$test_file" ]]; then
        echo "测试不存在: $test_name"
        return
    fi

    echo "# 变体比较: $test_name"
    echo ""

    jq '.variants[] | "变体: \(.name)\n配置: \(.config)\n"' "$test_file"

    echo ""
    echo "结果:"
    jq '.results' "$test_file"
}

main() {
    case "${1:-help}" in
        create)
            create_test "$2" "$3"
            ;;
        variant)
            add_variant "$2" "$3" "$4"
            ;;
        result)
            record_result "$2" "$3" "$4" "$5"
            ;;
        show)
            show_results "$2"
            ;;
        compare)
            compare_variants "$2"
            ;;
        list)
            ls -1 "$AB_DIR"/*.json 2>/dev/null | xargs -I {} basename {} .json
            ;;
        *)
            echo "OpenClaw A/B 测试框架"
            echo ""
            echo "用法: $0 {create|variant|result|show|compare|list}"
            echo ""
            echo "命令:"
            echo "  create <名称> <类型>    - 创建新测试"
            echo "  variant <测试> <变体> <配置> - 添加测试变体"
            echo "  result <测试> <变体> <指标> <值> - 记录结果"
            echo "  show [测试名称]         - 显示测试结果"
            echo "  compare <测试名称>      - 比较测试变体"
            echo "  list                   - 列出所有测试"
            ;;
    esac
}

main "$@"
