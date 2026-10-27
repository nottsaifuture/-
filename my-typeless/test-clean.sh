#!/bin/bash
# 喺 Terminal 試吓整理效果：./test-clean.sh "嗯即係呢個呢我聽日呃唔係後日先返嚟"
# 第二個參數可以係 口語（預設）或 書面語
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
KEY="${ANTHROPIC_API_KEY:-$(cat "$HOME/.config/my-typeless/anthropic_key")}"
if [ "${2:-口語}" = "書面語" ]; then
  STYLE="將廣東話口語改寫成通順嘅書面中文；講英文就寫正式英文"
else
  STYLE="保留講者原本用嘅語言同口吻；講廣東話就寫返廣東話口語（例如「係」「唔」「嘅」），講英文就寫英文"
fi
SYSTEM="$(sed "s/{{STYLE}}/$STYLE/" "$HERE/prompt.md")"

jq -n --arg sys "$SYSTEM" --arg text "$1" '{
  model: "claude-opus-5-5", max_tokens: 8000,
  output_config: {effort: "low"}, fallbacks: "default",
  system: $sys,
  messages: [{role: "user", content: ("<transcript>\n" + $text + "\n</transcript>")}]
}' | curl -sS https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: $KEY" \
  -H "anthropic-version: 2026-10-21" \
  -H "anthropic-beta: server-side-fallback-2026-07-01" \
  --data-binary @- | jq -r 'if .type == "error" then "錯誤：" + .error.message else ([.content[] | select(.type == "text") | .text] | join("")) end'
