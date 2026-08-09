#!/usr/bin/env python3
"""
Social media content generator and scheduler for PetaName.
Generates promotional posts for Twitter/X, Mastodon, Bluesky, LinkedIn,
Reddit, and Hacker News (Show HN). Posts are saved as text files and
can be auto-posted via platform APIs.

Usage:
  python scripts/promote.py generate --platform twitter    # Generate 5 tweets
  python scripts/promote.py generate --platform all         # Generate for all platforms
  python scripts/promote.py calendar                        # Generate a 30-day content calendar
  python scripts/promote.py launch                          # Generate launch announcement pack
"""

import argparse
import json
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUTPUT_DIR = PROJECT_ROOT / "promo_output"

APP_NAME = "PetaName"
APP_URL = "https://petaname.web.app/"
PLAY_URL = "https://play.google.com/store/apps/details?id=com.nanimonjya"
TAGLINE = "Never forget a name again."
TECH_TAGLINE = "Face & name memory training backed by cognitive science."

# ─── Post Templates ───────────────────────────────────────────────

HOOKS = [
    "You meet someone. Three seconds later, their name is gone. 😵‍💫",
    "5 people in this room. You remember 1 name. The other 4? Nope.",
    "Coworker: 'Hey, you remember me, right?' You: '...Of course!' (You don't.)",
    "New job = 30 new names. Your brain: 'I'll remember 3. Take it or leave it.'",
    "The most awkward 2 seconds in the world: '...what was your name again?'",
    "Face recognition: 10/10. Name recall: -5/10. What's wrong with our brains?",
    "Meet → forget → 'nice to see you *person whose name I definitely know*'",
    "Scientists have a name for why names are so hard to remember. It's fascinating.",
    "Most brain games train match-3 patterns. This one trains remembering YOUR BOSS'S NAME.",
    "The Baker/baker paradox explains everything wrong with how you remember names.",
    "A game that actually helps in real life? Yes — it's about names.",
    "You only get one chance to learn someone's name in this sci-fi story game.",
]

FEATURES = [
    "🧠 Name Call — rapid name recall game (2-4 players on one device!)",
    "📸 Face Memo — log real people. Build avatars. Train with their faces.",
    "💼 Business Recall — simulate meeting → delay → recall (with voice intros!)",
    "🚀 Project Noah — sci-fi story mode. Who you remember decides who survives.",
    "📚 25+ articles — memory research distilled into techniques you can actually use.",
    "🖼️ Avatar builder — no photo needed. Building features IS memorization.",
    "📇 Business card OCR — snap a card, auto-fill the profile.",
    "🌐 Online ranked matches — face your friends (and strangers) in name recall battles.",
]

SCIENCE_BITES = [
    "Retrieval practice beats re-reading. (Roediger & Karpicke, 2006)",
    "Names are uniquely hard — the Baker paradox. (McWeeny et al., 1987)",
    "Self-reference boosts memory. Connect their name to YOUR life. (Rogers, 1977)",
    "Saying it out loud helps. The 'production effect.' (MacLeod et al., 2010)",
    "Sleep consolidates name memories. (Staresina, 2024, TiCS)",
    "Spaced retrieval > cramming. Wrong answers come back tomorrow.",
]

CTAS = [
    "Free on Android & Web. Link in bio.",
    "Try it: petaname.web.app",
    "Google Play: 'PetaName' (com.nanimonjya)",
    "No account needed. Free. Web + Android.",
    "Download free on Google Play →",
]

HASHTAGS = [
    "#memorytraining #braintraining #namerecall",
    "#memory #learning #productivity",
    "#edtech #cognitivescience #memoryhack",
    "#indiegame #androiddev #flutterdev",
    "#selfimprovement #lifelonglearning #braingames",
]


# ─── Generator ─────────────────────────────────────────────────────

