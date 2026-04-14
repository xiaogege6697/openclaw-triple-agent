#!/bin/bash
# ============================================================
# OpenClaw Triple Agent 一键安装脚本
# 三 Agent 架构: main 😎 + secretary 🌸 + guest 🎮
# ============================================================
set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

OPENCLAW_DIR="$HOME/.openclaw"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo -e "${CYAN}🦞 OpenClaw Triple Agent 安装器${NC}"
echo -e "${CYAN}==============================${NC}"
echo ""

# ---- 1. 环境检查 ----
echo -e "${BLUE}📋 Step 1: 环境检查${NC}"

check_command() {
    if command -v "$1" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

MISSING=0

if ! check_command node; then
    echo -e "  ${RED}✗ Node.js 未安装${NC} (需要 >= 20)"
    echo -e "    安装: brew install node 或 https://nodejs.org"
    MISSING=1
else
    NODE_VER=$(node -v | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_VER" -lt 20 ]; then
        echo -e "  ${RED}✗ Node.js 版本过低: $(node -v) (需要 >= 20)${NC}"
        MISSING=1
    else
        echo -e "  ${GREEN}✓ Node.js $(node -v)${NC}"
    fi
fi

if ! check_command openclaw; then
    echo -e "  ${YELLOW}⚠ OpenClaw CLI 未安装${NC}"
    echo -e "    正在安装: npm install -g openclaw"
    npm install -g openclaw 2>/dev/null || {
        echo -e "  ${RED}✗ 安装失败，请手动执行: npm install -g openclaw${NC}"
        MISSING=1
    }
else
    echo -e "  ${GREEN}✓ OpenClaw $(openclaw --version 2>/dev/null || echo 'installed')${NC}"
fi

if ! check_command python3; then
    echo -e "  ${YELLOW}⚠ python3 未安装（用于 JSON 处理）${NC}"
    MISSING=1
else
    echo -e "  ${GREEN}✓ python3$(python3 --version 2>/dev/null | sed 's/python//')${NC}"
fi

if ! check_command git; then
    echo -e "  ${YELLOW}⚠ git 未安装${NC}"
    MISSING=1
else
    echo -e "  ${GREEN}✓ git$(git --version | sed 's/git//')${NC}"
fi

if [ "$MISSING" -eq 1 ]; then
    echo ""
    echo -e "${RED}请先安装缺失的依赖，然后重新运行。${NC}"
    exit 1
fi

echo ""

# ---- 2. 安装模式选择 ----
echo -e "${BLUE}📋 Step 2: 选择安装模式${NC}"
echo "  1) 完整安装（三 Agent + 微信 + Cron + Skills）"
echo "  2) 最小安装（main Agent + 模型配置）"
echo "  3) Claude Code 调试模式（main + 本地模型）"
echo ""
read -p "选择 [1-3, 默认 1]: " INSTALL_MODE
INSTALL_MODE=${INSTALL_MODE:-1}

echo ""

# ---- 3. 配置大模型 ----
echo -e "${BLUE}📋 Step 3: 配置大模型${NC}"
echo "  1) 智谱 GLM（推荐，国内免费套餐）"
echo "  2) OpenAI / 兼容 API"
echo "  3) 本地 Ollama（无需 API Key）"
echo "  4) 小米 MiMo"
echo "  5) 自定义 OpenAI 兼容"
echo ""
read -p "选择提供商 [1-5]: " MODEL_CHOICE

case $MODEL_CHOICE in
    1)
        PROVIDER="zai"
        BASE_URL="https://open.bigmodel.cn/api/paas/v4"
        read -p "智谱 API Key: " API_KEY
        PRIMARY_MODEL="glm-4.7-flash"
        ;;
    2)
        PROVIDER="openai"
        read -p "Base URL [https://api.openai.com/v1]: " BASE_URL
        BASE_URL=${BASE_URL:-"https://api.openai.com/v1"}
        read -p "API Key: " API_KEY
        PRIMARY_MODEL="gpt-4o-mini"
        ;;
    3)
        PROVIDER="ollama"
        BASE_URL="http://localhost:11434/v1"
        API_KEY="ollama"
        PRIMARY_MODEL="qwen2.5"
        echo -e "  ${YELLOW}确保 Ollama 已启动且模型已下载${NC}"
        ;;
    4)
        PROVIDER="xiaomi"
        BASE_URL="https://api.xiaomimimo.com/v1"
        read -p "MiMo API Key: " API_KEY
        PRIMARY_MODEL="mimo-v2-pro"
        ;;
    5)
        PROVIDER="custom"
        read -p "Provider 名称: " PROVIDER
        read -p "Base URL: " BASE_URL
        read -p "API Key: " API_KEY
        read -p "模型 ID: " PRIMARY_MODEL
        ;;
    *)
        echo -e "${RED}无效选择${NC}"
        exit 1
        ;;
