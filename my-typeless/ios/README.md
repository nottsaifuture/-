# iPhone 鍵盤版（My Typeless 鍵盤）

裝完之後，撳 🌐 會見到「My Typeless」。撳中間個「整理」掣，輸入框入面啲字就會即刻變成整理好嘅版本。

```
平時鍵盤打字／講嘢 ──► 🌐 轉做 My Typeless ──► 撳「整理」──► Gemini ──► 取代輸入框啲字
```

## 你需要
- 一部 Mac，喺 App Store 裝 **Xcode**（免費）
- 一條 USB 線駁 iPhone
- Gemini API key（https://aistudio.google.com/apikey）

## 安裝步驟（第一次大約 15 分鐘）

1. **裝 XcodeGen**
   ```bash
   brew install xcodegen
   ```
2. **放入 API key**
   ```bash
   cd my-typeless/ios
   cp Secrets.example.swift Keyboard/Secrets.swift
   open -e Keyboard/Secrets.swift   # 將引號入面換做你條 key，儲存
   ```
3. **改 Bundle ID**：打開 `project.yml`，將 `com.yourname.mytypeless` 改做你自己嘅名，例如 `com.wilson.mytypeless`
4. **生成專案並打開**
   ```bash
   xcodegen && open MyTypeless.xcodeproj
   ```
5. **登入 Apple ID**：Xcode → Settings → Accounts → ＋ → Apple ID
6. **簽名**：左邊撳藍色 MyTypeless 專案 → 揀 `MyTypeless` target → Signing & Capabilities → Team 揀你個名（Personal Team）。再揀 `Keyboard` target，做多一次
7. **iPhone 開發者模式**：駁好 iPhone → iPhone 設定 → 私隱與安全性 → 開發者模式 → 開，然後重新開機
8. **裝落部電話**：Xcode 頂部揀你部 iPhone → 撳 ▶（⌘R）
9. **信任開發者**：iPhone 設定 → 一般 → VPN 與裝置管理 → 撳你個 Apple ID → 信任
10. **開鍵盤**：打開 My Typeless app → 撳「打開設定」→ 鍵盤 → 開「My Typeless」同「允許完整取用」

## 用法
- 用平時嘅鍵盤打字，或者用 iPhone 鍵盤個咪講完 → 撳 🌐 轉做 My Typeless → 撳 **整理**
- 文字好長：先全選再撳「整理」（有啲 app 只會俾鍵盤睇到游標附近嘅字）
- 唔啱心水：撳 **↶** 還原
- 右上角可以轉 **口語／書面語**

## 注意
- **免費 Apple ID 裝嘅 app 7 日後就會開唔到**，到時駁返 Mac 再撳一次 ▶ 就得。唔想咁麻煩就要開 Apple Developer 帳戶（每年 US$99）
- 喺輸入密碼嘅地方，iOS 會自動轉返系統鍵盤，呢個係正常
- 想改整理規則，就改 `my-typeless/prompt.md`，然後重新撳 ▶
