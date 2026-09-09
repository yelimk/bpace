/**
 * BPACE 백엔드 표준 공통 응답 래퍼 (Envelope Helper)
 * 
 * 프론트엔드 ApiClient Contract 100% 준수:
 * - 성공 응답: { "success": true, "data": { ... } }
 * - 실패 응답: { "success": false, "error": { "code": "...", "message": "..." } }
 */

/**
 * 성공 응답 전송
 * @param {object} res Express Response 객체
 * @param {any} data 반환할 데이터
 * @param {number} statusCode HTTP 상태 코드 (기본 200)
 */
function sendSuccess(res, data, statusCode = 200) {
  return res.status(statusCode).json({
    success: true,
    data: data
  });
}

/**
 * 실패 응답 전송
 * @param {object} res Express Response 객체
 * @param {string} code 프론트엔드 식별 에러 코드 (예: 'INVALID_CREDENTIALS', 'POOR_SIGNAL_QUALITY')
 * @param {string} message 사용자 노출용 한국어 에러 메시지
 * @param {number} statusCode HTTP 상태 코드 (기본 400)
 */
function sendError(res, code, message, statusCode = 400) {
  return res.status(statusCode).json({
    success: false,
    error: {
      code,
      message
    }
  });
}

module.exports = {
  sendSuccess,
  sendError
};
