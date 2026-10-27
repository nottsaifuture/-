# My Typeless（自製版，用 Google Gemini）

講嘢 → Gemini 聽錄音、刪走「嗯、呃、即係、咁」、處理講錯改口、補標點 → 貼出嚟就用得。

```
Mac：  咪 ──► Gemini（聽 + 整理）──► 貼落游標位置
手機： iPhone 聽寫 ──► Gemini（整理）──► 剪貼簿
```

| 檔案 | 用途 |
|---|---|
| `prompt.md` | 整理規則（兩個版本共用，想改風格就改呢度） |
| `mac/typeless.lua` | Mac：Hammerspoon 腳本，揿 Fn 開始／停止 |
| `mac/install.sh` | Mac：一鍵安裝 |
| `ios/` | iPhone 鍵盤 app：撳 🌐 揀「My Typeless」，再撳「整理」（安裝見 `ios/README.md`） |
| `phone/README.md` | 唔想裝 app 嘅另一個做法：iPhone 捷徑（同 Android） |
| `test-clean.sh` | 喺 Terminal 試整理效果 |

## 需要

- 一條免費 Gemini API key：https://aistudio.google.com/apikey（唔使綁信用卡）
- Mac：Homebrew

## Mac 版

```bash
cd my-typeless/mac && ./install.sh
```

然後照住安裝完顯示嘅 3 步手動設定（Fn 鍵改「不執行任何動作」、俾 Hammerspoon 輔助使用同咪高峰權限、Reload）。

用法：喺任何輸入框揿一下 **Fn** → 選單列變 🔴 → 講嘢 → 再揿 **Fn** → ⏳ → 文字自動貼出嚟。錄緊音揿 **Esc** 取消。選單列 🎙 可以轉「口語／書面語」。

設定喺 `~/.hammerspoon/typeless.lua` 頂部：
- `model`：預設 `gemini-3.8-flash`；撞到免費額度上限可以改做 `gemini-3.5-flash-lite`
- `autoPaste = false`：淨係抄落剪貼簿，唔自動貼

## 私隱

免費額度嘅內容 Google 可能會攞嚟改進佢哋嘅產品。敏感嘢（例如密碼、病歷）就唔好用呢個講。
