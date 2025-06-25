const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const firestore = admin.firestore();

// Google Cloud Text-to-Speech クライアントをインポート
const { TextToSpeechClient } = require('@google-cloud/text-to-speech');
const ttsClient = new TextToSpeechClient();

// ルームのプレイヤー数が揃ったときにゲームを開始する例
// 実際には、プレイヤーが「ゲーム開始」ボタンを押すなど、明示的なトリガーの方が良い場合もあります。
exports.startGameOnPlayerCount = functions.firestore
    .document('rooms/{roomId}')
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const previousData = change.before.data();

        // 状態がwaitingで、プレイヤー数が変化し、かつゲーム開始に必要な人数に達した場合
        if (newData.status === 'waiting' &&
            newData.playerCount !== previousData.playerCount &&
            newData.playerCount >= 2 && // 例えば2人以上で開始
            !newData.gameStarted) { // gameStartedフラグを追加して複数回トリガーされないようにする

            const roomId = context.params.roomId;
            const imageUrls = newData.imageUrls; // ロビーでアップロードされた画像

            if (!imageUrls || imageUrls.length < 12) {
                console.log(`Room ${roomId} does not have enough images.`);
                return null;
            }

            // デッキを生成してシャッフル
            let fullDeck = [];
            for (let url of imageUrls) {
                for (let i = 0; i < 5; i++) {
                    fullDeck.push(url);
                }
            }
            // 配列をシャッフルするシンプルな関数
            function shuffleArray(array) {
                for (let i = array.length - 1; i > 0; i--) {
                    const j = Math.floor(Math.random() * (i + 1));
                    [array[i], array[j]] = [array[j], array[i]]; // Swap
                }
                return array;
            }
            fullDeck = shuffleArray(fullDeck);

            // プレイヤーの初期スコアを決定（ここでは仮にプレイヤーIDを自動生成）
            const initialScores = {};
            // 実際には、ルーム参加時にFirestoreに記録されたプレイヤーIDリストを使う
            // 例: newData.players.forEach(playerId => initialScores[playerId] = 0);
            for (let i = 0; i < newData.playerCount; i++) {
                initialScores[`player_${i + 1}`] = 0;
            }


            await firestore.collection('rooms').doc(roomId).update({
                status: 'playing',
                deck: fullDeck,
                scores: initialScores,
                fieldCards: [],
                seenImages: [],
                currentCard: null,
                isFirstAppearance: true,
                canSelectPlayer: false,
                turnCount: 0,
                gameStarted: true, // ゲームが開始されたことを示すフラグ
            });
            console.log(`Game started for room: ${roomId}`);

            // 最初のカードをめくる処理をトリガー
            await firestore.runTransaction(async (transaction) => {
                const roomDoc = await transaction.get(firestore.collection('rooms').doc(roomId));
                let currentDeck = roomDoc.data().deck;
                if (currentDeck.length > 0) {
                    const firstCard = currentDeck.pop();
                    transaction.update(firestore.collection('rooms').doc(roomId), {
                        currentCard: firstCard,
                        deck: currentDeck,
                        turnCount: 1,
                        isFirstAppearance: true, // 最初のカードは必ず初登場
                        canSelectPlayer: false,
                        seenImages: [firstCard], // 初めての画像として記録
                    });
                }
            });

        }
        return null;
    });

// 新しい Cloud Function: テキストを音声に変換して返す
exports.synthesizeSpeech = functions.https.onCall(async (data, context) => {
    // リクエストからテキストを取得
    const text = data.text;
    if (!text) {
        throw new functions.https.HttpsError('invalid-argument', 'テキストが指定されていません。');
    }

    // 音声合成のリクエストを構築
    const request = {
        input: { text: text },
        // ここで声の設定（言語、性別、声の種類など）をカスタマイズできます。
        // 詳細はこちらを参照: https://cloud.google.com/text-to-speech/docs/voices
        voice: { languageCode: 'ja-JP', name: 'ja-JP-Wavenet-B', ssmlGender: 'FEMALE' }, // 例: 日本語、Wavenet-B、女性の声
        audioConfig: { audioEncoding: 'MP3' }, // MP3形式で音声データを取得
    };

    try {
        // Text-to-Speech API を呼び出し
        const [response] = await ttsClient.synthesizeSpeech(request);
        // 音声データをBase64エンコードしてクライアントに返します
        const audioContent = response.audioContent.toString('base64');
        return { audioContent: audioContent };
    } catch (error) {
        console.error('音声合成エラー:', error);
        throw new functions.https.HttpsError('internal', '音声合成に失敗しました。', error.message);
    }
});