def generate_twitter_posts(count=5):
    """Generate Twitter/X posts (under 280 chars each)."""
    posts = []
    for i in range(count):
        hook = HOOKS[i % len(HOOKS)]
        feat = FEATURES[i % len(FEATURES)]
        cta = CTAS[i % len(CTAS)]
        # Build tweet: hook + feature + CTA
        tweet = f"{hook}\n\n{feat}\n\n{cta}"
        if len(tweet) <= 280:
            posts.append(tweet)
        else:
            # Short version
            posts.append(f"{hook}\n\n{cta}\n\n{APP_URL}")
    return posts


def generate_mastodon_posts(count=3):
    """Generate Mastodon/Bluesky posts (longer form, 500+ chars)."""
    posts = []
    for i in range(count):
        hook = HOOKS[i % len(HOOKS)]
        feat1 = FEATURES[i % len(FEATURES)]
        feat2 = FEATURES[(i + 2) % len(FEATURES)]
        science = SCIENCE_BITES[i % len(SCIENCE_BITES)]
        post = (
            f"{hook}\n\n"
            f"I built {APP_NAME} — a free app that helps you remember names.\n\n"
            f"It has:\n• {feat1}\n• {feat2}\n\n"
            f"Every mechanic is backed by memory research:\n"
            f"{science}\n\n"
            f"Free on Android & Web: {APP_URL}"
        )
        posts.append(post)
    return posts


def generate_linkedin_posts(count=3):
    """Generate LinkedIn posts (professional tone)."""
    posts = []
    for i in range(count):
        posts.append(
            f"After my third time forgetting a colleague's name in the hallway, "
            f"I decided to fix the problem at the root.\n\n"
            f"I built {APP_NAME} — a face-and-name memory training app based on "
            f"published cognitive science research.\n\n"
            f"It uses:\n"
            f"✅ Elaborative encoding (not raw repetition)\n"
            f"✅ The Baker-Baker technique — attach meaning to names\n"
            f"✅ Self-referential processing — connect names to YOUR context\n"
            f"✅ Spaced retrieval with next-day review for wrong answers\n\n"
            f"You can upload photos of real colleagues, classmates, or clients "
            f"and the app builds memory games around them.\n\n"
            f"Free on Android & Web: {APP_URL}\n\n"
            f"#professionaldevelopment #networking #memory #softskills"
        )

    # Add a business-specific post
    posts.append(
        f"Sales, reception, and client-facing roles share one universal pain point: "
        f"remembering names.\n\n"
        f"{APP_NAME} has a 'Business Recall' mode that simulates exactly this:\n"
        f"1️⃣ Meet → person hands you a card, introduces themselves (audio)\n"
        f"2️⃣ Delay → a deliberate gap (research shows this strengthens memory)\n"
        f"3️⃣ Recall → face appears. Can you name them? Company? Title?\n\n"
        f"Wrong answers come back tomorrow (spaced repetition).\n"
        f"You can import real business cards via OCR.\n\n"
        f"Free on Android & Web: {APP_URL}"
    )

    return posts


