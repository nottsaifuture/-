---
name: animated-text-64
description: 字會動 64 式 — 64 Chinese/CJK kinetic-typography text animations (entrance, flow, swap, emphasis, 3D/space, lyric-MV, variety-show captions, horror) with exact timing specs, a working reference implementation, and an MP4/green-screen export script. Use whenever the user wants moving/animated text, a title or intro animation, lyric video text, 字卡, 綜藝字幕, 片頭字, 動態文字, kinetic type, a looping text animation as HTML, or a green-screen/MP4 text clip — even if they only describe the look ("字彈出來", "像霓虹燈閃", "恐怖片抖動字幕").
---

# 字會動 64 式 · Animated Text

A catalog of 64 kinetic-type motions, each with a precise spec (seconds, angles, scale) and a
live, dependency-free implementation. Source: pound0423/claude-animated-text (MIT, see
`assets/LICENSE`) — live demo https://pound0423.github.io/claude-animated-text/.

## Files

- `references/catalog.md` — all 64 effects: look, use case, default scheme/words/length, and the full
  ready-to-use prompt (with the exact motion spec). **Read the entries you need; don't load it all unless choosing.**
- `assets/index.html` — the original specimen page. Every effect is a `make(root, words)` function in the
  `FX` array (search `{id:'<id>'`); motion text is in `PROMPT.<id>.m`; palettes in `const SCH`.
  Opening it in a browser gives the full interactive gallery (type your words, zoom, ratio, colours).
- `scripts/make_player.py` — turns one effect into a standalone looping HTML page.
- `scripts/render.py` — frame-exact MP4 export via headless Chrome + ffmpeg.

## Workflow

1. **Pick the effect.** Map the user's intent to the quick index below (by group and 適合 use case).
   If ambiguous, offer 2–3 candidates with their one-line look from `references/catalog.md`.
2. **Collect inputs:** words (split on spaces; ≤8 words, ≤14 chars each), ratio (16:9 / 9:16 / 1:1),
   colour scheme, and output type. Default to the effect's sample words/scheme if not given.
3. **Produce the output** — choose the cheapest path that meets the need:
   - **Exact original look, fast:** `python scripts/make_player.py <id> --words "詞一 詞二" --scheme key --out <file>.html`
     (single looping HTML; ratio follows the window size).
   - **Video file / green screen:** `python scripts/render.py <id> [<id>…] --words "…" --scheme key --size 1080x1920 --seconds 4 --out out/`
     (needs Python Playwright, Chromium, ffmpeg with libx264; `--list` shows ids and lengths;
     `--chrome /opt/pw-browsers/chromium` or similar if auto-detect fails).
   - **Custom / standalone code** (user wants clean code to modify, embed in their app, React, CSS-only, etc.):
     write it fresh from the catalog's prompt for that effect, substituting words/ratio/colours. Follow
     every timing in the 動態 line literally, loop seamlessly, scale text with the viewport
     (e.g. `cqmin`/`vmin` + width-fit so it never overflows), and show only the animation.
     Consult the effect's `make()` in `assets/index.html` when a detail is unclear.
   - **Just the prompt** (user will paste it into another AI): output the catalog prompt with their
     words/ratio/scheme filled in.
4. Verify visually when possible (screenshot a few timestamps with Playwright) before handing over.

## Prompt template

Every catalog prompt follows this shape; fill the bracketed parts:

```text
【<no> <名稱>】
用單一 HTML 檔（純 CSS + JavaScript，不用外部套件）做一個可以無縫循環播放的文字動畫。
畫面：比例 <16:9|9:16|1:1>，背景 <bg>，主文字 <fg>，強調色 <accent>。
字體：最粗的黑體（Noto Sans TC 900）   ← or 粗明體（Noto Serif TC 900） for serif effects
文字：「詞一」「詞二」…                  ← some effects say 句子／上下句 etc.; keep the catalog's wording
動態：<motion spec from catalog>
其他：文字大小跟著畫面縮放，不要超出畫面；只要這一個動畫，不要其他介面或說明文字。
```

