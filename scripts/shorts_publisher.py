#!/usr/bin/env python3
"""
YouTube Shorts / TikTok / Instagram Reels multi-platform publisher.

Takes an MP4 video and generates:
- Platform-specific captions (hashtags, descriptions)
- Thumbnail recommendation
- Best posting times per platform

Usage:
  python scripts/shorts_publisher.py --video store_assets/promo/youtube_shorts_1080x1920.mp4
"""

import argparse
import os
import random
from datetime import datetime
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent

APP_URL = "https://web-sigma-drab-72.vercel.app"
PLAY_URL = "https://play.google.com/store/apps/details?id=com.nanimonjya"

# ─── Platform-specific templates ───

YOUTUBE = {
    "title_templates": [
        "Can You Remember This Person's Name? (Memory Game)",
        "I Built a Game to Fix Name Amnesia (Try It Free)",
        "The Baker-Baker Paradox: Why You Forget Names Instantly",
        "Meet 12 People. Remember Their Names. Go.",
        "Memory Science + Card Game = Name Recall Training",
        "New Job? 30 Names to Remember? Play This.",
        "The Most Awkward 2 Seconds: Forgetting Someone's Name",
    ],
    "description_template": """{hook}

PetaName is a free face-and-name memory training game backed by cognitive science research.

🧠 Name Call — rapid name recall race (2-4 players on one device!)
📸 Face Memo — log real people, build avatars
💼 Business Recall — meet → delay → recall with voice intros
📚 25+ research-backed articles on memory

🎮 Try it free (no account needed):
Web: {web}
Google Play: {play}

#memorytraining #braintraining #namerecall #memorygame #cognitive #androidgames #edtech
""",
    "tags": ["memory training", "brain training", "name recall", "memory game", "cognitive science", "android game", "free game", "name memory", "face memory", "ペタネーム"],
    "best_times": "Mon-Fri 12:00-16:00 ET (lunch break + afternoon slump)",
}

TIKTOK = {
    "caption_templates": [
        "Can you remember this person's name? 👀 #memory #braintraining",
        "I built a game because I kept forgetting names 🤦 #indiegame #memory",
        "Name recall: 0/10 but the science says we can fix this 🧠 #cognitivescience",
        "Meet. Remember. Win. Free memory game 👇 #braingame #android",
    ],
    "tags": ["memory", "braintraining", "braingame", "cognitivescience", "learnontiktok", "edtech", "indiegame", "androidgame", "fyp"],
    "best_times": "Tue/Thu 7:00-9:00 AM + 7:00-9:00 PM (commute hours)",
}

INSTAGRAM = {
    "caption_templates": [
        """The Baker-Baker Paradox: Why names slip away 🧠

Research shows names are uniquely hard to remember because they lack semantic meaning. "Baker" the name vs "baker" the profession — your brain attaches meaning to one and discards the other.

That's why PetaName trains you to attach meaning to names — not just memorize them.

Free on Android & Web. Link in bio. ☝️

#memory #learning #cognitivescience #braintraining""",

        """3 ways PetaName helps you remember names:

1️⃣ Name Call — meet people, name them, recall later
2️⃣ Face Memo — log real colleagues, build avatars
3️⃣ Business Recall — simulate real introductions with voice

Backed by 25+ published memory studies.
Free. No account. Android + Web.

#productivity #networking #memoryhack #androidapp""",
    ],
    "story_ideas": [
        "Quick poll: 'Do you forget names within 30 seconds of meeting someone?' with Yes/No sticker",
        "Before/After: 'Me before PetaName vs after — now I remember everyone at the party'",
        "Swipe-up link to web app with text 'Try it now — free, no account'",
        "Countdown sticker: 'How many names can you remember in 10 seconds?'",
    ],
    "best_times": "Mon/Wed/Fri 11:00 AM + 7:00-9:00 PM",
}

