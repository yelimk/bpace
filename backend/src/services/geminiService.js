/**
 * BPACE Gemini REST API 통신 모듈
 * 
 * Google AI Studio Gemini Flash Free Tier (100% 무료)
 * - API 키 누락 또는 네트워크 통신 실패 시 표준 에러 객체(AI_SERVICE_UNAVAILABLE)를 반환합니다.
 */

/**
 * Gemini API 호출 함수
 * @param {string} promptText 작성된 시스템 프롬프트
 * @returns {Promise<object>} Gemini AI가 생성한 JSON 결과 객체
 */
async function generateAiContent(promptText) {
  const apiKey = process.env.GEMINI_API_KEY;

  if (!apiKey || apiKey === 'YOUR_GEMINI_API_KEY' || apiKey.trim() === '') {
    const error = new Error('GEMINI_API_KEY가 설정되어 있지 않습니다.');
    error.code = 'AI_SERVICE_UNAVAILABLE';
    error.userMessage = '현재 AI 분석을 불러올 수 없습니다. 잠시 후 다시 시도해 주세요.';
    throw error;
  }

  // 최고 퀄리티를 보장하는 최신 Flash 정예 모델만 유지 (저품질 경량 모델 제외)
  const modelCandidates = [
    'gemini-3.8-flash',
    'gemini-3.6-flash'
  ];

  let lastError = null;

  for (const model of modelCandidates) {
    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          contents: [
            {
              parts: [{ text: promptText }]
            }
          ],
          generationConfig: {
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 1000,
            responseMimeType: "application/json"
          }
        })
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`[Gemini API (${model}) Http Error]:`, response.status, errorText);
        lastError = new Error(`Gemini API (${model}) HTTP Error: ${response.status}`);
        continue;
      }

      const data = await response.json();
      const candidate = data?.candidates?.[0];
      const textOutput = candidate?.content?.parts?.[0]?.text;

      if (!textOutput) {
        throw new Error('Gemini API 응답 텍스트가 비어있습니다.');
      }

      // JSON 파싱 (마크다운 파싱 안전 처리)
      const cleanedText = textOutput.replace(/```json/g, '').replace(/```/g, '').trim();
      const jsonResult = JSON.parse(cleanedText);

      return jsonResult;
    } catch (err) {
      lastError = err;
    }
  }

  console.error('[GeminiService Error]:', lastError?.message || lastError);
  const apiError = new Error(lastError?.message || 'Gemini API 통신 실패');
  apiError.code = 'AI_SERVICE_UNAVAILABLE';
  apiError.userMessage = '현재 AI 분석을 불러올 수 없습니다. 잠시 후 다시 시도해 주세요.';
  throw apiError;
}

module.exports = {
  generateAiContent
};