Colour schemes (bg / main text / accent):

| scheme | 名 | bg | text | accent |
|---|---|---|---|---|
| `ink` | 墨黑 | #14161b | #f4f5f7 | #ff4d2e |
| `paper` | 紙白 | #f4f5f7 | #14161b | #2340ff |
| `cobalt` | 鈷藍 | #2340ff | #ffffff | #14161b |
| `verm` | 朱紅 | #ff4d2e | #14161b | #f4f5f7 |
| `key` | 綠幕 (chroma key) | #00b140 | #ffffff | #14161b |

Speed changes: scale the seconds in the 動態 line proportionally. Translate the prompt to English if
the user works in English — keep all numbers.

## Quick index

**Entrance 登場**

| # | id | 名稱 | English | 適合 | 預設底色 |
|---|---|---|---|---|---|
| 01 | `burst` | 爆出 | Burst | 片頭、標題 | ink |
| 02 | `hit` | 逐字重擊 | Hit by hit | 口號、倒數 | verm |
| 03 | `stamp` | 蓋章 | Stamp | 公告、認證 | paper |
| 04 | `punch` | 衝向鏡頭 | Punch in | 重點強調 | ink |
| 05 | `stack` | 左右疊字 | Side stack | 歌詞、預告 | cobalt |
| 06 | `stretch` | 拉長 | Stretch | 搞笑、驚訝 | verm |
| 07 | `through` | 穿過去 | Fly through | 轉場 | paper |
| 08 | `squash` | 落地回彈 | Drop and squash | 可愛、活潑 | ink |

**Flow 流動**

| # | id | 名稱 | English | 適合 | 預設底色 |
|---|---|---|---|---|---|
| 09 | `crawl` | 巨字橫移 | Giant crawl | 背景、片頭 | ink |
| 10 | `drift` | 直排對流 | Column drift | 東方氛圍 | cobalt |
| 11 | `echo` | 重複波浪 | Echo wave | 背景、節奏 | paper |
| 12 | `slant` | 斜帶 | Slant bands | 預告、促銷 | ink |
| 13 | `path` | 彎道 | Path ribbon | 歌詞、過場 | verm |
| 14 | `ticker` | 多層跑馬燈 | Ticker stack | 資訊、促銷 | cobalt |
| 15 | `depth` | 遠近直書 | Depth columns | 文藝、片尾 | paper |
| 16 | `tape` | 交叉封條 | Crossed tape | 警示、限定 | ink |

**Swap 切換**

| # | id | 名稱 | English | 適合 | 預設底色 |
|---|---|---|---|---|---|
| 17 | `flap` | 翻牌看板 | Split flap | 時間、地點 | ink |
| 18 | `flip` | 翻卡 | Card flip | 分段標題 | cobalt |
| 19 | `type` | 打字機 | Typewriter | 旁白、字幕 | paper |
| 20 | `slot` | 拉霸 | Slot reel | 抽獎、揭曉 | verm |
| 21 | `odo` | 跳錶 | Odometer | 數據、成績 | paper |
| 22 | `swapline` | 標題輪替 | Headline swap | 快訊、清單 | ink |
| 23 | `led` | 點陣看板 | Dot matrix | 復古、車站 | ink |
| 24 | `split` | 上下裂開 | Split reveal | 轉場、反轉 | cobalt |

**Emphasis 強調**

| # | id | 名稱 | English | 適合 | 預設底色 |
|---|---|---|---|---|---|
| 25 | `glitch` | 訊號故障 | Glitch | 科技、懸疑 | ink |
| 26 | `marker` | 螢光筆 | Highlighter | 重點、教學 | verm |
| 27 | `shake` | 抖動 | Shake | 憤怒、驚嚇 | paper |
| 28 | `neon` | 霓虹燈管 | Neon flicker | 夜晚、招牌 | ink |
| 29 | `bob` | 波浪起伏 | Wave bob | 輕鬆、音樂 | cobalt |
| 30 | `track` | 字距拉開 | Tracking out | 片名、章節 | paper |
| 31 | `fill` | 空心填滿 | Outline fill | 進度、蓄力 | verm |
| 32 | `focus` | 對焦 | Focus pull | 回憶、揭曉 | ink |

