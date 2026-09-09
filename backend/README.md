# 🚀 BPACE 백엔드 & 대회 제출/배포 마스터 명세서 (Backend README)

본 문서는 BPACE 백엔드 구축 및 대회 제출/배포를 위해 **사용자가 요구한 모든 기능과 아키텍처**를 종합 정리한 마스터 명세서입니다.

* 📖 **세부 기획 명세서**: [backend/SPECIFICATION.md](file:///c:/Users/82103/Desktop/bpace/backend/SPECIFICATION.md) (회원 등급, PPG 계산 수식, 호흡 추천, AI 분석)

---


## 📌 핵심 구축 목표 및 세부 기능

### 1. 💾 서버 DB 및 회원 데이터 보존 (Server DB & User Data)
* 로컬 저장소와 별개로 클라우드 DB(PostgreSQL/MySQL)에 회원별 정보, 측정 결과, 호흡 수행 내역을 영구 보존.
* **이메일 회원가입 (`POST /api/auth/signup`) 및 로그인 (`POST /api/auth/login`)** 지원.
* **구글 소셜 로그인 연동 (`POST /api/auth/google`)**, **게스트 로그인 (`POST /api/auth/guest`)**, **내 프로필 조회 (`GET /api/auth/me`)** API 제공.


### 2. 🔑 구글 OAuth 2.0 및 구글 캘린더(Google Calendar API) 양방향 동기화
* 구글 소셜 로그인 연동 (`POST /api/auth/google`).
* 구글 로그인 회원 대상 구글 캘린더 권한(`calendar.events`) 요청.
* 앱에서 등록한 일정을 사용자의 실제 **구글 캘린더(Google Calendar)와 양방향 자동 동기화** (`POST /api/calendar/sync`).

### 3. 🩸 서버 측 생체 파형 계산 & 🤖 AI 맞춤 분석 (Gemini / OpenAI API)
* **서버 측 심박수 & HRV 정밀 계산 (`POST /api/measurements`)**:
  * 프론트엔드 카메라에서 수집한 20초 파형 샘플 데이터(`samples`)를 서버가 받아 **서버에서 심박수(BPM), HRV(ms), 컨디션 점수를 정밀하게 계산**하여 응답.
* **호흡 완수 피드백 AI 분석 (`POST /api/ai/feedback`)**:
  * 세션 완수율, BPM 변화량을 AI 프롬프트로 전달해 호흡 맞춤 피드백 멘트 생성.
* **로그 페이지 분석 탭 AI 종합 진단 (`POST /api/ai/analyze-trend`)**:
  * 주간 HR/HRV 추이 데이터를 분석해 자율신경계 상태 및 스트레스 완화 팁 멘트 생성.

### 4. 🔔 일정 & 루틴 알림 (Local Notification & Push)
* **스마트폰 로컬 알림 (Flutter Local Notifications - 100% 무료)**:
  * 일정 시작 30분/1시간 전 긴장 완화 호흡 알림 및 매일 아침 루틴 측정 알림은 서버/인터넷 연결 필요 없이 **앱 단독 로컬 알림 기능**으로 정확히 발송.
* **[선택] FCM 원격 푸시 알림**:
  * 백엔드 공지사항이나 외부 이벤트 전송 필요 시 선택적 활용.


### 5. 🏆 대회 제출 전략 & 📱 배포/출시 가이드
* **백엔드 클라우드 배포**: Render / Railway / AWS 환경에 HTTPS 서버 및 `.env` 보안 환경 변수 적용 후 배포.
* **대회 제출용 링크 구성 전략**:
  * **메인 제출**: **`안드로이드 APK 다운로드 링크`** (카메라 및 플래시 실측용 정식 서비스)
  * **보조 제출**: **`Vercel 웹 시연 링크`** (심사위원의 빠른 화면/UI 시연용)
* **앱 배포 vs APK 파일 차이점**:
  * `APK`: 개발자 수동 테스트용 압축 파일.
  * `AAB (.aab)`: 구글 플레이 스토어(Google Play Console)에 제출하는 정식 검수용 표준 배포 파일.
* **플레이 스토어 출시 절차**: `flutter build aab --release` ➡️ Google Play Console 등록 ➡️ 구글 심사 후 정식 출시.

---

## 6. 추진 단계 로드맵

1. **1단계 (기본 환경 & DB 구축)**: 백엔드 초기화 및 PostgreSQL/MySQL 핵심 테이블 설계
2. **2단계 (서버 측 파형 계산 API)**: 파형 샘플 받아 심박수/HRV 정밀 계산하는 `/api/measurements` 구축
3. **3단계 (Google OAuth & Google Calendar API 연동)**: 구글 캘린더 양방향 일정 동기화 로직 구현
4. **4단계 (Gemini/OpenAI AI 모듈 탑재)**: 호흡 피드백 및 분석 탭 AI 분석 API 구현
5. **5단계 (클라우드 배포 & 대회 제출)**: Render/Supabase 무료 배포 및 APK / Vercel 웹 제출 링크 준비
6. **6단계 (로컬 알림 & FCM)**: 앱 내 로컬 알림(Flutter Local Notifications) 구축 및 필요시 FCM 푸시 연동

