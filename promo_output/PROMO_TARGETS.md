# PetaName プロモーション先 全リスト

## 無料アプリ掲載サイト（やるだけタダ）

### 日本
| サイト | URL | 内容 |
|--------|-----|------|
| アプリオ | https://app-liv.com/ | アプリレビュー・紹介依頼 |
| AppBank | https://www.appbank.net/ | アプリ紹介記事依頼 |
| オクトバ | https://octoba.net/ | アプリ紹介依頼 |
| アンドロイダー | https://androider.jp/ | Androidアプリ専門 |

### 英語圏
| サイト | URL | 内容 |
|--------|-----|------|
| Product Hunt | https://www.producthunt.com/ | 最重要。ローンチ日を決めて予約 |
| AlternativeTo | https://alternativeto.net/ | 「brain training」カテゴリに登録 |
| AppRagg | https://appragg.com/ | アプリ登録（無料） |
| AppAdvice | https://appadvice.com/ | iOS/Androidアプリ紹介 |
| Softpedia | https://www.softpedia.com/ | Windows/Androidアプリ登録 |
| Slant | https://www.slant.co/ | 「best brain training apps」に追加 |
| Product Hunt Ship | https://www.producthunt.com/ship | ビルド中から公開できる |

### 開発者コミュニティ
| サイト | URL | 内容 |
|--------|-----|------|
| Flutter Gems | https://fluttergems.dev/ | Flutterアプリ登録 |
| Made with Flutter | https://madewithflutter.net/ | Flutterアプリ紹介依頼 |
| It's All Widgets | https://itsallwidgets.com/ | Flutterアプリ登録（Play Store URLを貼るだけ） |

---

## SNS・コミュニティ

### 自動化済み（auto_poster.py）
| プラットフォーム | 状態 | 設定手順 |
|-----------------|------|---------|
| Mastodon | 準備完了 | `python scripts/auto_poster.py setup mastodon` |
| Bluesky | 準備完了 | `python scripts/auto_poster.py setup bluesky` |
| Twitter/X | 手動 | API有料化のため手動投稿のみ |
| Reddit | 手動 | `promo_output/launch_reddit.txt` をコピペ |
| Hacker News | 手動 | `promo_output/launch_showhn.txt` をコピペ |
| LinkedIn | 手動 | `promo_output/launch_linkedin.txt` をコピペ |

### 投稿すべきSubreddit
- r/InternetIsBeautiful
- r/selfimprovement
- r/AndroidApps
- r/androiddev
- r/cogsci（認知科学コミュニティ）
- r/nootropics（脳機能向上に関心がある層）
- r/productivity
- r/SideProject
- r/FlutterDev

---

## プレス・メディア

### 英語
| 媒体 | ピッチ対象 | メール雛形 |
|------|-----------|-----------|
| Lifehacker | 生産性アプリ紹介 | `promo_output/LAUNCH_GUIDE.md` |
| Zapier Blog | 仕事効率化アプリ | 同上 |
| BPS Research Digest | 記憶研究の実用例 | 同上 |
| Psychology Today Blog | 名前記憶の科学 | 同上 |
| TechCrunch App | アプリコーナー | 同上 |

### 日本
| 媒体 | ピッチ対象 | メール雛形 |
|------|-----------|-----------|
| ケータイWatch | アプリ紹介コーナー | `promo_output/LAUNCH_GUIDE.md` 日本語 |
| 窓の杜 | 新着アプリ | 同上 |
| AppBank | アプリレビュー | 同上 |
| アプリオ | アプリ紹介 | 同上 |
| インプレス | 複数媒体あり | 同上 |

---

## 自動化できること

### 1. 毎日自動投稿
```bash
# Mastodon + Bluesky に今日のカレンダーから自動投稿
python scripts/auto_poster.py daily
```

### 2. 一斉投稿（3本連続）
```bash
python scripts/auto_poster.py blast
```

### 3. 1本だけ投稿
```bash
python scripts/auto_poster.py post
```

### 4. Windowsタスクスケジューラに登録（毎日9時）
```powershell
# 管理者PowerShellで実行:
$action = New-ScheduledTaskAction -Execute "python" -Argument "scripts/auto_poster.py daily" -WorkingDirectory "C:\Users\tori\Downloads\nanimonjya-main\nanimonjya-main"
$trigger = New-ScheduledTaskTrigger -Daily -At 9:00AM
Register-ScheduledTask -TaskName "PetaName每日投稿" -Action $action -Trigger $trigger
```

---

## 📅 Product Hunt ローンチの手順

1. https://www.producthunt.com/ でアカウント作成
2. https://www.producthunt.com/launch で「Coming Soon」ページ作成
3. 以下の情報を入れる:
   - タグライン: "Face & name memory training game backed by cognitive science"
   - 説明: (promo_output/launch_showhn.txt を使う)
   - アイコン: web/icons/Icon-512.png
   - スクリーンショット: store_assets/screenshots/ から5枚
   - カテゴリ: Android, Web App, Education, Health & Fitness
4. ローンチ日を**火曜〜木曜**に設定（月曜は混む、金曜は見られない）
5. ローンチ前に coming-soon ページでメールを集める
6. ローンチ当日: 朝8am PTに公開 → 全SNSでシェア

---

## やることチェックリスト（優先度順）

- [ ] Product Hunt に "Coming Soon" を登録（所要5分）
- [ ] Mastodonアカウント作成＋ auto_poster 設定（所要10分）
- [ ] Blueskyアカウント作成＋ auto_poster 設定（所要10分）
- [ ] Flutter Gems / It's All Widgets に登録（所要5分、URLを貼るだけ）
- [ ] AlternativeTo に「brain training」で登録（所要5分）
- [ ] Reddit r/AndroidApps に投稿（promo_output/launch_reddit.txt から）
- [ ] Show HN に投稿（平日11am ET / 日本時間深夜0時がベスト）
- [ ] 日本のメディアにメール（LAUNCH_GUIDE.md の日本語テンプレート）
- [ ] 英語メディアにメール（LAUNCH_GUIDE.md の英語テンプレート）
- [ ] YouTube/TikTok ショート動画をもう1本作る（「Baker-Baker錯覚とは？」など）