def generate_reddit_posts():
    """Generate subreddit-specific posts."""
    return {
        "r/InternetIsBeautiful": (
            f"[OC] {APP_NAME} — a free web app that trains your brain to "
            f"remember faces & names, built on cognitive science. "
            f"Upload photos of real people you need to remember. "
            f"No signup required.\n\n{APP_URL}"
        ),
        "r/selfimprovement": (
            f"I built a free tool to fix the #1 social anxiety trigger: "
            f"forgetting someone's name.\n\n"
            f"{APP_NAME} is a memory training app that uses techniques from "
            f"published research — not just another match-3 'brain game.'\n\n"
            f"It has a mode where you upload real people you need to remember "
            f"(coworkers, classmates, clients) and builds memory games around THEM.\n\n"
            f"Another mode simulates a business meeting: meet → delay → recall, "
            f"with voice introductions and business card OCR.\n\n"
            f"Free. No account. Web + Android.\n{APP_URL}"
        ),
        "r/AndroidApps": (
            f"[DEV] {APP_NAME} — I built a face & name memory training game. "
            f"Real cognitive science, not buzzwords. OCR for business cards. "
            f"Avatar builder. Online ranked play. Story mode. Completely free.\n\n"
            f"Google Play: {PLAY_URL}\n"
            f"Web: {APP_URL}"
        ),
        "r/androiddev": (
            f"[SHOW] Built {APP_NAME} with Flutter + Firebase (Firestore, "
            f"Crashlytics, Analytics, Auth, Cloud Functions). \n\n"
            f"Features: real-time online races (lockstep), turn-based replay "
            f"system (replay from move log), OCR (google_mlkit), TTS introductions, "
            f"in-app purchases, AdMob mediation, custom avatar builder, "
            f"and a full sci-fi story mode with branching endings.\n\n"
            f"AMA about the tech stack.\n{PLAY_URL}"
        ),
        "r/japanlife": (
            f"[OC] 人の名前を覚えるのが苦手な人のためのアプリ「ペタネーム」を作りました。\n\n"
            f"顔写真を登録して、その人で神経衰弱ができる無料アプリです。"
            f"名刺OCR、音声の自己紹介、オンライン対戦もあります。\n\n"
            f"Google Play: {PLAY_URL}"
        ),
    }


def generate_show_hn():
    """Generate Hacker News Show HN post."""
    return (
        f"Show HN: {APP_NAME} — A face & name memory training game built on "
        f"cognitive science research\n\n"
        f"Hi HN,\n\n"
        f"I built {APP_NAME} because I kept forgetting people's names at work "
        f"and it was getting embarrassing.\n\n"
        f"The app combines a card-matching game with techniques from published "
        f"memory research: elaborative encoding, the Baker-Baker technique, "
        f"self-referential processing, spaced retrieval, and the production effect.\n\n"
        f"What makes it different from other 'brain training' apps:\n"
        f"- You can upload photos of REAL people you need to remember (colleagues, "
        f"clients, classmates) and the app builds games around them\n"
        f"- A business card mode with OCR, voice introductions, and a "
        f"meet→delay→recall flow that mirrors real situations\n"
        f"- Every mechanic is traceable to a specific published study (cited in-app)\n"
        f"- No account required. Data stays on-device.\n\n"
        f"Tech: Flutter + Firebase. Android + Web.\n\n"
        f"Web: {APP_URL}\n"
        f"Google Play: {PLAY_URL}\n"
        f"Source: (not open source, but happy to discuss the architecture)\n\n"
        f"Cognitive science of name memory is genuinely fascinating — "
        f"happy to discuss in the comments."
    )


# ─── 30-Day Calendar ───────────────────────────────────────────────

def generate_calendar():
    """Generate a 30-day content calendar for social media."""
    days = []
    base_date = datetime.now().replace(hour=9, minute=0, second=0, microsecond=0)

    themes = [
        "Week 1: Hook — The universal pain of forgetting names",
        "Week 2: Feature showcase — What makes PetaName different",
        "Week 3: Science deep dives — The research behind each mechanic",
        "Week 4: Call to action — Share your name-forgetting stories",
    ]

    for i in range(30):
        day = base_date + timedelta(days=i)
        theme_week = i // 7
        day_of_week = day.strftime("%A")

        if day_of_week in ("Saturday", "Sunday"):
            content_type = "engagement"
            prompt = (
                "Q: What's the worst name-forgetting moment you've had? "
                "Reply with your story."
            )
        else:
            if theme_week == 0:
                content_type = "hook"
                prompt = HOOKS[i % len(HOOKS)]
            elif theme_week == 1:
                content_type = "feature"
                prompt = FEATURES[i % len(FEATURES)]
            elif theme_week == 2:
                content_type = "science"
                prompt = SCIENCE_BITES[i % len(SCIENCE_BITES)]
            else:
                content_type = "cta"
                prompt = f"Ready to fix name amnesia? Try it free: {APP_URL}"

        days.append({
            "date": day.strftime("%Y-%m-%d"),
            "day": day_of_week,
            "type": content_type,
            "content": prompt,
        })

    return {
        "generated": datetime.now().isoformat(),
        "themes": themes,
        "calendar": days,
    }


