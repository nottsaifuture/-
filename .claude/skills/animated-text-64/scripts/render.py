#!/usr/bin/env python3
"""把 index.html 裡的文字動態逐格輸出成 MP4。

做法：用無頭 Chrome 開啟 index.html，呼叫頁面提供的 window.__tm 介面
把指定的動態鋪滿整個視窗，再一格一格指定時間、截圖，交給 ffmpeg 編碼。
因為每一格都是「指定時間 → 截圖」，輸出不受電腦快慢影響，不會掉格。

需要：Python 3.9+、playwright（pip install playwright）、Chrome 或 Chromium、ffmpeg。
"""
import argparse
import asyncio
import base64
import json
import os
import pathlib
import shutil
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
GROUP_DIRS = {
    "in": "1_登場", "flow": "2_流動", "swap": "3_切換", "em": "4_強調",
    "sp": "5_空間", "mv": "6_歌詞MV", "tv": "7_綜藝字卡", "hr": "8_恐怖片",
}
SCHEMES = ["ink", "paper", "cobalt", "verm", "key"]


def find_chrome(explicit):
    if explicit:
        return explicit
    for name in ("google-chrome", "google-chrome-stable", "chromium", "chromium-browser"):
        path = shutil.which(name)
        if path:
            return path
    return None  # 交給 playwright 自己安裝的 Chromium


def parse_args():
    ap = argparse.ArgumentParser(description="把文字動態輸出成 MP4")
    ap.add_argument("ids", nargs="*", help="要輸出的動態 id（用 --list 查）；不給就輸出全部")
    ap.add_argument("--list", action="store_true", help="列出所有動態的編號、id、名稱、預設秒數後結束")
    ap.add_argument("--out", default=os.path.join(HERE, "mp4"), help="輸出資料夾（預設 ./mp4）")
    ap.add_argument("--size", default="1920x1080", help="畫面大小 寬x高（預設 1920x1080；直式用 1080x1920）")
    ap.add_argument("--fps", type=int, default=30, help="每秒格數（預設 30）")
    ap.add_argument("--seconds", type=float, default=None, help="每支影片的長度；不給就用各動態預設的一輪長度")
    ap.add_argument("--scheme", choices=SCHEMES, default=None, help="底色：ink 墨黑、paper 紙白、cobalt 鈷藍、verm 朱紅、key 綠幕；不給就用各動態預設")
    ap.add_argument("--words", default=None, help='自訂文字，用空格分開多個詞，例如 --words "今晚八點 首播"')
    ap.add_argument("--crf", type=int, default=20, help="x264 畫質，數字越小越清楚、檔案越大（預設 20）")
    ap.add_argument("--chrome", default=None, help="Chrome/Chromium 執行檔路徑；不給會自動找")
    ap.add_argument("--page", default=os.path.join(HERE, "..", "assets", "index.html"), help="index.html 的路徑")
    return ap.parse_args()


async def run(a):
    from playwright.async_api import async_playwright

    try:
        w, h = (int(x) for x in a.size.lower().split("x"))
    except ValueError:
        sys.exit("--size 的格式是 寬x高，例如 1920x1080")
    if w % 2 or h % 2:
        sys.exit("--size 的寬和高都要是偶數（H.264 的限制）")
    if not a.list and not shutil.which("ffmpeg"):
        sys.exit("找不到 ffmpeg，請先安裝")
    words = a.words.split() if a.words else None

    async with async_playwright() as p:
        chrome = find_chrome(a.chrome)
        launch = {"args": ["--no-sandbox", "--force-color-profile=srgb"]}
        if chrome:
            launch["executable_path"] = chrome
        browser = await p.chromium.launch(**launch)
        page = await browser.new_page(viewport={"width": w, "height": h})
        # 離線也能跑：擋掉網路字型，改用系統裡的思源／Noto CJK 字型
        await page.route("**/*", lambda r: r.abort() if "fonts.g" in r.request.url else r.continue_())
        await page.goto(pathlib.Path(a.page).resolve().as_uri(), wait_until="domcontentloaded")
        await page.wait_for_timeout(300)
        items = await page.evaluate("window.__tm.list()")

        if a.list:
            for it in items:
                print(f"{it['no']}  {it['id']:<10} {it['zh']}  ({it['en']})  {it['len']}s")
            await browser.close()
            return

        known = {it["id"] for it in items}
        unknown = [i for i in a.ids if i not in known]
        if unknown:
            await browser.close()
            sys.exit("沒有這些 id：" + ", ".join(unknown) + "（用 --list 查）")
        todo = [it for it in items if not a.ids or it["id"] in a.ids]

        cdp = await page.context.new_cdp_session(page)
        for it in todo:
            folder = os.path.join(a.out, GROUP_DIRS.get(it["g"], it["g"]))
            os.makedirs(folder, exist_ok=True)
            path = os.path.join(folder, f"{it['no']}_{it['zh']}_{it['en'].replace(' ', '-')}.mp4")
            frames = round((a.seconds or it["len"]) * a.fps)
            ff = subprocess.Popen(
                ["ffmpeg", "-loglevel", "error", "-y", "-f", "image2pipe", "-framerate", str(a.fps),
                 "-c:v", "mjpeg", "-i", "-",
                 "-vf", "scale=out_color_matrix=bt709:out_range=tv,format=yuv420p",
                 "-c:v", "libx264", "-preset", "fast", "-tune", "animation", "-crf", str(a.crf),
                 "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709",
                 "-movflags", "+faststart", path],
                stdin=subprocess.PIPE,
            )
            t0 = time.time()
            await page.evaluate(
                "([id, scheme, words]) => window.__tm.open(id, scheme, words)",
                [it["id"], a.scheme, words],
            )
            await page.wait_for_timeout(120)
            for i in range(frames):
                await page.evaluate("t => window.__tm.at(t)", i / a.fps)
                shot = await cdp.send("Page.captureScreenshot", {"format": "jpeg", "quality": 95})
                ff.stdin.write(base64.b64decode(shot["data"]))
            ff.stdin.close()
            if ff.wait() != 0:
                await browser.close()
                sys.exit(f"ffmpeg 編碼失敗：{path}")
            print(f"{os.path.relpath(path)}  {frames} 格  {time.time() - t0:.1f}s  {os.path.getsize(path) / 1e6:.2f}MB", flush=True)
        await browser.close()


if __name__ == "__main__":
    asyncio.run(run(parse_args()))
