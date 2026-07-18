// ペタネーム Cloud Functions
//
// v2.1.0時点: サーバー側の処理は不要になったため、関数は定義していない。
// 旧ルール（ナニモンジャ時代）にあった以下の関数は撤去済み:
//   - startGameOnPlayerCount: 旧オンライン対戦のゲーム開始トリガー
//   - generateSimilarNames:   Gemini(Vertex AI)によるおとり名前生成
//   - synthesizeSpeech:       ボイスモード用のTTS
//
// 新オンライン対戦（同時レース方式）はクライアント同士がFirestoreの
// rooms ドキュメントを直接読み書きするだけで完結する（トリガー不要）。
//
// ★デプロイ済みの旧関数を削除するには（課金・干渉の芽を摘む）:
//   firebase deploy --only functions --force
//   （--force で「コードに存在しない関数の削除」を承認する）
