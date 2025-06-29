const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const firestore = admin.firestore();

const { VertexAI } = require('@google-cloud/vertexai');

// Vertex AI の初期化
const projectId = 'nanimonjya'; // ★あなたのプロジェクトIDに置き換えてください★
const location = 'us-central1'; // ★Vertex AIが利用可能なリージョンを選択してください★ (例: us-central1, asia-northeast1など)
const vertex_ai = new VertexAI({ project: projectId, location: location });

// Gemini Pro モデルの初期化 (テキスト生成用)
const model = 'gemini-2.0-flash-lite-001'
const generativeModel = vertex_ai.preview.getGenerativeModel({ // ★修正された行★
    model: model,
});


// ルームのプレイヤー数が揃ったときにゲームを開始する例
exports.startGameOnPlayerCount = functions.firestore
    .document('rooms/{roomId}')
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const previousData = change.before.data();

        // 状態がwaitingで、プレイヤー数が変化し、かつゲーム開始に必要な人数に達した場合
        if (newData.status === 'waiting' &&
            newData.players && newData.players.length !== (previousData.players ? previousData.players.length : 0) && // players配列の長さで変化を検知
            newData.players.length >= 2 && // 例えば2人以上で開始
            !newData.gameStarted) {

            const roomId = context.params.roomId;
            const imageUrls = newData.imageUrls;

            if (!imageUrls || imageUrls.length < 12) {
                console.log(`Room ${roomId} does not have enough images.`);
                return null;
            }

            let fullDeck = [];
            for (let url of imageUrls) {
                for (let i = 0; i < 5; i++) {
                    fullDeck.push(url);
                }
            }
            function shuffleArray(array) {
                for (let i = array.length - 1; i > 0; i--) {
                    const j = Math.floor(Math.random() * (i + 1));
                    [array[i], array[j]] = [array[j], array[i]];
                }
                return array;
            }
            fullDeck = shuffleArray(fullDeck);

            const initialScores = {};
            newData.players.forEach(playerId => {
                initialScores[playerId] = 0;
            });

            // プレイヤーの順番をシャッフルして設定
            const playerIdsForOrder = [...newData.players]; // コピーを作成
            const shuffledPlayerOrder = shuffleArray(playerIdsForOrder); // シャッフル

            await firestore.collection('rooms').doc(roomId).update({
                status: 'playing',
                deck: fullDeck,
                scores: initialScores,
                fieldCards: [],
                seenImages: [],
                characterNames: {},
                currentCard: null,
                isFirstAppearance: true,
                canSelectPlayer: false,
                turnCount: 0,
                gameStarted: true,
                playerOrder: shuffledPlayerOrder, // プレイヤーの順番を保存
                currentPlayerIndex: 0, // 最初のプレイヤーのインデックス
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
                        isFirstAppearance: true,
                        canSelectPlayer: false,
                        seenImages: admin.firestore.FieldValue.arrayUnion(firstCard),
                    });
                }
            });
        }
        return null;
    });

// テキストを音声に変換して返す関数
exports.synthesizeSpeech = functions.https.onCall(async (data, context) => {
    const text = data.text;
    if (!text) {
        throw new functions.https.HttpsError('invalid-argument', 'テキストが指定されていません。');
    }

    const { TextToSpeechClient } = require('@google-cloud/text-to-speech');
    const ttsClient = new TextToSpeechClient();

    const request = {
        input: { text: text },
        voice: { languageCode: 'ja-JP', name: 'ja-JP-Wavenet-B', ssmlGender: 'FEMALE' },
        audioConfig: { audioEncoding: 'MP3' },
    };

    try {
        const [response] = await ttsClient.synthesizeSpeech(request);
        const audioContent = response.audioContent.toString('base64');
        return { audioContent: audioContent };
    } catch (error) {
        console.error('音声合成エラー:', error);
        throw new functions.https.HttpsError('internal', '音声合成に失敗しました。', error.message);
    }
});


