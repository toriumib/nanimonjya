#!/usr/bin/env python3
"""
PetaName Auto Poster — SNS自動投稿エンジン

Mastodon と Bluesky に自動投稿する。どちらも API が無料・承認不要。
Twitter/X は有料API化されたため対象外（手動で貼る）。

=== 初期設定（各1回だけ） ===

[Mastodon]
1. 好きなインスタンス（例: mastodon.social / mstdn.jp）でアカウントを作る
2. 設定 → 開発 → 新規アプリケーション で token を発行
3. 下記コマンドで登録:
   python scripts/auto_poster.py setup mastodon --instance <INSTANCE> --token <TOKEN>

[Bluesky]
1. https://bsky.app でアカウントを作る
2. 設定 → プライバシーとセキュリティ → App Passwords → 新規作成
3. 下記コマンドで登録:
   python scripts/auto_poster.py setup bluesky --handle <HANDLE> --password <APP_PASSWORD>

=== 使い方 ===

# いますぐ1本投稿（内容を自動で選ぶ）
python scripts/auto_poster.py post

# 指定の投稿を送る
python scripts/auto_poster.py post --text "PetaName is a free memory training game..."

# 画像つき投稿
python scripts/auto_poster.py post --text "..." --image promo_output/ogp-image.png

# 30日分のカレンダーから、今日のぶんを自動投稿
python scripts/auto_poster.py daily

# すべてのプラットフォームに一斉投稿
python scripts/auto_poster.py blast
"""

import argparse
import json
import os
import random
import sys
import time
import urllib.request
import urllib.error
from datetime import datetime, timedelta
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
CONFIG_FILE = PROJECT_ROOT / "scripts" / ".auto_poster_config.json"
CALENDAR_FILE = PROJECT_ROOT / "promo_output" / "content_calendar.json"

APP_URL = "https://petaname.web.app/"
PLAY_URL = "https://play.google.com/store/apps/details?id=com.nanimonjya"

# ─── 投稿プール ───

HOOKS = [
    "You meet someone. Three seconds later, their name is gone.",
    "5 people in this room. You remember 1 name. The other 4? Nope.",
    'Coworker: "Hey, you remember me, right?" You: "...Of course!" (You don\'t.)',
    "New job = 30 new names. Your brain: \"I'll remember 3. Take it or leave it.\"",
    'The most awkward 2 seconds: "...what was your name again?"',
    "Face recognition: 10/10. Name recall: -5/10.",
    "Scientists have a name for why names are so hard to remember.",
    "Most brain games train match-3. This one trains remembering YOUR BOSS'S NAME.",
    "You only get one chance to learn someone's name in this sci-fi story game.",
    "Meet -> forget -> \"nice to see you *person whose name I definitely know*\"",
]

FEATURES = [
    "Name Call — rapid name recall race (2-4 players on one device)",
    "Face Memo — log real people, build avatars, train with their faces",
    "Business Recall — meet someone, time passes, then recall their details",
    "Project Noah — sci-fi story mode where your memory shapes the ending",
    "Business card OCR — snap a card, auto-fill the profile",
    "Avatar builder — no photo needed. Building features IS memorization.",
    "25+ research-backed articles on name memory",
    "Online ranked matches — compete globally in name recall",
]

CTAS = [
    f"Free on Android & Web: {APP_URL}",
    f"Google Play: {PLAY_URL}",
    f"No account needed. Free. {APP_URL}",
    "Download free on Google Play ->",
]

TAGS = [
    "#memory #braintraining #indiegame",
    "#cognitivescience #memoryhack #edtech",
    "#selfimprovement #learning #android",
    "#flutterdev #indiedev #buildinpublic",
]


def load_config():
    if CONFIG_FILE.exists():
        return json.loads(CONFIG_FILE.read_text("utf-8"))
    return {}


def save_config(cfg):
    CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
    CONFIG_FILE.write_text(json.dumps(cfg, indent=2), "utf-8")


def random_post():
    """組み合わせで毎回ちがう投稿を生成する"""
    hook = random.choice(HOOKS)
    feat = random.choice(FEATURES)
    cta = random.choice(CTAS)
    tags = random.choice(TAGS)

    # 投稿全体を280字以内に保つ（Mastodonの表示制限ではないが読みやすさ重視）
    post = f"{hook}\n\n{feat}\n\n{cta}\n\n{tags}"
    return post


