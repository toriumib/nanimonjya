# COMMIT★STAR — プロトタイプ

Gitの仕組みを冒険で学ぶ、近未来SF知育ゲームのプロトタイプ。
「新しいコマンドを覚える＝新しい移動能力を得る」メトロイドヴァニア型の構成。

## 何で作ってあるか

素の HTML / CSS / JavaScript（ビルド不要・依存ゼロ・全部で約1,500行）。
プロトタイプの目的は「触って面白いか」を最速で判定することなので、
フレームワークもバンドラも入れていない。そのままVercelに置ける。

コミットグラフの描画は SVG。Canvas と違って要素ごとにCSSアニメーションが
かけられるので、「記録結晶が生える」演出が素直に書ける。

## 設計の核

**本物の git は動かさない。** コミットDAG / refs / HEAD / index / working tree を
`engine.js` に自前で持つ。理由：

- どの操作でも巻き戻せる（教育ゲームでは必須）
- 内部状態を全部画面に出せる（Gitが分かりにくいのは状態が見えないから）
- ブラウザだけで完結する
- 後で Flutter などに移植する場合、このモデルをそのまま写せば挙動が変わらない

## ファイル構成

| ファイル | 役割 |
|---|---|
| `engine.js` | Gitモデルのシミュレータ。DOMに一切触らない純粋なロジック |
| `stages.js` | 章（ステージ）定義。setup / mission / goal / hints |
| `ui.js` | DOM描画・SVGグラフ・章進行 |
| `style.css` | ネオンサイバーのビジュアル |
| `index.html` | 画面の骨格 |

## 実装済みのコマンド

`status` `add` `commit` `log` `branch` `switch` `checkout` `merge`（fast-forward / 3-way / コンフリクト）
`resolve` `reset --hard` `reflog` `cherry-pick` `revert` `stash` `tag` `help`

rev の指定は `HEAD` `HEAD~2` `HEAD@{1}` ブランチ名・ハッシュの前方一致に対応。

## 章構成

| 章 | 舞台 | 習得 | 山場 |
|---|---|---|---|
| CH.1 | 記録の間 | add / commit | 記録した瞬間だけが永遠になる |
| CH.2 | 時渡りの回廊 | log / checkout / HEAD | 過去へ飛び、detached HEAD を体験 |
| CH.3 | 分岐の樹海 | branch / switch | 分けてから作る |
| CH.4 | 融合塔 | merge | fast-forward の意味が分かる |
| CH.5 | 干渉領域 ⚔ | コンフリクト解決 | 「どちらを現実にするか」は人間が決める |
| CH.6 | 消滅の谷 ⚔ | reset --hard / reflog | 全財宝を失う → reflogで復活 |
| CH.7 | 禁術書庫 | cherry-pick / revert | 歴史は消さない、打ち消す記録を積む |
| FREE | サンドボックス | 全コマンド | 自由に実験 |

## ローカルで動かす

ビルド不要。`index.html` をブラウザで開くだけ。

```
python3 -m http.server 8000    # もしくは file:// で直接開いてもよい
```

## テスト

`engine.js` と `stages.js` は DOM に依存しないので、Node からそのまま実行できる。

```js
global.GitEngine = require('./engine.js');
const { STAGES } = require('./stages.js');
// setup → コマンド列を exec → goal() が true になるかを検証
```

## 名称について

「Git」は Software Freedom Conservancy の商標のため、製品名には含めていない
（説明文で「Gitの仕組みが学べる」と書く方針）。ビジュアル・文言はすべてオリジナル。