// テキストと文字種（英語、ひらがな、漢字など）に基づいて似た名前を生成する関数
exports.generateSimilarNames = functions.https.onCall(async (data, context) => {
    const originalName = data.originalName;
    const scriptType = data.scriptType;
    const numToGenerate = data.numToGenerate || 4;

    console.log(`[generateSimilarNames] Function started. Original: ${originalName}, Script: ${scriptType}, Num: ${numToGenerate}`); // ★追加★

    if (!originalName || typeof originalName !== 'string') {
        throw new functions.https.HttpsError('invalid-argument', 'originalName (string) is required.');
    }
    if (!scriptType || typeof scriptType !== 'string') {
        throw new functions.https.HttpsError('invalid-argument', 'scriptType (string) is required.');
    }

    try {
        let prompt;
        // プロンプトエンジニアリングで文字種を指示し、結果をカンマ区切りで要求する
        if (scriptType === 'hiragana') {
            prompt = `「${originalName}」というひらがなの名前を基に、似た響きや雰囲気を持つひらがなの名前を${numToGenerate}個生成してください。結果はカンマ区切りで、余計な説明や箇条書きマークは含めないでください。例: 名前A,名前B,名前C`;
        } else if (scriptType === 'kanji') {
            prompt = `「${originalName}」という漢字の名前を基に、似た雰囲気や意味を持つ漢字の名前を${numToGenerate}個生成してください。結果はカンマ区切りで、余計な説明や箇条書きマークは含めないでください。例: 名前A,名前B,名前C`;
        } else if (scriptType === 'english') {
            prompt = `Based on the English name "${originalName}", generate ${numToGenerate} similar-sounding or stylistically similar English names. List them as a comma-separated string. No extra explanations or bullet points. Example: NameA,NameB,NameC`;
        } else if (scriptType === 'katakana') {
            prompt = `「${originalName}」というカタカナの名前を基に、似た響きや雰囲気を持つカタカナの名前を${numToGenerate}個生成してください。結果はカンマ区切りで、余計な説明や箇条書きマークは含めないでください。例: 名前A,名前B,名前C`;
        }
        else {
            prompt = `「${originalName}」という名前を基に、似た響きや雰囲気を持つ名前を${numToGenerate}個生成してください。結果はカンマ区切りで、余計な説明や箇条書きマークは含めないでください。例: 名前A,名前B,名前C`;
        }

        console.log(`[generateSimilarNames] Prompt: ${prompt}`); // ★追加★

        const request = {
            contents: [{ role: 'user', parts: [{ text: prompt }] }],
        };

        const result = await generativeModel.generateContent(request);
        const response = result.response;
        const generatedText = response.candidates[0].content.parts[0].text;
        console.log(`[generateSimilarNames] Raw response from Gemini: ${generatedText}`); // ★追加★

        let generatedNames = generatedText
            .split(',')
            .map(name => name.trim())
            .filter(name => name.length > 0 && name.length <= 8 && name !== originalName); // 空でない、8文字以内、元の名前と異なるものだけフィルター
        
        console.log(`[generateSimilarNames] Parsed names before fallback: ${generatedNames}`); // ★追加★

        // 期待する数に満たない場合は、フォールバックとして適当な名前を追加する
        // AIの生成が完璧でないことを考慮し、ユニークなダミー名を追加
        const fallbackNames = ['モコ', 'ピコ', 'フワ', 'ギザ', 'ポム', 'クルル', 'ニャー', 'ハニャ', 'ワンダー', 'ミラクル']; // ダミー名リスト
        let fallbackIndex = 0;
        while (generatedNames.length < numToGenerate) {
            const dummyName = fallbackNames[fallbackIndex % fallbackNames.length];
            if (!generatedNames.includes(dummyName)) { // 重複しないように
                generatedNames.push(dummyName);
            }
            fallbackIndex++;
            if (fallbackIndex > fallbackNames.length * 2) { // 無限ループ防止
                break;
            }
        }

        // 期待する数よりも多い場合は切り詰める
        if (generatedNames.length > numToGenerate) {
            generatedNames = generatedNames.slice(0, numToGenerate);
        }

        console.log(`[generateSimilarNames] Final names to return: ${generatedNames}`); // ★追加★
        return { similarNames: generatedNames };

    } catch (error) {
        console.error('[generateSimilarNames] Error in try block:', error); // ★既存のエラーログを強化★
        throw new functions.https.HttpsError('internal', '名前の生成に失敗しました。', error.message);
    }
});