# ─── CLI ───────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="PetaName social media content generator"
    )
    sub = parser.add_subparsers(dest="command", required=True)

    gen = sub.add_parser("generate", help="Generate posts for a platform")
    gen.add_argument(
        "--platform", required=True,
        choices=["twitter", "mastodon", "linkedin", "reddit", "showhn", "all"]
    )
    gen.add_argument("--count", type=int, default=5, help="Number of posts")

    sub.add_parser("calendar", help="Generate 30-day content calendar")
    sub.add_parser("launch", help="Generate full launch announcement pack")

    args = parser.parse_args()
    OUTPUT_DIR.mkdir(exist_ok=True)

    if args.command == "generate":
        results = {}

        if args.platform in ("twitter", "all"):
            results["twitter"] = generate_twitter_posts(args.count)
        if args.platform in ("mastodon", "all"):
            results["mastodon"] = generate_mastodon_posts(args.count)
        if args.platform in ("linkedin", "all"):
            results["linkedin"] = generate_linkedin_posts(args.count)
        if args.platform in ("reddit", "all"):
            results["reddit"] = generate_reddit_posts()
        if args.platform in ("showhn", "all"):
            results["showhn"] = generate_show_hn()

        for platform, posts in results.items():
            fpath = OUTPUT_DIR / f"posts_{platform}.txt"
            with open(fpath, "w", encoding="utf-8") as f:
                if isinstance(posts, list):
                    for i, post in enumerate(posts, 1):
                        f.write(f"=== Post {i} ===\n")
                        f.write(post)
                        f.write(f"\n\n")
                elif isinstance(posts, dict):
                    for subreddit, post in posts.items():
                        f.write(f"=== {subreddit} ===\n")
                        f.write(post)
                        f.write(f"\n\n")
                else:
                    f.write(posts)
            print(f"  → {fpath} ({len(posts)} posts)")

        print(f"\nSaved to {OUTPUT_DIR}/")

    elif args.command == "calendar":
        cal = generate_calendar()
        with open(OUTPUT_DIR / "content_calendar.json", "w", encoding="utf-8") as f:
            json.dump(cal, f, indent=2, ensure_ascii=False)

        # Also write as readable text
        with open(OUTPUT_DIR / "content_calendar.txt", "w", encoding="utf-8") as f:
            for theme in cal["themes"]:
                f.write(f"# {theme}\n\n")
            f.write("\n")
            for day in cal["calendar"]:
                f.write(f"  {day['date']} {day['day']:>9} [{day['type']:>10}]  "
                        f"{day['content'][:100]}...\n")

        print(f"30-day content calendar saved to {OUTPUT_DIR}/content_calendar.*")
        print(f"First day: {cal['calendar'][0]['date']}")

    elif args.command == "launch":
        # Full launch pack: everything + a comprehensive launch guide
        cal = generate_calendar()

        files = {
            "launch_twitter.txt": "\n\n---\n\n".join(generate_twitter_posts(7)),
            "launch_mastodon.txt": "\n\n---\n\n".join(generate_mastodon_posts(3)),
            "launch_linkedin.txt": "\n\n---\n\n".join(generate_linkedin_posts(3)),
            "launch_reddit.txt": "\n\n".join(
                f"=== {sub} ===\n{post}"
                for sub, post in generate_reddit_posts().items()
            ),
            "launch_showhn.txt": generate_show_hn(),
        }

        for fname, content in files.items():
            with open(OUTPUT_DIR / fname, "w", encoding="utf-8") as f:
                f.write(content)

        # Launch guide
        guide = f"""# PetaName Launch Promotion Guide
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}

## Quick Links
- Web: {APP_URL}
- Google Play: {PLAY_URL}
- Press Kit: {APP_URL}presskit.html
- Privacy Policy: {APP_URL}privacy.html

## Launch Checklist

### Day 0: Pre-launch
[ ] Verify all links work (web, Play Store, press kit, privacy)
[ ] Verify OGP tags render correctly (use https://www.opengraph.xyz)
[ ] Have screenshots ready (store_assets/screenshots/)
[ ] Prepare a pinned tweet/profile update

### Day 1: Launch day
[ ] Post on Twitter/X (use launch_twitter.txt)
[ ] Post on Mastodon (use launch_mastodon.txt)
[ ] Post Show HN (use launch_showhn.txt) — best time: 11am ET weekdays
[ ] Post on relevant subreddits (use launch_reddit.txt) — stagger by 2+ hours
[ ] Update Google Play store listing with English version (STORE_LISTING_EN.md)

### Day 2-3: Follow-up
[ ] Post LinkedIn article (use launch_linkedin.txt)
[ ] Reply to every comment on HN, Reddit, Twitter
[ ] Post a "lessons learned building this" thread on Twitter

### Day 4-7: Content drip
[ ] Post science deep-dive #1: Baker-Baker paradox
[ ] Post science deep-dive #2: Why retrieval beats re-reading
[ ] Share user feedback / reviews (if any)
[ ] Post feature spotlight: Business Recall mode

### Week 2-4: Sustained
[ ] Follow the 30-day content calendar (content_calendar.txt)
[ ] Reach out to: memory/learning bloggers, edtech YouTubers, productivity newsletters
[ ] Consider Product Hunt launch
[ ] Consider Japanese tech media (ケータイWatch, 窓の杜, etc.)

## Pitching to Press / Influencers

### Target outlets
- **Tech:** TechCrunch (app section), The Verge (apps), 9to5Google
- **Productivity:** Lifehacker, Zapier blog, Todoist blog
- **Science:** BPS Research Digest, Psychology Today blog
- **Japan:** ケータイWatch, 窓の杜, AppBank, アプリオ

### Email pitch template
Subject: PetaName — A memory game that uses real cognitive science, not buzzwords

Hi [NAME],

I built PetaName because I kept forgetting coworkers' names and the existing
"brain training" apps felt like glorified match-3 games.

PetaName is different:
- Every mechanic is traceable to a specific published study (cited in-app)
- You can upload photos of REAL people you need to remember
- A business card mode with OCR and voice introductions
- A sci-fi story mode where your memory shapes the ending

It's free on Android & Web, with no account required.
Data stays on-device.

Press kit: {APP_URL}presskit.html
Google Play: {PLAY_URL}

Would you be interested in trying it out?

Best,
Kengo Abe

### Japanese outlets pitch
件名: 人の名前を覚えるための無料アプリ「ペタネーム」— 認知科学に基づいた記憶トレーニング

[NAME] 様

初めまして、開発者の阿部と申します。
「顔は思い出せるのに名前が出てこない」を、認知科学の研究に基づいて
克服する無料アプリ「ペタネーム」をリリースしました。

特徴：
- 実際に覚えたい人の写真を登録して練習できる
- 名刺OCR＋音声自己紹介＋出会い→時間経過→思い出しの実践モード
- 研究25本以上の出典つき読み物
- アバター作成機能／オンライン対戦／SF物語モード
- 無料・アカウント不要・データは端末内保存

プレスキット: {APP_URL}presskit.html
Google Play: {PLAY_URL}

ぜひご確認いただけますと幸いです。

阿部健吾
"""
        with open(OUTPUT_DIR / "LAUNCH_GUIDE.md", "w", encoding="utf-8") as f:
            f.write(guide)

        print(f"Launch pack generated in {OUTPUT_DIR}/")
        for name in os.listdir(OUTPUT_DIR):
            print(f"  {name}")


if __name__ == "__main__":
    main()
