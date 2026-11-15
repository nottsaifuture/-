#!/usr/bin/env python3
"""Make a standalone, looping single-effect HTML page from assets/index.html.

Usage:
  python make_player.py burst --words "今晚八點 首播" --scheme key --out burst.html
  python make_player.py --list
The output is one self-contained HTML file (fonts from Google Fonts when online,
system CJK fonts offline) that plays only that effect full-window, looping forever.
"""
import argparse, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
PAGE = os.path.join(HERE, "..", "assets", "index.html")
SCHEMES = ["ink", "paper", "cobalt", "verm", "key"]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("id", nargs="?")
    ap.add_argument("--words", default="", help="space-separated words (max 8, 14 chars each)")
    ap.add_argument("--scheme", choices=SCHEMES, help="ink / paper / cobalt / verm / key(green screen)")
    ap.add_argument("--out")
    ap.add_argument("--list", action="store_true")
    a = ap.parse_args()
    src = open(PAGE, encoding="utf-8").read()
    ids = re.findall(r"\{id:'([^']+)',g:'", src)
    if a.list or not a.id:
        print(" ".join(ids)); return
    if a.id not in ids:
        sys.exit(f"unknown id {a.id!r}; use --list")
    words = [w[:14] for w in re.split(r"[\s,，、;；|/]+", a.words) if w][:8]
    boot = f"""<script>
(function(){{
  var id={json.dumps(a.id)}, sc={json.dumps(a.scheme)}, W={json.dumps(words, ensure_ascii=False)};
  function go(){{
    var api=window.__tm, it=api.list().find(function(x){{return x.id===id;}});
    api.open(id, sc, W.length?W:null);
    document.documentElement.style.background='#000';document.body.style.margin='0';
    var t0=performance.now(), L=it.len||6;
    (function loop(now){{api.at(((now-t0)/1000)%L);requestAnimationFrame(loop);}})(t0);
  }}
  if(document.readyState==='loading')addEventListener('DOMContentLoaded',function(){{setTimeout(go,50);}});else setTimeout(go,50);
}})();
</script>
</body>"""
    title = f"<title>{a.id}</title>"
    out_html = re.sub(r"<title>.*?</title>", title, src, count=1, flags=re.S)
    i = out_html.rfind("</body>")
    out_html = out_html[:i] + boot + out_html[i + len("</body>"):] if i >= 0 else out_html + boot
    out = a.out or f"{a.id}.html"
    open(out, "w", encoding="utf-8").write(out_html)
    print(out)

if __name__ == "__main__":
    main()
