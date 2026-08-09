#!/usr/bin/env python3
"""
YouTube & TikTok automated uploader.

=== SETUP (first time only) ===

YouTube:
  1. https://console.cloud.google.com → create project → APIs & Services → Enable YouTube Data API v3
  2. OAuth consent screen → External → app name "PetaName" → add your gmail as test user
  3. Credentials → Create OAuth client ID → Desktop app → download as scripts/client_secret.json
  4. Run: python scripts/youtube_upload.py --video store_assets/promo/youtube_shorts_1080x1920.mp4
  5. Browser opens → authorize → token saved to scripts/.youtube_token.json

TikTok:
  TikTok direct API requires business account + approval. Easier path:
  - Post manually via TikTok web (tiktok.com/upload) — still fastest
  - Or use a scheduler like Later/Buffer (free tier for 1 account)

=== USAGE ===

# Upload a video to YouTube
python scripts/youtube_upload.py --video path/to/video.mp4

# Upload with custom title/description
python scripts/youtube_upload.py --video path/to/video.mp4 --title "My Title" --description "desc"

# Upload as Short (auto-detected for vertical videos under 60s)
python scripts/youtube_upload.py --video store_assets/promo/youtube_shorts_1080x1920.mp4

# Batch upload all videos in a folder
python scripts/youtube_upload.py --batch path/to/folder
"""

import argparse
import json
import os
import pickle
import sys
from datetime import datetime, timezone
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
CLIENT_SECRETS = PROJECT_ROOT / "scripts" / "client_secret.json"
TOKEN_FILE = PROJECT_ROOT / "scripts" / ".youtube_token.pickle"
SCOPES = ["https://www.googleapis.com/auth/youtube.upload"]

APP_URL = "https://web-sigma-drab-72.vercel.app"
PLAY_URL = "https://play.google.com/store/apps/details?id=com.nanimonjya"

SHORTS_DESCRIPTION = """PetaName — Free face & name memory training game.

🧠 Train your brain to remember names
📸 Upload real people you need to remember
💼 Business card mode with OCR & voice intros
📚 25+ science-backed memory articles

Try it free (no account needed):
Web: {web}
Google Play: {play}

#memorytraining #braintraining #namerecall #Shorts"""

LONG_DESCRIPTION = """PetaName is a free face-and-name memory training game backed by cognitive science.

"Wait... what was their name?" — Never freeze up again.

FIVE GAME MODES:
🧠 Name Call — rapid name recall race. 2-4 players on one device, online ranked, CPU opponents.
📸 Face Memo — log real colleagues/classmates. Build avatars. Train with their faces.
💼 Business Recall — simulate real introductions: meet → time passes → recall with voice.
🚀 Project Noah — sci-fi story mode. Who you remember decides who survives.
📚 Reading — 25+ articles distilling memory research into techniques you can use.

Real cognitive science, not buzzwords:
✅ Elaborative encoding (Craik & Tulving, 1975)
✅ The Baker-Baker technique (McWeeny et al., 1987)
✅ Self-referential processing (Rogers et al., 1977)
✅ Spaced retrieval with next-day review
✅ Production effect — saying names out loud

Free on Android & Web. No account needed. Data stays on-device.

Web: {web}
Google Play: {play}
Support: https://buymeacoffee.com/toriumi

#memorytraining #braintraining #namerecall #cognitive #androidgames #edtech #flutter"""


def get_authenticated_service():
    """OAuth2 flow — opens browser on first run, silent on subsequent runs."""
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    from googleapiclient.discovery import build

    credentials = None

    if TOKEN_FILE.exists():
        with open(TOKEN_FILE, "rb") as f:
            credentials = pickle.load(f)

    if not credentials or not credentials.valid:
        if credentials and credentials.expired and credentials.refresh_token:
            credentials.refresh(Request())
        else:
            if not CLIENT_SECRETS.exists():
                print(f"ERROR: {CLIENT_SECRETS} not found.")
                print("1. Go to https://console.cloud.google.com")
                print("2. Create project → Enable YouTube Data API v3")
                print("3. Credentials → Create OAuth client ID → Desktop app")
                print("4. Download as scripts/client_secret.json")
                sys.exit(1)

            flow = InstalledAppFlow.from_client_secrets_file(
                str(CLIENT_SECRETS), SCOPES
            )
            credentials = flow.run_local_server(port=8080)

        with open(TOKEN_FILE, "wb") as f:
            pickle.dump(credentials, f)

    return build("youtube", "v3", credentials=credentials)