X_TWITTER = {
    "growth_tactics": """
=== X/Twitter Growth Tactics (no API needed) ===

1. REPLY TO BIG ACCOUNTS
   - Follow @hubermanlab, @sciam, @PsychToday
   - Reply with genuine insight within 30 min of their post
   - Example: they post about memory → you reply "This is why I built a game that
     uses the Baker-Baker technique to fix name recall. Free on web."
   - First reply gets the most visibility

2. THREAD ONCE A WEEK
   - "🧵 Why you forget names (backed by 6 studies):"
   - 6 tweets: 1 study per tweet, last tweet = link to PetaName
   - Threads get 3-5x more engagement than single tweets

3. BUILD-IN-PUBLIC
   - Post a screenshot of analytics/flutter code/new feature weekly
   - "#buildinpublic #flutter #indiedev"
   - Indie dev community is very supportive and will try your app

4. POSTING SCHEDULE
   - 1 tweet/day (hook + feature + link)
   - 1 thread/week (science deep dive)
   - Best times: 8-10 AM ET + 12-1 PM ET (lunch) + 5-6 PM ET (commute)
   - Use promo_output/launch_twitter.txt for the first 7 days

5. PINNED TWEET
   - Pin your best thread or a "what is PetaName" tweet
   - Every new visitor to your profile sees this first
""",
    "thread_ideas": [
        "Why do we remember faces but not names? (Baker-Baker paradox)",
        "6 cognitive science findings that explain name amnesia",
        "I analyzed 25 memory studies. Here's what actually works for names.",
        "How I built a memory training game with Flutter + Firebase (tech thread)",
        "From 'I keep forgetting names' to launching on Google Play — the story",
    ],
}


def generate_for_platform(platform: str) -> str:
    """Generate platform-specific posting content."""
    if platform == "youtube":
        return f"""=== YOUTUBE SHORTS ===

Title: {random.choice(YOUTUBE['title_templates'])}

Description:
{YOUTUBE['description_template'].format(
    hook=random.choice([
        "Can you remember this person's name? Most people can't.",
        "Meet someone → forget their name → feel awkward. Sound familiar?",
    ]),
    web=APP_URL,
    play=PLAY_URL,
)}

Tags: {', '.join(YOUTUBE['tags'])}

Best posting time: {YOUTUBE['best_times']}
"""

    elif platform == "tiktok":
        return f"""=== TIKTOK ===

Caption: {random.choice(TIKTOK['caption_templates'])}

Hashtags: {' '.join('#' + t for t in TIKTOK['tags'][:8])}

Best posting time: {TIKTOK['best_times']}

Pro tip: Post the same video on TikTok AND YouTube Shorts.
         The algorithm is different so cross-posting is fine.
         Use the existing video: store_assets/promo/youtube_shorts_1080x1920.mp4
"""

    elif platform == "instagram":
        return f"""=== INSTAGRAM REELS + STORIES ===

Reel caption:
{random.choice(INSTAGRAM['caption_templates'])}

Story ideas (post 1-2 per day):
{chr(10).join('- ' + s for s in INSTAGRAM['story_ideas'])}

Best posting time: {INSTAGRAM['best_times']}
"""

    elif platform == "x":
        return X_TWITTER['growth_tactics'] + "\n\nThread ideas:\n" + "\n".join(f"- {t}" for t in X_TWITTER['thread_ideas'])

    elif platform == "all":
        return "\n\n".join(generate_for_platform(p) for p in ["youtube", "tiktok", "instagram", "x"])

    return ""


def main():
    parser = argparse.ArgumentParser(description="Multi-platform short video publisher")
    parser.add_argument("--platform", default="all",
                        choices=["youtube", "tiktok", "instagram", "x", "all"])
    parser.add_argument("--video", help="Path to video file for metadata")
    args = parser.parse_args()

    if args.video:
        path = Path(args.video)
        if path.exists():
            size_mb = path.stat().st_size / (1024 * 1024)
            print(f"Video: {path.name} ({size_mb:.1f} MB)")
        else:
            print(f"Warning: {args.video} not found")

    print(generate_for_platform(args.platform))

    if args.platform in ("all", "tiktok", "instagram"):
        print(f"\n{'='*60}")
        print("EXISTING ASSETS YOU CAN POST RIGHT NOW:")
        print(f"  Video: store_assets/promo/youtube_shorts_1080x1920.mp4 (19.5s)")
        print(f"  Thumbnail: store_assets/promo/thumbnail_hook.png")
        print(f"  Screenshots: store_assets/screenshots/ (9 files)")
        print(f"  Narration script: store_assets/promo/narration_script.txt")


if __name__ == "__main__":
    main()
