# My Typeless（自製版）

講嘢 → 轉文字 → Claude 刪走「嗯、呃、即係、咁」、處理講錯改口、補標點 → 貼出嚟就用得。

```
咪 ──► 語音轉文字 ──► Claude 整理 ──► 貼落游標位置
       (whisper)      (prompt.md)
```

| 檔案 | 用途 |
|---|---|
| `prompt.md` | 整理規則（兩個版本共用，想改風格就改呢度） |
| `mac/typeless.lua` | Mac：Hammerspoon 腳本，揿 Fn 開始／停止 |
| `mac/install.sh` | Mac：一鍵安裝 |
| `phone/README.md` | iPhone 捷徑（同 Android）設定步驟 |
| `test-clean.sh` | 喺 Terminal 試整理效果 |

## Mac 版

```bash
cd my-typeless/mac && ./install.sh
```

然後照住安裝完顯示嘅 3 步手動設定（Fn 鍵改「不執行任何動作」、俾 Hammerspoon 輔助使用同咪高峰權限、Reload）。

用法：喺任何輸入框揿一下 **Fn** → 選單列變 🔴 → 講嘢 → 再揿 **Fn** → ⏳ → 文字自動貼出嚟。錄緊音揿 **Esc** 取消。選單列 🎙 可以轉「口語／書面語」。

設定喺 `~/.hammerspoon/typeless.lua` 頂部：

- `stt = "cloud"`：改用 Groq 雲端轉文字（快好多，有免費額度），將 Groq key 放入 `~/.config/my-typeless/stt_key`
- `language = "yue"`：淨係講廣東話嘅話轉得準啲
- `claudeModel = "claude-haiku-5-5"`：整理快啲、平好多

## 需要

- Anthropic API key（https://console.anthropic.com）
- Mac：Homebrew；本機轉文字模型約 1.6GB