esac

# 验证 API 连通性
echo -e "\n${YELLOW}🔄 验证 API 连通性...${NC}"
if [ "$PROVIDER" != "ollama" ]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
        "$BASE_URL/models" \
        -H "Authorization: Bearer $API_KEY" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ]; then
        echo -e "  ${GREEN}✓ API 可达 (HTTP $HTTP_CODE)${NC}"
    else
        echo -e "  ${YELLOW}⚠ API 返回 HTTP $HTTP_CODE，继续但可能需要检查配置${NC}"
    fi
else
    if curl -s --max-time 5 "$BASE_URL/models" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Ollama 可达${NC}"
    else
        echo -e "  ${YELLOW}⚠ Ollama 未响应，请确保已启动${NC}"
    fi
fi

echo ""

# ---- 4. 创建目录结构 ----
echo -e "${BLUE}📋 Step 4: 创建目录结构${NC}"

mkdir -p "$OPENCLAW_DIR"/{agents/main,agents/secretary,agents/guest}
mkdir -p "$OPENCLAW_DIR"/{workspace-main,workspace-secretary,workspace-guest}
mkdir -p "$OPENCLAW_DIR"/{scripts,cron,credentials}
mkdir -p "$OPENCLAW_DIR"/workspace-main/memory
mkdir -p "$OPENCLAW_DIR"/workspace-secretary/memory

echo -e "  ${GREEN}✓ 目录已创建${NC}"

# ---- 5. 复制 workspace 模板 ----
echo -e "${BLUE}📋 Step 5: 复制 Agent 工作区模板${NC}"

for agent in main secretary guest; do
    WS="$OPENCLAW_DIR/workspace-$agent"
    for f in SOUL.md AGENTS.md IDENTITY.md TOOLS.md HEARTBEAT.md BOOTSTRAP.md MEMORY.md USER.md; do
        if [ -f "$SCRIPT_DIR/workspaces/$agent/$f" ]; then
            cp "$SCRIPT_DIR/workspaces/$agent/$f" "$WS/$f"
        fi
    done
    echo -e "  ${GREEN}✓ $agent workspace 已配置${NC}"
done

echo ""

# ---- 6. 生成 openclaw.json ----
echo -e "${BLUE}📋 Step 6: 生成配置文件${NC}"

python3 << PYEOF
import json, secrets

with open('$SCRIPT_DIR/config/openclaw.json.template', 'r') as f:
    config = json.load(f)

# 1. 写入 API Key
provider_key = '$PROVIDER'
api_key = '$API_KEY'
base_url = '$BASE_URL'
primary_model = '$PRIMARY_MODEL'

# 确保 providers 中有选中的 provider
if 'models' not in config:
    config['models'] = {'providers': {}}
if 'providers' not in config['models']:
    config['models']['providers'] = {}

# 更新或创建 provider
if provider_key in config['models']['providers']:
    config['models']['providers'][provider_key]['apiKey'] = api_key
    if base_url:
        config['models']['providers'][provider_key]['baseUrl'] = base_url
else:
    config['models']['providers'][provider_key] = {
        'baseUrl': base_url,
        'api': 'openai-completions',
        'apiKey': api_key,
        'models': [{
            'id': primary_model,
            'name': primary_model,
            'reasoning': False,
            'input': ['text'],
            'contextWindow': 128000,
            'maxTokens': 8192
        }]
    }

# 2. 更新默认模型
config['agents']['defaults']['model']['primary'] = f'{provider_key}/{primary_model}'
# 清空 fallback（用户后续可自行配置）
config['agents']['defaults']['model']['fallbacks'] = []

# 3. 更新所有 agent 的模型
for agent in config['agents']['list']:
    agent['model']['primary'] = f'{provider_key}/{primary_model}'
    agent['model']['fallbacks'] = []

# 4. 生成 gateway auth token
config['gateway']['auth']['token'] = secrets.token_hex(24)