**Space/3D 空間**

| # | id | 名稱 | English | 適合 | 預設底色 |
|---|---|---|---|---|---|
| 33 | `cube` | 四角柱翻面 | Prism roll | 輪播、清單 | cobalt |
| 34 | `crawl3d` | 透視字幕 | Perspective crawl | 開場旁白 | ink |
| 35 | `orbit` | 環繞 | Orbit ring | 標誌、循環 | paper |
| 36 | `tunnel` | 隧道 | Tunnel | 穿越、加速 | verm |
| 37 | `scatter` | 散開聚合 | Scatter assemble | 解謎、片名 | ink |
| 38 | `extrude` | 厚度陰影 | Extrude | 標題、海報感 | cobalt |
| 39 | `blinds` | 橫條拼字 | Slice in | 轉場、頻道感 | paper |
| 40 | `block` | 色塊揭開 | Block reveal | 人名條、標題 | ink |

**Lyrics MV 歌詞**

| # | id | 名稱 | English | 適合 | 預設底色 |
|---|---|---|---|---|---|
| 41 | `kara` | 跟唱填色 | Karaoke fill | 歌詞、跟唱 | ink |
| 42 | `popsync` | 逐字踩拍 | Beat by beat | 副歌、口號 | cobalt |
| 43 | `dual` | 上下兩行 | Two-line karaoke | KTV、對唱 | paper |
| 44 | `beat` | 重拍反白 | Beat flash | 快歌、前奏 | verm |
| 45 | `soft` | 柔焦浮現 | Soft rise | 抒情、獨白 | verm |
| 46 | `lyrics` | 歌詞捲動 | Lyric scroll | 整首歌詞 | ink |
| 47 | `trail` | 重拍殘影 | Echo trail | 電音、舞曲 | cobalt |
| 48 | `mix` | 大小混排 | Type block | 歌詞重點、片頭 | paper |

**Variety captions 綜藝字卡**

| # | id | 名稱 | English | 適合 | 預設底色 |
|---|---|---|---|---|---|
| 49 | `vpop` | 彈出字卡 | Pop caption | 反應、吐槽 | verm |
| 50 | `slam` | 斜砸下來 | Diagonal slam | 否定、打臉 | ink |
| 51 | `lines` | 集中線 | Speed lines | 震驚、重點 | paper |
| 52 | `marks` | 問號驚嘆號 | Reaction marks | 疑惑、傻眼 | cobalt |
| 53 | `telop` | 字卡條 | Telop bar | 單元名稱、說明 | ink |
| 54 | `emph` | 關鍵字放大 | Keyword zoom | 笑點、轉折 | verm |
| 55 | `bouncy` | 逐字蹦跳 | Bouncy letters | 歡樂、慶祝 | cobalt |
| 56 | `star` | 爆炸框 | Starburst | 獨家、特價 | paper |

**Horror 恐怖片**

| # | id | 名稱 | English | 適合 | 預設底色 |
|---|---|---|---|---|---|
| 57 | `flick` | 燈泡將熄 | Dying bulb | 懸疑開場 | ink |
| 58 | `drip` | 往下滴 | Drip | 片名、警告 | paper |
| 59 | `creep` | 慢慢逼近 | Slow creep | 驚嚇、倒數 | ink |
| 60 | `ghost` | 重影抽搐 | Double vision | 不安、幻覺 | paper |
| 61 | `corrupt` | 字被換掉 | Corrupt | 反轉、附身 | ink |
| 62 | `mirror` | 鏡中倒影 | Mirror | 雙重人格、鏡子 | paper |
| 63 | `torch` | 手電筒 | Flashlight | 探索、密室 | ink |
| 64 | `melt` | 融化拉長 | Melt | 崩壞、夢境 | verm |
