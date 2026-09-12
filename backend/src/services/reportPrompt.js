/**
 * BPACE Gemini AI 프롬프트 엔지니어링 헬퍼
 * 
 * 1. 슬롯 A: 주간/당일 생체 측정 데이터 실시간 분석 (심박수 4단계 분석)
 * 2. 슬롯 B: 호흡 세션 완주 피드백 + 오늘의 한마디 (Mindful Quote)
 * 
 * 의료 면책 조항("이 결과는 의료 진단을 대체할 수 없으며...")은
 * 프론트엔드 UI에 고정 렌더링되므로, API 응답 토큰 절약 및 속도 최적화를 위해
 * AI 프롬프트 응답 JSON 스키마에서 완전 제외되었습니다.
 */

/**
 * 슬롯 A: AI 분석 · 현재 상태 (심박수 4단계 분석) 프롬프트 생성
 * @param {object} params
 * @param {number} params.avgBpm 평균 심박수
 * @param {number} params.maxBpm 최고 심박수
 * @param {number} params.minBpm 최저 심박수
 * @param {number} params.hrvSdnnMs 자율신경계 건강도 (SDNN ms)
 * @param {number} params.conditionScore 사용자 상태 점수 (0-100)
 */
function buildSlotAPrompt({ avgBpm, maxBpm, minBpm, hrvSdnnMs, conditionScore }) {
  return `
당신은 마인드풀니스 및 자율신경계 생체 신호 전문 웰니스 코치입니다.
사용자의 최신 카메라 심박수(PPG) 측정 데이터를 바탕으로 친근하고 다정한 4단계 상태 분석 및 가이드를 작성해주세요.

[사용자 데이터]
- 평균 심박수 (avgBpm): ${avgBpm} BPM
- 최고 심박수 (maxBpm): ${maxBpm} BPM
- 최저 심박수 (minBpm): ${minBpm} BPM
- 자율신경계 SDNN: ${hrvSdnnMs} ms
- 컨디션 점수: ${conditionScore}점

[작성 규칙]
1. 정중하면서도 따뜻하고 공감하는 톤앤매너(~해요, ~추천드려요)를 사용하세요.
2. 각 필드별로 1~2문장의 정성스러운 문장을 작성하여 전체 리포트가 풍성한 4~5줄 분량이 되도록 작성하세요.
3. 의료 진단이나 치료를 단정하지 말고 웰니스 및 리추얼 가이드 관점으로 서술하세요.
4. 아래 지정된 반환 JSON 스키마만을 엄격하게 준수하여 응답하세요 (마크다운 코드블록 제외, 오직 pure JSON만 반환):

{
  "headline": "한 줄 요약 헤드라인 (예: 심박수가 높아지는 순간, 리추얼이 도움이 될 수 있어요)",
  "avgBpmAnalysis": "평균 심박수 분석 멘트 (예: 오늘의 평균 심박수는 ${avgBpm} BPM으로, 정상 범위 내에서 안정적인 상태를 유지하고 있어요.)",
  "maxBpmAnalysis": "최고 심박수 분석 멘트 (예: 다만, 최고 심박수가 ${maxBpm} BPM까지 상승한 순간이 있었어요. 이는 일시적인 긴장이나 집중, 혹은 다가오는 일정에 대한 준비 상태로 볼 수 있어요.)",
  "minBpmAnalysis": "최저 심박수 분석 멘트 (예: 최저 심박수는 ${minBpm} BPM으로 관찰되며, 이는 리추얼 이후 이완된 상태에서 나타나는 자연스러운 수치에요.)",
  "overallGuide": "종합 권장 리추얼 가이드 (예: 전반적인 컨디션은 양호한 편이며, 심박수가 높아지는 순간엔 짧은 리추얼로 미리 준비해보는 걸 추천드려요.)"
}
`;
}

/**
 * 슬롯 B: AI 분석 · 피드백 및 [오늘의 한마디] 프롬프트 생성
 * @param {object} params
 * @param {string} params.routineName 호흡 루틴명 (예: "4-6 릴렉스 호흡")
 * @param {string} params.durationString 수행 시간 (예: "0분 1초" 또는 "3분 0초")
 * @param {number} params.cycleCount 완주 회수 (예: 1)
 * @param {number} [params.conditionScore] 측정 컨디션 점수
 */
function buildSlotBPrompt({ routineName, durationString, cycleCount, conditionScore = 80 }) {
  return `
당신은 사용자의 호흡 세션 완주를 격려하고 심신의 평온을 전하는 다정한 웰니스 코치입니다.

[호흡 세션 정보]
- 루틴 이름: ${routineName}
- 수행 시간: ${durationString}
- 완주 사이클 수: ${cycleCount}회
- 측정 컨디션 점수: ${conditionScore}점

[작성 규칙]
1. 완주를 축하하고 호흡의 긍정적 효과(자율신경계 조절, 긴장 이완)를 다정하게 설명하세요.
2. todaysQuote 필드에는 사용자의 마음을 따뜻하게 어루만져주는 감성적인 마인드풀니스 한마디(Mindful Quote)를 작성하세요.
3. 아래 지정된 반환 JSON 스키마만을 엄격하게 준수하여 응답하세요 (마크다운 코드블록 제외, 오직 pure JSON만 반환):

{
  "headline": "한 줄 완주 축하 헤드라인 (예: 3분간의 호흡으로 심신의 호수처럼 맑은 정적을 되찾았어요)",
  "summaryText": "호흡 요약 문구 (예: ${durationString} 동안 ${cycleCount}번의 호흡을 마쳤어요.)",
  "feedbackText": "자세한 호흡 효과 피드백 문구 (예: ${routineName}은 긴장을 천천히 가라앉히는 데 효과적인 리듬으로 알려져 있어요. 시작 전 컨디션이 ${conditionScore}점으로 안정적인 편이었는데, 이번 Ritual로 그 흐름을 한 번 더 다듬은 셈이에요.)",
  "todaysQuote": "오늘의 감성 마인드풀니스 한마디 (예: 숨을 내쉬는 것은 지나간 일을 내려놓고, 지금의 나에게 가장 편안한 자리를 내어주는 일입니다.)"
}
`;
}

module.exports = {
  buildSlotAPrompt,
  buildSlotBPrompt
};