# 5. 修正路径
import os
home = os.path.expanduser('~')
def fix_paths(obj):
    if isinstance(obj, str):
        return obj.replace('\$HOME', home).replace('$HOME', home)
    elif isinstance(obj, dict):
        return {k: fix_paths(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [fix_paths(i) for i in obj]
    return obj
config = fix_paths(config)

with open('$OPENCLAW_DIR/openclaw.json', 'w') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
    f.write('\n')

print('✓ openclaw.json 已生成')
PYEOF

echo ""

# ---- 7. [完整安装] 复制 Cron + 脚本 + 插件 ----
if [ "$INSTALL_MODE" = "1" ]; then
    
    echo -e "${BLUE}📋 Step 7: 配置 Cron 和脚本${NC}"
    
    # 复制脚本
    cp "$SCRIPT_DIR/scripts/"*.sh "$OPENCLAW_DIR/scripts/" 2>/dev/null
    chmod +x "$OPENCLAW_DIR/scripts/"*.sh 2>/dev/null
    echo -e "  ${GREEN}✓ 运维脚本已安装${NC}"
    
    # 复制 cron 模板（delivery 留空，后续填）
    cp "$SCRIPT_DIR/cron/jobs.json.template" "$OPENCLAW_DIR/cron/jobs.json"
    echo -e "  ${GREEN}✓ Cron 任务模板已安装（delivery 待绑定微信后填入）${NC}"
    
    # 复制微信插件
    if [ -d "$SCRIPT_DIR/extensions/openclaw-weixin" ]; then
        echo -e "\n${BLUE}📱 配置微信插件${NC}"
        mkdir -p "$OPENCLAW_DIR/extensions/openclaw-weixin"
        cp -r "$SCRIPT_DIR/extensions/openclaw-weixin/"* "$OPENCLAW_DIR/extensions/openclaw-weixin/" 2>/dev/null
        
        cd "$OPENCLAW_DIR/extensions/openclaw-weixin"
        if [ -f "package.json" ]; then
            echo -e "  ${YELLOW}安装微信插件依赖...${NC}"
            npm install --production 2>/dev/null && echo -e "  ${GREEN}✓ 微信插件依赖已安装${NC}" || \
                echo -e "  ${YELLOW}⚠ npm install 失败，请手动进入插件目录执行${NC}"
        fi
        cd "$SCRIPT_DIR"
    fi
    
    echo ""
fi

# ---- 8. 启动 Gateway ----
echo -e "${BLUE}📋 Step $([ "$INSTALL_MODE" = "1" ] && echo "8" || echo "7"): 启动 Gateway${NC}"

openclaw gateway start 2>/dev/null && echo -e "  ${GREEN}✓ Gateway 已启动${NC}" || \
    echo -e "  ${YELLOW}⚠ 请手动执行: openclaw gateway start${NC}"

echo ""

# ---- 9. [完整安装] 微信绑定引导 ----
if [ "$INSTALL_MODE" = "1" ]; then
    echo -e "${BLUE}📋 Step 9: 微信绑定（可选）${NC}"
    echo ""
    echo -e "  ${CYAN}要使用微信功能，请按以下步骤操作：${NC}"
    echo ""
    echo "  1. 获取微信公众号测试号："
    echo "     访问 https://mp.weixin.qq.com/debug/cgi-bin/sandbox?t=sandbox/login"
    echo "     扫码登录，记录 appId 和 appSecret"
    echo ""
    echo "  2. 配置微信："
    echo "     openclaw configure --section channels"
    echo "     选择 openclaw-weixin，填入 appId 和 appSecret"
    echo ""
    echo "  3. 扫码关注测试号，发送消息即可开始"
    echo ""
    echo "  4. 绑定成功后，运行以下命令自动配置 Cron delivery："
    echo "     bash $SCRIPT_DIR/scripts/fill-delivery.sh"
    echo ""
fi

# ---- 完成 ----
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ OpenClaw Triple Agent 安装完成！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}三 Agent 已就位：${NC}"
echo -e "  😎 main（主助手）  → $OPENCLAW_DIR/workspace-main"
echo -e "  🌸 secretary（小秘书） → $OPENCLAW_DIR/workspace-secretary"
echo -e "  🎮 guest（体验助手）  → $OPENCLAW_DIR/workspace-guest"
echo ""
echo -e "  ${BOLD}下一步：${NC}"
echo -e "  1. 测试聊天: openclaw chat"
echo -e "  2. 配置微信: openclaw configure --section channels"
echo -e "  3. 查看文档: cat $SCRIPT_DIR/docs/architecture.md"
echo ""
