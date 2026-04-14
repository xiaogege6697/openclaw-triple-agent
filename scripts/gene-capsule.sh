#!/bin/bash
set -e
CAPSULE_DIR="$HOME/.openclaw/workspace/gene-capsule"
OUTPUT="$HOME/.openclaw/gene-capsule-$(date +%Y%m%d).tar.gz"
find $HOME/.openclaw -name "gene-capsule-*.tar.gz" -mtime +7 -delete 2>/dev/null
cp $HOME/.openclaw/workspace/SOUL.md "$CAPSULE_DIR/main/" 2>/dev/null
cp $HOME/.openclaw/workspace/AGENTS.md "$CAPSULE_DIR/main/" 2>/dev/null
cp $HOME/.openclaw/workspace/MEMORY.md "$CAPSULE_DIR/main/" 2>/dev/null
cp $HOME/.openclaw/workspace/USER.md "$CAPSULE_DIR/main/" 2>/dev/null
cp $HOME/.openclaw/workspace/IDENTITY.md "$CAPSULE_DIR/main/" 2>/dev/null
cp $HOME/.openclaw/workspace/TOOLS.md "$CAPSULE_DIR/main/" 2>/dev/null
cp $HOME/.openclaw/workspace/HEARTBEAT.md "$CAPSULE_DIR/main/" 2>/dev/null
cp $HOME/.openclaw/workspace/memory/*.md "$CAPSULE_DIR/main/memory/" 2>/dev/null
cp $HOME/.openclaw/workspace-secretary/SOUL.md "$CAPSULE_DIR/secretary/" 2>/dev/null
cp $HOME/.openclaw/workspace-secretary/AGENTS.md "$CAPSULE_DIR/secretary/" 2>/dev/null
cp $HOME/.openclaw/workspace-secretary/MEMORY.md "$CAPSULE_DIR/secretary/" 2>/dev/null
cp $HOME/.openclaw/workspace-secretary/IDENTITY.md "$CAPSULE_DIR/secretary/" 2>/dev/null
cp $HOME/.openclaw/workspace-secretary/memory/*.md "$CAPSULE_DIR/secretary/memory/" 2>/dev/null
cp $HOME/.openclaw/openclaw.json "$CAPSULE_DIR/" 2>/dev/null
sed -i '' "s/生成时间：.*/生成时间：$(date '+%Y-%m-%d %H:%M')/g" "$CAPSULE_DIR/README.md"
cd "$CAPSULE_DIR" && tar -czf "$OUTPUT" .
echo "Gene capsule updated: $OUTPUT ($(du -sh "$OUTPUT" | cut -f1))"
