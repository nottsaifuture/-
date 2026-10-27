-- My Typeless for Mac (Hammerspoon + Gemini)
-- 揿一下 Fn 開始錄音，再揿一下 Fn 停止 → Gemini 聽錄音同時整理 → 自動貼落游標位置。
-- 錄緊音嗰陣揿 Esc 可以取消。

local M = {}

local HOME = os.getenv("HOME")
local CFG_DIR = HOME .. "/.config/my-typeless"

M.config = {
  rec = "/opt/homebrew/bin/rec", -- 錄音（sox）
  model = "gemini-3.8-flash", -- 撞到免費額度上限可以改做 "gemini-3.5-flash-lite"
  style = "口語", -- "口語" = 保留廣東話；"書面語" = 轉做書面中文
  autoPaste = true, -- false 就淨係抄落剪貼簿
}

local STYLES = {
  ["口語"] = "保留講者原本用嘅語言同口吻；講廣東話就寫返廣東話口語，講英文就寫英文",
  ["書面語"] = "將廣東話口語改寫成通順嘅書面中文；講英文就寫正式英文",
}

local state = "idle" -- idle | recording | processing
local recTask, recStart
local wavPath = CFG_DIR .. "/last.wav"

local function readFile(path, binary)
  local f = io.open(path, binary and "rb" or "r")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  if binary then return s end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function writeFile(path, s)
  local f = assert(io.open(path, "w"))
  f:write(s)
  f:close()
end

-- 選單列圖示
M.menu = hs.menubar.new()
local function setStatus(s)
  state = s
  local icons = { idle = "🎙", recording = "🔴", processing = "⏳" }
  if M.menu then M.menu:setTitle(icons[s]) end
end

local function fail(msg)
  hs.alert.show("Typeless：" .. msg, 4)
  setStatus("idle")
end

local function deliver(text)
  if text == "" then return fail("聽唔到嘢") end
  hs.pasteboard.setContents(text)
  if M.config.autoPaste then
    hs.eventtap.keyStroke({ "cmd" }, "v", 0)
  else
    hs.alert.show("已抄落剪貼簿")
  end
  setStatus("idle")
end

-- 將錄音交俾 Gemini，一次過轉文字兼整理
local function process()
  local key = readFile(CFG_DIR .. "/gemini_key")
  if not key then return fail("搵唔到 " .. CFG_DIR .. "/gemini_key") end
  local prompt = readFile(CFG_DIR .. "/prompt.md")
  if not prompt then return fail("搵唔到 prompt.md") end
  prompt = prompt:gsub("{{STYLE}}", STYLES[M.config.style] or STYLES["口語"])
  local audio = readFile(wavPath, true)
  if not audio then return fail("搵唔到錄音檔") end

  local bodyPath = CFG_DIR .. "/request.json"
  writeFile(bodyPath, hs.json.encode({
    system_instruction = { parts = { { text = prompt } } },
    contents = { {
      role = "user",
      parts = {
        { text = "請整理呢段錄音。" },
        { inline_data = { mime_type = "audio/wav", data = hs.base64.encode(audio) } },
      },
    } },
  }))

  local url = "https://generativelanguage.googleapis.com/v1beta/models/"
    .. M.config.model .. ":generateContent"
  hs.task.new("/usr/bin/curl", function(code, out)
    local resp = code == 0 and hs.json.decode(out) or nil
    if not resp then return fail("Gemini 冇回應") end
    if resp.error then return fail("Gemini 出錯：" .. tostring(resp.error.message)) end
    local cand = resp.candidates and resp.candidates[1]
    if not (cand and cand.content) then return fail("Gemini 冇俾到結果") end
    local parts = {}
    for _, part in ipairs(cand.content.parts or {}) do
      if part.text and not part.thought then table.insert(parts, part.text) end
    end
    deliver((table.concat(parts):gsub("^%s+", ""):gsub("%s+$", "")))
  end, {
    "-sS", "--max-time", "90", url,
    "-H", "content-type: application/json",
    "-H", "x-goog-api-key: " .. key,
    "--data-binary", "@" .. bodyPath,
  }):start()
end

-- 錄音
local escKey
local function startRecording()
  hs.fs.mkdir(CFG_DIR)
  os.remove(wavPath)
  recTask = hs.task.new(M.config.rec, function()
    if state ~= "processing" then return end -- 已取消
    if hs.timer.secondsSinceEpoch() - recStart < 0.6 then return setStatus("idle") end
    process()
  end, { "-q", "-c", "1", "-r", "16000", "-b", "16", wavPath })
  if not recTask:start() then return fail("開唔到 sox，有冇裝 sox？") end
  recStart = hs.timer.secondsSinceEpoch()
  setStatus("recording")
  escKey:enable()
end

local function stopRecording(cancel)
  escKey:disable()
  setStatus(cancel and "idle" or "processing")
  if recTask and recTask:isRunning() then recTask:interrupt() end
end

escKey = hs.hotkey.new({}, "escape", function() stopRecording(true) end)

function M.toggle()
  if state == "idle" then
    startRecording()
  elseif state == "recording" then
    stopRecording(false)
  end -- processing 中就唔理
end

-- Fn 鍵：單獨揿落再放開先算（Fn + 其他鍵唔觸發）
local FN_KEYCODE = 63
local fnDown, fnAlone = false, false
local types = hs.eventtap.event.types
M.fnTap = hs.eventtap.new({ types.flagsChanged, types.keyDown }, function(e)
  if e:getType() == types.keyDown or e:getKeyCode() ~= FN_KEYCODE then
    if fnDown then fnAlone = false end
    return false
  end
  local isDown = e:getFlags().fn == true
  if isDown and not fnDown then
    fnDown, fnAlone = true, true
  elseif not isDown and fnDown then
    fnDown = false
    if fnAlone then hs.timer.doAfter(0, M.toggle) end
  end
  return false
end)
M.fnTap:start()

-- macOS 有時會自動停咗 eventtap，定時檢查一下
M.watchdog = hs.timer.doEvery(5, function()
  if not M.fnTap:isEnabled() then M.fnTap:start() end
end)

local function buildMenu()
  return {
    { title = "開始／停止錄音 (Fn)", fn = M.toggle },
    { title = "-" },
    { title = "風格：口語", checked = M.config.style == "口語", fn = function() M.config.style = "口語" end },
    { title = "風格：書面語", checked = M.config.style == "書面語", fn = function() M.config.style = "書面語" end },
    { title = "-" },
    { title = "重新載入", fn = hs.reload },
  }
end
if M.menu then M.menu:setMenu(buildMenu) end
setStatus("idle")

return M
