#!/bin/bash
# 喺 Terminal 試吓整理效果：./test-clean.sh "嗯即係呢個呢我聽日呃唔係後日先返嚟"
# 第二個參數可以係 口語（預設）或 書面語
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
KEY="${GEMINI_API_KEY:-$(cat "$HOME/.config/my-typeless/gemini_key")}"
MODEL="${GEMINI_MODEL:-gemini-3.8-flash}"
if [ "${2:-口語}" = "書面語" ]; then
  STYLE="將廣東話口語改寫成通順嘅書面中文；講英文就寫正式英文"
else
  STYLE="保留講者原本用嘅語言同口吻；講廣東話就寫返廣東話口語，講英文就寫英文"
fi
SYSTEM="$(sed "s/{{STYLE}}/$STYLE/" "$HERE/prompt.md")"

jq -n --arg sys "$SYSTEM" --arg text "$1" '{
  system_instruction: {parts: [{text: $sys}]},
  contents: [{role: "user", parts: [{text: ("<transcript>\n" + $text + "\n</transcript>")}]}]
}' | curl -sS "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent" \
  -H "content-type: application/json" \
  -H "x-goog-api-key: $KEY" \
  --data-binary @- | jq -r 'if .error then "錯誤：" + .error.message else ([.candidates[0].content.parts[] | select(.thought != true) | .text] | join("")) end'