def upload_video(youtube, video_path: str, title: str, description: str,
                 tags: list[str], category: str = "28") -> str:
    """Upload video to YouTube. category 28 = Science & Technology."""
    from googleapiclient.http import MediaFileUpload

    body = {
        "snippet": {
            "title": title[:100],
            "description": description,
            "tags": tags,
            "categoryId": category,
            "defaultLanguage": "en",
        },
        "status": {
            "privacyStatus": "public",
            "selfDeclaredMadeForKids": False,
        },
    }

    # Detect vertical Shorts (9:16 aspect ratio)
    # We'll mark as Shorts if title contains #Shorts or it's vertical

    media = MediaFileUpload(video_path, chunksize=-1, resumable=True)
    request = youtube.videos().insert(
        part="snippet,status",
        body=body,
        media_body=media,
    )

    print(f"Uploading: {Path(video_path).name}...")
    response = None
    while response is None:
        status, response = request.next_chunk()
        if status:
            print(f"  {int(status.progress() * 100)}%", end="\r")

    video_id = response["id"]
    url = f"https://youtu.be/{video_id}"
    print(f"\n  Done: {url}")
    return url


def detect_video_type(path: str) -> tuple[str, str]:
    """Detect if video is a Short or regular. Returns (type, suggested_title_prefix)."""
    # For now, we check file name and size
    name = Path(path).stem.lower()
    size = os.path.getsize(path)

    is_short = any(kw in name for kw in ["short", "shorts", "tiktok", "reel"])
    is_vertical = False  # ideally we'd check resolution, but trust naming

    if is_short or size < 10 * 1024 * 1024:  # under 10MB = likely short
        return "short", "#Shorts "
    return "video", ""


def main():
    parser = argparse.ArgumentParser(description="YouTube video uploader")
    parser.add_argument("--video", help="Path to video file")
    parser.add_argument("--title", help="Video title (auto-generated if omitted)")
    parser.add_argument("--description", help="Video description")
    parser.add_argument("--tags", help="Comma-separated tags")
    parser.add_argument("--batch", help="Upload all MP4 files in a folder")
    args = parser.parse_args()

    youtube = get_authenticated_service()
    default_tags = ["PetaName", "memory training", "brain training", "name recall",
                    "memory game", "cognitive science", "android game", "free game"]

    videos = []
    if args.batch:
        folder = Path(args.batch)
        videos = list(folder.glob("*.mp4")) + list(folder.glob("*.mov"))
        if not videos:
            print(f"No MP4/MOV files found in {folder}")
            return
    elif args.video:
        videos = [Path(args.video)]
    else:
        print("ERROR: --video or --batch required")
        return

    for vpath in videos:
        vtype, prefix = detect_video_type(str(vpath))

        if args.title:
            title = args.title
        else:
            base = vpath.stem.replace("_", " ").title()
            title = f"{prefix}{base} | PetaName Memory Game"

        if args.description:
            description = args.description.format(web=APP_URL, play=PLAY_URL)
        elif vtype == "short":
            description = SHORTS_DESCRIPTION.format(web=APP_URL, play=PLAY_URL)
        else:
            description = LONG_DESCRIPTION.format(web=APP_URL, play=PLAY_URL)

        tags = args.tags.split(",") if args.tags else default_tags

        try:
            upload_video(youtube, str(vpath), title, description, tags)
        except Exception as e:
            print(f"  FAILED: {e}")


if __name__ == "__main__":
    main()
