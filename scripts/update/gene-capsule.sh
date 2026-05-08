#!/bin/bash
# 🧬 Gene Capsule — 每日基因备份
# 更新于 2026-04-15：路径迁移到 workspace-main
set -e

CAPSULE_DIR="/Users/xiaogege/.openclaw/workspace-main/gene-capsule"
OUTPUT="/Users/xiaogege/.openclaw/gene-capsule-$(date +%Y%m%d).tar.gz"

# 清理旧胶囊（保留7天）
find /Users/xiaogege/.openclaw -name "gene-capsule-*.tar.gz" -mtime +7 -delete 2>/dev/null || true

# 重建胶囊目录
mkdir -p "$CAPSULE_DIR/main/memory"
mkdir -p "$CAPSULE_DIR/secretary/memory"

# main（从 workspace-main 复制）
for f in SOUL.md AGENTS.md MEMORY.md USER.md IDENTITY.md TOOLS.md HEARTBEAT.md; do
    cp "/Users/xiaogege/.openclaw/workspace-main/$f" "$CAPSULE_DIR/main/" 2>/dev/null || true
done
cp /Users/xiaogege/.openclaw/workspace-main/memory/*.md "$CAPSULE_DIR/main/memory/" 2>/dev/null || true
cp -r /Users/xiaogege/.openclaw/workspace-main/memory/projects "$CAPSULE_DIR/main/memory/" 2>/dev/null || true
cp -r /Users/xiaogege/.openclaw/workspace-main/memory/ideas "$CAPSULE_DIR/main/memory/" 2>/dev/null || true

# secretary
for f in SOUL.md AGENTS.md MEMORY.md IDENTITY.md USER.md TOOLS.md HEARTBEAT.md; do
    cp "/Users/xiaogege/.openclaw/workspace-secretary/$f" "$CAPSULE_DIR/secretary/" 2>/dev/null || true
done
cp /Users/xiaogege/.openclaw/workspace-secretary/memory/*.md "$CAPSULE_DIR/secretary/memory/" 2>/dev/null || true

# config
cp /Users/xiaogege/.openclaw/openclaw.json "$CAPSULE_DIR/" 2>/dev/null || true

# 更新 README
if [ -f "$CAPSULE_DIR/README.md" ]; then
    sed -i '' "s/生成时间：.*/生成时间：$(date '+%Y-%m-%d %H:%M')/g" "$CAPSULE_DIR/README.md" 2>/dev/null || true
fi

# 打包
cd "$CAPSULE_DIR" && tar -czf "$OUTPUT" .

echo "🧬 Gene capsule updated: $OUTPUT ($(du -sh "$OUTPUT" | cut -f1))"