# ─── Mastodon ───

def post_mastodon(instance: str, token: str, text: str, image_path: str = None):
    """Mastodon REST API で投稿。画像がある場合は先にアップロード。"""
    media_ids = []
    if image_path and os.path.exists(image_path):
        boundary = "----petanameboundary"
        with open(image_path, "rb") as f:
            img_data = f.read()

        body = (
            f"--{boundary}\r\n"
            f'Content-Disposition: form-data; name="file"; filename="{os.path.basename(image_path)}"\r\n'
            f"Content-Type: image/png\r\n\r\n"
        ).encode() + img_data + f"\r\n--{boundary}--\r\n".encode()

        req = urllib.request.Request(
            f"https://{instance}/api/v2/media",
            data=body,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": f"multipart/form-data; boundary={boundary}",
            },
            method="POST",
        )
        try:
            resp = json.loads(urllib.request.urlopen(req).read())
            media_ids.append(resp["id"])
        except Exception as e:
            print(f"  Mastodon media upload failed: {e}")

    payload = json.dumps({"status": text, "media_ids": media_ids}).encode()
    req = urllib.request.Request(
        f"https://{instance}/api/v1/statuses",
        data=payload,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        resp = json.loads(urllib.request.urlopen(req).read())
        print(f"  Mastodon: {resp.get('url', 'posted')}")
        return True
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"  Mastodon error {e.code}: {body}")
        return False


# ─── Bluesky (AT Protocol) ───

