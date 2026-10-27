#!/bin/bash
# My Typeless for Mac：一次過安裝
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CFG="$HOME/.config/my-typeless"

command -v brew >/dev/null || { echo "請先裝 Homebrew：https://brew.sh"; exit 1; }

echo "▶ 安裝 Hammerspoon、sox、jq"
brew install --cask hammerspoon
brew install sox jq

mkdir -p "$CFG" "$HOME/.hammerspoon"
cp "$HERE/../prompt.md" "$CFG/prompt.md"
cp "$HERE/typeless.lua" "$HOME/.hammerspoon/typeless.lua"

INIT="$HOME/.hammerspoon/init.lua"
touch "$INIT"
grep -q 'require("typeless")' "$INIT" || echo 'typeless = require("typeless")' >> "$INIT"

if [ ! -f "$CFG/gemini_key" ]; then
  echo "▶ 去 https://aistudio.google.com/apikey 揿「Create API key」"
  read -r -s -p "  將條 key 貼喺度，然後揿 Enter：" KEY; echo
  printf '%s' "$KEY" > "$CFG/gemini_key"
  chmod 600 "$CFG/gemini_key"
fi

open -a Hammerspoon
cat <<'EOF'

✅ 裝好。仲有 3 步要手動做：
1. 系統設定 → 鍵盤 →「按 🌐 鍵時」揀「不執行任何動作」
2. 系統設定 → 私隱與安全性 →「輔助使用」同「咪高峰」都剔 Hammerspoon
3. Hammerspoon 選單列圖示 → Reload Config

之後喺任何輸入框：揿 Fn 講嘢，再揿 Fn 完成（Esc 取消）。
EOF
