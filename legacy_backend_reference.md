# 📜 기존 백엔드(Spring Boot) 참조 문서 (Legacy Backend Reference)

본 문서는 삭제된 이전 Java/Spring Boot 백엔드 프로젝트의 **DB 스키마**, **API 규격** 및 **구조 사양** 정리 문서입니다.
추후 새 백엔드 구축이나 참고 시 활용할 수 있도록 보존되어 있습니다.

---

## 1. DB 스키마 규격 (Flyway Migration 기준)

### 1) `users` (사용자 테이블)
* `id`: BIGINT (PK, Auto Increment)
* `email`: VARCHAR(255) (Unique, Nullable)
* `password`: VARCHAR(255) (Nullable)
* `nickname`: VARCHAR(100) (NOT NULL)
* `auth_provider`: VARCHAR(20) (DEFAULT 'LOCAL', 'GOOGLE', 'APPLE', 'KAKAO' 등)
* `created_at` / `updated_at`: DATETIME

### 2) `revoked_tokens` (로그아웃 / 토큰 블랙리스트)
* `id`: BIGINT (PK, Auto Increment)
* `jti`: VARCHAR(255) (NOT NULL, Unique)
* `expiration`: DATETIME (NOT NULL)
* `revoked_at`: DATETIME

### 3) `breathing_session` (호흡 운동/세션 기록)
* `id`: BIGINT (PK, Auto Increment)
* `user_id`: BIGINT (FK -> `users.id`)
* `preset_id`: VARCHAR(50) (NOT NULL, 호흡 모드/프리셋 ID)
* `preset_title`: VARCHAR(100)
* `target_duration_seconds`: INT (목표 시간)
* `actual_duration_seconds`: INT (실제 수행 시간)
* `completed`: BOOLEAN (완료 여부)
* `started_at` / `ended_at`: DATETIME
* 지표 데이터: `bpm_change`, `rmssd_change`, `sdnn_change`, `stress_score_change` 등

### 4) `measurement` (호흡/PPG 파형 측정 기록)
* `id`: BIGINT (PK, Auto Increment)
* `user_id`: BIGINT (FK -> `users.id`, Nullable - 비회원 지원)
* `measured_at`: DATETIME (NOT NULL)
* `duration_seconds`: INT
* `bpm`: DOUBLE
* `rmssd`: DOUBLE
* `sdnn`: DOUBLE
* `stress_score` / `condition_score`: INT (상태 점수)
* `quality`: VARCHAR(20) ('EXCELLENT', 'GOOD', 'FAIR', 'POOR' 등)
* `notes`: TEXT

### 5) `ai_report` (AI 호흡 분석 리포트)
* `id`: BIGINT (PK, Auto Increment)
* `user_id`: BIGINT (FK -> `users.id`)
* `start_date` / `end_date`: DATE (주간/기간 리포트 범위)
* `summary`: TEXT (AI 요약)
* `recommendations`: TEXT (AI 추천사항)
* `created_at`: DATETIME

### 6) `calendar_event` & `event_push_log` (일정 및 알림 연동)
* Google/Apple 캘린더 이벤트 동기화 및 호흡 알림 이력 관리

### 7) `user_device` (FCM 푸시 알림 디바이스 토큰)
* `user_id`: BIGINT (FK -> `users.id`)
* `fcm_token`: VARCHAR(512)
* `device_type`: VARCHAR(20) ('IOS', 'ANDROID' 등)

---

## 2. API 엔드포인트 규격

| 도메인 | HTTP Method | Endpoint | 설명 |
| :--- | :--- | :--- | :--- |
| **Auth** | `POST` | `/api/auth/signup` | 일반 회원가입 |
| | `POST` | `/api/auth/login` | 일반 로그인 (JWT 발급) |
| | `POST` | `/api/auth/social` | 소셜 로그인 (Firebase/ID Token 검증) |
| | `POST` | `/api/auth/logout` | 로그아웃 (토큰 블랙리스트 처리) |
| | `DELETE` | `/api/auth/withdraw` | 회원 탈퇴 |
| **Session** | `POST` | `/api/sessions` | 호흡 세션 시작/완료 기록 저장 |
| | `GET` | `/api/sessions` | 호흡 세션 이력 조회 |
| **Measurement**| `POST` | `/api/measurements` | 측정 결과 저장 |
| | `POST` | `/api/measurements/analyze` | 비회원/게스트 파형 분석 요청 |
| | `GET` | `/api/measurements` | 측정 이력 목록 조회 |
| **Statistics** | `GET` | `/api/statistics/summary` | 기간별 통계 요약 (평균 BPM, 스트레스 등) |
| | `GET` | `/api/statistics/daily` | 일별 상세 지표 조회 |
| **Report** | `GET` | `/api/reports/weekly` | 주간 AI 리포트 조회 |
| | `POST` | `/api/reports/weekly` | 주간 AI 리포트 생성을 요청 (Gemini/OpenAI) |
| **Device** | `POST` | `/api/devices` | FCM 디바이스 토큰 등록 |
| | `DELETE` | `/api/devices` | FCM 디바이스 토큰 삭제 |
| **Calendar** | `POST` | `/api/calendar/sync` | 캘린더 일정을 동기화 |
| | `GET/POST` | `/api/calendar/events` | 캘린더 이벤트 조회 / 추가 |
| **Breathing** | `GET` | `/api/breathing/presets` | 호흡 운동 프리셋 목록 조회 |
