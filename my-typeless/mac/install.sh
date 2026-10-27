#!/bin/bash
# My Typeless for Mac：一次過安裝
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CFG="$HOME/.config/my-typeless"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin"

command -v brew >/dev/null || { echo "請先裝 Homebrew：https://brew.sh"; exit 1; }

echo "▶ 安裝 Hammerspoon、sox、whisper.cpp、jq"
brew install --cask hammerspoon
brew install sox whisper-cpp jq

mkdir -p "$CFG" "$HOME/.hammerspoon"
cp "$HERE/../prompt.md" "$CFG/prompt.md"
cp "$HERE/typeless.lua" "$HOME/.hammerspoon/typeless.lua"

INIT="$HOME/.hammerspoon/init.lua"
touch "$INIT"
grep -q 'require("typeless")' "$INIT" || echo 'typeless = require("typeless")' >> "$INIT"

if [ ! -f "$CFG/ggml-large-v3-turbo.bin" ]; then
  echo "▶ 下載語音模型（約 1.6GB，第一次先要）"
  curl -L --fail -o "$CFG/ggml-large-v3-turbo.bin" "$MODEL_URL"
fi

if [ ! -f "$CFG/anthropic_key" ]; then
  read -r -s -p "▶ 貼上你嘅 Anthropic API key（sk-ant-...），然後揿 Enter：" KEY; echo
  printf '%s' "$KEY" > "$CFG/anthropic_key"
  chmod 600 "$CFG/anthropic_key"
fi

open -a Hammerspoon
cat <<'EOF'

✅ 裝好。仲有 3 步要手動做：
1. 系統設定 → 鍵盤 →「按 🌐 鍵時」揀「不執行任何動作」
2. 系統設定 → 私隱與安全性 →「輔助使用」同「咪高峰」都剔 Hammerspoon
3. Hammerspoon 選單列圖示 → Reload Config

之後喺任何輸入框：揿 Fn 講嘢，再揿 Fn 完成（Esc 取消）。
EOF
