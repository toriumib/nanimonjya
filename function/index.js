const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const firestore = admin.firestore();

const { VertexAI } = require('@google-cloud/vertexai');

// Vertex AI の初期化
const projectId = 'nanimonjya'; // ★あなたのプロジェクトIDに置き換えてください★
const location = 'us-central1'; // ★Vertex AIが利用可能なリージョンを選択してください★
const vertex_ai = new VertexAI({ project: projectId, location: location });

// Gemini Pro モデルの初期化 (テキスト生成用)
const model = 'gemini-2.0-flash-lite-001';
const generativeModel = vertex_ai.preview.getGenerativeModel({
    model: model,
});


// ルームのプレイヤー数が揃い、全員が準備完了したらゲームを開始する
exports.startGameOnPlayerCount = functions.firestore
    .document('rooms/{roomId}')
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const previousData = change.before.data(); // 以前のデータも引き続き比較に使う

        const roomId = context.params.roomId;

        // ゲーム開始条件をチェック
        // 1. ルームが 'waiting' ステータスであること
        // 2. まだゲームが始まっていないこと
        // 3. プレイヤーが2人以上いること
        // 4. 全ての参加プレイヤーが readyPlayerIds に含まれていること (全員が準備完了)
        if (newData.status === 'waiting' &&
            !newData.gameStarted &&
            newData.players && newData.players.length >= 2 && // 最低2人
            newData.readyPlayerIds && newData.readyPlayerIds.length === newData.players.length && // 全員準備完了
            // readyPlayerIds の数が変化したとき、または players の数が変化したときにトリガー
            (newData.readyPlayerIds.length !== (previousData.readyPlayerIds ? previousData.readyPlayerIds.length : 0) ||
             newData.players.length !== (previousData.players ? previousData.players.length : 0))
            ) {

            // ゲーム開始に必要な画像が12枚あるかチェック
            const imageUrls = newData.imageUrls;
            if (!imageUrls || imageUrls.length < 12) {
                console.log(`Room ${roomId} does not have enough images (${imageUrls ? imageUrls.length : 0}/12). Game cannot start.`);
                // 必要に応じてクライアントにエラー通知する処理を追加
                return null;
            }

            // デッキを生成してシャッフル (既存ロジック)
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

            // プレイヤーの初期スコアを決定 (既存ロジック)
            const initialScores = {};
            newData.players.forEach(playerId => {
                initialScores[playerId] = 0;
            });

            // プレイヤーの順番をシャッフルして設定 (既存ロジック)
            const playerIdsForOrder = [...newData.players];
            const shuffledPlayerOrder = shuffleArray(playerIdsForOrder);

            await firestore.collection('rooms').doc(roomId).update({
                status: 'playing', // ステータスを「プレイ中」に
                deck: fullDeck,
                scores: initialScores,
                fieldCards: [],
                seenImages: [],
                characterNames: {},
                currentCard: null,
                isFirstAppearance: true,
                canSelectPlayer: false,
                turnCount: 0,
                gameStarted: true, // ゲームが開始されたことを示すフラグ
                playerOrder: shuffledPlayerOrder, // プレイヤーの順番を保存
                currentPlayerIndex: 0, // 最初のプレイヤーのインデックス
                playersAttemptedCurrentCard: {}, // 現在のカードで回答済みのプレイヤーを記録
                readyPlayerIds: [], // ゲーム開始時に準備完了状態をリセット
                displayDelayCompleteTimestamp: null, 
                lastNamedCharacterData: null,
            });
            console.log(`Game started for room: ${roomId}`);

            // 最初のカードをめくる処理をトリガー (既存ロジック)
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
            return null;
        }
        console.log(`Room ${roomId}: Not all conditions met for game start. Current players: ${newData.players ? newData.players.length : 0}, Ready: ${newData.readyPlayerIds ? newData.readyPlayerIds.length : 0}.`);
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

    console.log(`[generateSimilarNames] Function started. Original: ${originalName}, Script: ${scriptType}, Num: ${numToGenerate}`);

    if (!originalName || typeof originalName !== 'string') {
        throw new functions.https.HttpsError('invalid-argument', 'originalName (string) is required.');
    }
    if (!scriptType || typeof scriptType !== 'string') {
        throw new functions.https.HttpsError('invalid-argument', 'scriptType (string) is required.');
    }

    try {
        let prompt;
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

        console.log(`[generateSimilarNames] Prompt: ${prompt}`);

        const request = {
            contents: [{ role: 'user', parts: [{ text: prompt }] }],
        };

        const result = await generativeModel.generateContent(request);
        const response = result.response;
        const generatedText = response.candidates[0].content.parts[0].text;
        console.log(`[generateSimilarNames] Raw response from Gemini: ${generatedText}`);

        let generatedNames = generatedText
            .split(',')
            .map(name => name.trim())
            .filter(name => name.length > 0 && name.length <= 8 && name !== originalName);
        
        console.log(`[generateSimilarNames] Parsed names before fallback: ${generatedNames}`);

        const fallbackNames = ['モコ', 'ピコ', 'フワ', 'ギザ', 'ポム', 'クルル', 'ニャー', 'ハニャ', 'ワンダー', 'ミラクル'];
        let fallbackIndex = 0;
        while (generatedNames.length < numToGenerate) {
            const dummyName = fallbackNames[fallbackIndex % fallbackNames.length];
            if (!generatedNames.includes(dummyName)) {
                generatedNames.push(dummyName);
            }
            fallbackIndex++;
            if (fallbackIndex > fallbackNames.length * 2) {
                break;
            }
        }

        if (generatedNames.length > numToGenerate) {
            generatedNames = generatedNames.slice(0, numToGenerate);
        }

        console.log(`[generateSimilarNames] Final names to return: ${generatedNames}`);
        return { similarNames: generatedNames };

    } catch (error) {
        console.error('[generateSimilarNames] Error in try block:', error);
        throw new functions.https.HttpsError('internal', '名前の生成に失敗しました。', error.message);
    }
});