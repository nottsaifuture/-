"""Upload a video to YouTube with the YouTube Data API v3 (standard library only).

Reads OAuth credentials from the environment:
  YOUTUBE_CLIENT_ID, YOUTUBE_CLIENT_SECRET, YOUTUBE_REFRESH_TOKEN
The refresh token needs the https://www.googleapis.com/auth/youtube.upload scope
and must belong to the Google account that manages the target channel.

Usage:
  python3 videos/upload_youtube.py VIDEO.mp4 --title "..." --description-file desc.txt \
      [--tags "a,b,c"] [--privacy private|unlisted|public]
"""
import argparse
import json
import os
import sys
import urllib.parse
import urllib.request

TOKEN_URL = "https://oauth2.googleapis.com/token"
UPLOAD_URL = "https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status"
CHANNEL_URL = "https://www.googleapis.com/youtube/v3/channels?part=snippet&mine=true"


def access_token():
    missing = [k for k in ("YOUTUBE_CLIENT_ID", "YOUTUBE_CLIENT_SECRET", "YOUTUBE_REFRESH_TOKEN") if not os.environ.get(k)]
    if missing:
        sys.exit("Missing environment variables: " + ", ".join(missing))
    body = urllib.parse.urlencode({
        "client_id": os.environ["YOUTUBE_CLIENT_ID"],
        "client_secret": os.environ["YOUTUBE_CLIENT_SECRET"],
        "refresh_token": os.environ["YOUTUBE_REFRESH_TOKEN"],
        "grant_type": "refresh_token",
    }).encode()
    with urllib.request.urlopen(urllib.request.Request(TOKEN_URL, data=body)) as r:
        return json.load(r)["access_token"]


def channel_title(token):
    req = urllib.request.Request(CHANNEL_URL, headers={"Authorization": "Bearer " + token})
    with urllib.request.urlopen(req) as r:
        items = json.load(r).get("items", [])
    return items[0]["snippet"]["title"] if items else None


def upload(token, path, title, description, tags, privacy):
    meta = json.dumps({
        "snippet": {"title": title, "description": description, "tags": tags, "categoryId": "25"},  # 25 = News & Politics
        "status": {"privacyStatus": privacy, "selfDeclaredMadeForKids": False},
    }).encode()
    size = os.path.getsize(path)
    start = urllib.request.Request(UPLOAD_URL, data=meta, method="POST", headers={
        "Authorization": "Bearer " + token,
        "Content-Type": "application/json; charset=UTF-8",
        "X-Upload-Content-Type": "video/mp4",
        "X-Upload-Content-Length": str(size),
    })
    with urllib.request.urlopen(start) as r:
        session = r.headers["Location"]
    with open(path, "rb") as f:
        put = urllib.request.Request(session, data=f.read(), method="PUT", headers={
            "Authorization": "Bearer " + token, "Content-Type": "video/mp4", "Content-Length": str(size),
        })
    with urllib.request.urlopen(put) as r:
        return json.load(r)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("video")
    p.add_argument("--title", required=True)
    p.add_argument("--description-file", required=True)
    p.add_argument("--tags", default="")
    p.add_argument("--privacy", default="private", choices=["private", "unlisted", "public"])
    a = p.parse_args()

    token = access_token()
    print("Channel:", channel_title(token))
    with open(a.description_file, encoding="utf-8") as f:
        description = f.read()
    tags = [t.strip() for t in a.tags.split(",") if t.strip()]
    video = upload(token, a.video, a.title, description, tags, a.privacy)
    print("Uploaded:", "https://youtu.be/" + video["id"], "| privacy:", video["status"]["privacyStatus"])


if __name__ == "__main__":
    main()
