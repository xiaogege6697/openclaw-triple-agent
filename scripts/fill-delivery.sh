#!/bin/bash
# ============================================================
# 自动填入 Cron delivery 配置（微信绑定后运行）
# 从 openclaw-weixin 的 accounts 中读取 accountId，
# 从 sessions 中读取 chat_id，自动填入 cron/jobs.json
# ============================================================
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

OPENCLAW_DIR="$HOME/.openclaw"
WX_STATE="$OPENCLAW_DIR/openclaw-weixin"
CRON_FILE="$OPENCLAW_DIR/cron/jobs.json"

echo -e "${CYAN}🔄 自动配置 Cron delivery...${NC}"

# 检查微信账户
if [ ! -d "$WX_STATE/accounts" ]; then
    echo -e "${YELLOW}⚠ 未找到微信账户，请先绑定微信${NC}"
    exit 1
fi

# 读取账户列表
ACCOUNTS=$(ls "$WX_STATE/accounts"/*.json 2>/dev/null | grep -v sync | grep -v context-tokens)
if [ -z "$ACCOUNTS" ]; then
    echo -e "${YELLOW}⚠ 未找到微信账户文件${NC}"
    exit 1
fi

echo -e "\n找到以下微信账户："
ACCOUNT_LIST=()
i=1
for f in $ACCOUNTS; do
    name=$(basename "$f" .json)
    ACCOUNT_LIST+=("$name")
    echo "  $i) $name"
    i=$((i+1))
done

if [ ${#ACCOUNT_LIST[@]} -eq 1 ]; then
    # 只有一个账户，直接用
    MAIN_ACCOUNT="${ACCOUNT_LIST[0]}"
    echo -e "\n${GREEN}✓ 自动选择唯一账户: $MAIN_ACCOUNT${NC}"
else
    # 多个账户，让用户选
    echo ""
    read -p "选择主账户（大号bot）编号: " MAIN_IDX
    MAIN_ACCOUNT="${ACCOUNT_LIST[$((MAIN_IDX-1))]}"
    
    if [ ${#ACCOUNT_LIST[@]} -ge 2 ]; then
        read -p "选择小秘书账户编号（没有则回车跳过）: " SEC_IDX
        SEC_ACCOUNT="${ACCOUNT_LIST[$((SEC_IDX-1))]}" 2>/dev/null || ""
    fi
fi

echo -e "\n主账户: $MAIN_ACCOUNT"
[ -n "$SEC_ACCOUNT" ] && echo "秘书账户: $SEC_ACCOUNT"

# 从 sessions 获取 chat_id
echo -e "\n${YELLOW}请用微信发一条消息给 bot，按回车继续...${NC}"
read

# 从最近 session 中提取 chat_id
CHAT_ID=$(python3 << PYEOF
import json, os, glob

# 从 sessions.json 中找最新的微信 chat_id
for agent in ['main', 'secretary']:
    sess_file = os.path.expanduser(f'~/.openclaw/agents/{agent}/sessions/sessions.json')
    if os.path.exists(sess_file):
        try:
            with open(sess_file) as f:
                sessions = json.load(f)
            for s in reversed(sessions):
                if 'weixin' in s.get('channel', '') or 'wechat' in s.get('channel', ''):
                    cid = s.get('chatId', '')
                    if '@im.wechat' in cid:
                        print(cid)
                        exit(0)
        except:
            pass
PYEOF
)

if [ -z "$CHAT_ID" ]; then
    echo -e "${YELLOW}⚠ 未自动获取到 chat_id，请手动输入: ${NC}"
    read -p "chat_id (格式: xxx@im.wechat): " CHAT_ID
fi

echo -e "${GREEN}✓ chat_id: $CHAT_ID${NC}"

# 填入 cron/jobs.json
python3 << PYEOF
import json

cron_file = '$CRON_FILE'
main_account = '$MAIN_ACCOUNT'
sec_account = '$SEC_ACCOUNT'
chat_id = '$CHAT_ID'

with open(cron_file, 'r') as f:
    data = json.load(f)

for j in data['jobs']:
    if 'delivery' not in j:
        continue
    d = j['delivery']
    
    # 根据 agentId 决定用哪个 account
    agent_id = j.get('agentId', 'main')
    if 'secretary' in j.get('name', '') or agent_id == 'secretary':
        if sec_account:
            d['accountId'] = sec_account
        else:
            d['accountId'] = main_account
    else:
        d['accountId'] = main_account
    
    # 统一填入 chat_id
    if d.get('mode') == 'announce':
        d['to'] = chat_id

with open(cron_file, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')

print(f'✓ 已更新 {len(data["jobs"])} 个 cron 任务的 delivery 配置')
PYEOF

echo ""
echo -e "${GREEN}✅ Cron delivery 配置完成！${NC}"
echo -e "  重启 Gateway 生效: openclaw gateway restart"