def _bsky_auth(handle: str, app_password: str) -> dict:
    """Bluesky にログインして accessJwt を返す"""
    payload = json.dumps({"identifier": handle, "password": app_password}).encode()
    req = urllib.request.Request(
        "https://bsky.social/xrpc/com.atproto.server.createSession",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    return json.loads(urllib.request.urlopen(req).read())


def post_bluesky(handle: str, app_password: str, text: str, image_path: str = None):
    """Bluesky AT Protocol で投稿。"""
    try:
        session = _bsky_auth(handle, app_password)
    except Exception as e:
        print(f"  Bluesky auth failed: {e}")
        return False

    jwt = session["accessJwt"]
    did = session["did"]

    # 画像アップロード
    thumb_blob = None
    if image_path and os.path.exists(image_path):
        try:
            with open(image_path, "rb") as f:
                img_data = f.read()
            # Bluesky は multipart ではなくバイナリ直送
            boundary = "----bskyboundary"
            body = (
                f"--{boundary}\r\n"
                f'Content-Disposition: form-data; name="file"; filename="{os.path.basename(image_path)}"\r\n'
                f"Content-Type: image/png\r\n\r\n"
            ).encode() + img_data + f"\r\n--{boundary}--\r\n".encode()

            req = urllib.request.Request(
                "https://bsky.social/xrpc/com.atproto.repo.uploadBlob",
                data=img_data,
                headers={
                    "Authorization": f"Bearer {jwt}",
                    "Content-Type": "application/octet-stream",
                },
                method="POST",
            )
            thumb_blob = json.loads(urllib.request.urlopen(req).read())["blob"]
        except Exception as e:
            print(f"  Bluesky image upload failed: {e}")

    # 投稿本文
    record = {
        "collection": "app.bsky.feed.post",
        "repo": did,
        "record": {
            "text": text,
            "createdAt": datetime.utcnow().isoformat() + "Z",
        },
    }

    if thumb_blob:
        # Bluesky の画像埋め込み
        record["record"]["embed"] = {
            "$type": "app.bsky.embed.images",
            "images": [{"image": thumb_blob, "alt": "PetaName app screenshot"}],
        }
        # ファセット（リンクのクリック可能化）
        record["record"]["facets"] = [
            {
                "index": {
                    "byteStart": text.find(APP_URL),
                    "byteEnd": text.find(APP_URL) + len(APP_URL),
                },
                "features": [
                    {
                        "$type": "app.bsky.richtext.facet#link",
                        "uri": APP_URL,
                    }
                ],
            }
        ]

    payload = json.dumps(record).encode()
    req = urllib.request.Request(
        "https://bsky.social/xrpc/com.atproto.repo.createRecord",
        data=payload,
        headers={
            "Authorization": f"Bearer {jwt}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        resp = json.loads(urllib.request.urlopen(req).read())
        print(f"  Bluesky: at://{did}/{resp['uri'].split('/')[-1]}")
        return True
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"  Bluesky error {e.code}: {body}")
        return False


# ─── CLI ───

def cmd_setup(args):
    cfg = load_config()
    if args.platform == "mastodon":
        cfg["mastodon"] = {"instance": args.instance, "token": args.token}
        print(f"Mastodon: {args.instance} を登録しました")
    elif args.platform == "bluesky":
        cfg["bluesky"] = {"handle": args.handle, "password": args.password}
        print(f"Bluesky: @{args.handle} を登録しました")
    save_config(cfg)


def cmd_post(args):
    cfg = load_config()
    text = args.text or random_post()
    image = args.image
    if not image:
        ogp = PROJECT_ROOT / "web" / "icons" / "ogp-image.png"
        if ogp.exists():
            image = str(ogp)

    print(f"Post: {text[:80]}...")
    ok = True

    if args.platform in ("mastodon", "all"):
        m = cfg.get("mastodon")
        if m:
            print("[Mastodon]")
            ok &= post_mastodon(m["instance"], m["token"], text, image)
        else:
            print("[Mastodon] not configured. Run: python scripts/auto_poster.py setup mastodon")

    if args.platform in ("bluesky", "all"):
        b = cfg.get("bluesky")
        if b:
            print("[Bluesky]")
            ok &= post_bluesky(b["handle"], b["password"], text, image)
        else:
            print("[Bluesky] not configured. Run: python scripts/auto_poster.py setup bluesky")

    return ok


def cmd_daily(args):
    """今日のカレンダーから自動投稿"""
    cfg = load_config()
    today = datetime.now().strftime("%Y-%m-%d")

    if not CALENDAR_FILE.exists():
        print("No calendar file. Run: python scripts/promote.py calendar")
        return False

    cal = json.loads(CALENDAR_FILE.read_text("utf-8"))
    for day in cal.get("calendar", []):
        if day["date"] == today:
            text = day["content"]
            break
    else:
        # カレンダーに今日がなければランダム生成
        text = random_post()

    print(f"Daily post ({today}): {text[:80]}...")
    ok = True

    m = cfg.get("mastodon")
    if m:
        print("[Mastodon]")
        ok &= post_mastodon(m["instance"], m["token"], text)

    b = cfg.get("bluesky")
    if b:
        print("[Bluesky]")
        ok &= post_bluesky(b["handle"], b["password"], text)

    return ok


def cmd_blast(args):
    """全プラットフォームに連続投稿（間隔をあける）"""
    posts = [random_post() for _ in range(3)]

    for i, text in enumerate(posts):
        print(f"\n=== Post {i + 1}/3 ===")
        cmd_post(argparse.Namespace(
            platform="all", text=text, image=None
        ))
        if i < len(posts) - 1:
            wait = random.randint(30, 90)
            print(f"  Waiting {wait}s before next post...")
            time.sleep(wait)

    print("\nBlast complete.")


def main():
    parser = argparse.ArgumentParser(description="PetaName Auto Poster")
    sub = parser.add_subparsers(dest="command", required=True)

    setup = sub.add_parser("setup", help="Configure a platform")
    setup.add_argument("platform", choices=["mastodon", "bluesky"])
    setup.add_argument("--instance", help="Mastodon instance hostname (e.g. mstdn.jp)")
    setup.add_argument("--token", help="Mastodon access token")
    setup.add_argument("--handle", help="Bluesky handle (e.g. petaname.bsky.social)")
    setup.add_argument("--password", help="Bluesky app password")

    post = sub.add_parser("post", help="Post now")
    post.add_argument("--platform", default="all", choices=["mastodon", "bluesky", "all"])
    post.add_argument("--text", help="Post text (random if omitted)")
    post.add_argument("--image", help="Image path (OGP image if omitted)")

    sub.add_parser("daily", help="Post today's calendar entry")
    sub.add_parser("blast", help="Post 3 times with delays")

    args = parser.parse_args()

    if args.command == "setup":
        cmd_setup(args)
    elif args.command == "post":
        cmd_post(args)
    elif args.command == "daily":
        cmd_daily(args)
    elif args.command == "blast":
        cmd_blast(args)


if __name__ == "__main__":
    main()
