# 🚀 BPACE 백엔드 API & 클라우드 배포 명세서 (Backend README)

본 문서는 **BPACE 백엔드** (Node.js / Express / Prisma SQLite & PostgreSQL) 구축 내역, 100% $0 무료 인프라 방침, 전체 REST API 명세서 및 **Render 클라우드 배포 가이드**를 정리한 종합 명세서입니다.

> 💡 **핵심 가이드라인 & 운영 방침**:
> 1. 💰 **100% $0 무료 인프라 준수 (Zero-Cost Infrastructure)**: 백엔드 서버(Render Free Tier), DB(SQLite/Prisma), AI(Google AI Studio Gemini 2.0 Flash Free Tier)는 **100% 비용 발생 없는 무료 티어로 구축**되었습니다.
> 2. 🛡️ **Render 단일 배포 표준**: 카드 등록 없이 매월 750시간 100% $0 무료 웹 서비스를 제공하는 Render(렌더) 플랫폼을 단일 배포 표준으로 채택했습니다.
> 3. 📜 **오픈소스 라이선스 준수**: MIT License를 적용합니다.

---

## 🛠️ 백엔드 기술 스택 & 데이터베이스 구조

* **Runtime & Framework**: Node.js v20+ / Express.js
* **ORM & Database**: Prisma ORM / SQLite (`dev.db` - 로컬 개발) & PostgreSQL (운영 환경)
* **AI Engine**: Google AI Studio Gemini 2.0 Flash Free Tier REST API
* **Auth**: JWT (JSON Web Token) & bcryptjs Password Hashing
* **Deployment**: Render Web Service (Free Tier, `render.yaml`, `Dockerfile`)

---

## 📡 REST API 엔드포인트 종합 명세서

### 1️⃣ 서버 헬스 체크 & 시스템 모니터링 (`/api/health`)
| Method | Endpoint | 설명 | 인증 |
| :--- | :--- | :--- | :---: |
| `GET` | `/api/health` | 서버 동작 상태 및 DB 핑 연결 확인 | X |
| `GET` | `/api/health/version` | API 버전 및 라이선스 정보 반환 | X |

### 2️⃣ 인증 & 회원 관리 API (`/api/auth`)
| Method | Endpoint | 설명 | 인증 |
| :--- | :--- | :--- | :---: |
| `POST` | `/api/auth/signup` | 신규 회원 가입 | X |
| `POST` | `/api/auth/login` | 이메일/비밀번호 로그인 (JWT 발급) | X |
| `POST` | `/api/auth/google` | 구글 OAuth 소셜 로그인 처리 | X |
| `POST` | `/api/auth/guest` | 비회원 게스트 토큰 발급 | X |
| `GET` | `/api/auth/me` | 내 프로필 정보 조회 | Bearer JWT |

### 3️⃣ PPG 생체 측정 API (`/api/measurements`)
| Method | Endpoint | 설명 | 인증 |
| :--- | :--- | :--- | :---: |
| `POST` | `/api/measurements` | 20초 파형 샘플(600개) 처리 ➡️ BPM, HRV(SDNN/RMSSD), 컨디션 점수 산출 및 추천 호흡 연산 | 선택 |

### 4️⃣ 호흡 세션 기록 & 통계 API (`/api/breathing-logs`, `/api/statistics`)
| Method | Endpoint | 설명 | 인증 |
| :--- | :--- | :--- | :---: |
| `POST` | `/api/breathing-logs` | 호흡 세션 완주 기록 저장 | 선택 |
| `GET` | `/api/breathing-logs` | 사용자 최근 호흡 내역 목록 조회 | 선택 |
| `GET` | `/api/statistics/summary` | 주간/월간 생체 및 호흡 통계 요약 | 선택 |
| `GET` | `/api/statistics/daily` | 일별 생체 측정 추이 데이터 반환 | 선택 |

### 5️⃣ 일정 CRUD & 알림 연산 API (`/api/schedules`)
| Method | Endpoint | 설명 | 인증 |
| :--- | :--- | :--- | :---: |
| `GET` | `/api/schedules` | 등록된 일정 목록 조회 | 선택 |
| `POST` | `/api/schedules` | 신규 일정 등록 및 30분 전 알림 연산 | 선택 |
| `PATCH` | `/api/schedules/:id` | 일정 정보 수정 | 선택 |
| `DELETE` | `/api/schedules/:id` | 일정 삭제 | 선택 |
| `POST` | `/api/schedules/sync` | 구글 캘린더 양방향 일정 동기화 | 선택 |

### 6️⃣ Gemini 2.0 Flash AI 리포트 & 피드백 API (`/api/reports`)
| Method | Endpoint | 설명 | 인증 |
| :--- | :--- | :--- | :---: |
| `POST` | `/api/reports/analyze` | 슬롯 A: 카메라 측정 수치 기반 실시간 AI 4~5줄 심박 분석 | 선택 |
| `POST` | `/api/reports/feedback` | 슬롯 B: 호흡 완주 피드백 + [오늘의 한마디 (todaysQuote)] 실시간 생성 | 선택 |
| `GET` | `/api/reports/latest` | DB에 저장된 최근 AI 분석 리포트 조회 | 선택 |

---

## 🌐 Render 클라우드 100% $0 무료 배포 가이드

1. **GitHub 리포지토리 연동**:
   * Render Dashboard (`dashboard.render.com`) 로그인 후 **New Web Service** 클릭 및 본 `bpace` 리포지토리 선택

2. **빌드 & 실행 설정**:
   * **Environment**: `Node`
   * **Region**: `Singapore` (아시아 한국 최단 거리)
   * **Plan**: `Free` ($0/month)
   * **Build Command**: `npm install && npx prisma generate && npx prisma db push`
   * **Start Command**: `node src/server.js`

3. **환경 변수 등록 (Environment Variables)**:
   * `NODE_ENV`: `production`
   * `JWT_SECRET`: `bpace_jwt_secret_key_2026_production`
   * `GEMINI_API_KEY`: Google AI Studio에서 발급받은 무료 API 키 입력

---

## 🧪 로컬 개발 & 테스트 방법

```bash
# 1. 패키지 설치
npm install

# 2. 데이터베이스 스키마 생성
npx prisma db push

# 3. 개발 서버 실행 (기본 포트 3000)
npm run dev

# 4. 전체 API 기능 검증 스크립트 실행
node src/utils/testDeploy.js
```
