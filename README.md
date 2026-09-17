# BPACE

스마트폰 카메라 PPG 센서 기반 심박수·컨디션 측정 및 맞춤형 호흡 케어 웰니스 플랫폼

---

## 배포 링크 (Deployment)

| 서비스 | URL |
| :--- | :--- |
| 웹 (Vercel) | https://bpace.vercel.app |
| 백엔드 API (Render) | https://bpace.onrender.com |
| GitHub 저장소 | https://github.com/yelimk/bpace |

---

## 프로젝트 소개

BPACE는 별도의 웨어러블 기기 없이 **스마트폰 카메라(PPG, 광혈류 측정)** 만으로 사용자의 심박수(BPM) 및 심박변이도(HRV)를 정밀 측정하고, 측정된 생체 데이터와 구글 캘린더 일정 상황을 결합하여 최적의 맞춤형 호흡 루틴과 Gemini 2.0 Flash AI 분석 리포트를 제공하는 웰니스 케어 솔루션입니다.

---

## 주요 기능 (Key Features)

### 1. 스마트폰 카메라 PPG 생체 측정
- 손가락을 카메라 렌즈 및 플래시에 밀착하여 20초간 초당 30프레임(총 600샘플) 신호 수집
- 심박수(BPM), 심박변이도(HRV SDNN / RMSSD), 컨디션 점수(0~100점) 자동 산출
- 신호 품질(`good` / `poor`) 자동 판별

### 2. 의학 근거 기반 5대 카테고리 8종 호흡 루틴

| 카테고리 | 루틴명 | 특징 |
| :---: | :--- | :--- |
| 진정 | 생리학적 한숨 | 이중 들숨 + 긴 날숨, 급성 스트레스 즉시 완화 |
| 이완 | 4-7-8 호흡 | 4초 들숨, 7초 정지, 8초 날숨 |
| 이완 | 4-6 릴렉스 호흡 | 4초 들숨, 6초 날숨 |
| 집중 | 4-4-4-4 박스 호흡 | 미 해군 NAVY SEALs 집중력 강화 기법 |
| 집중 | 4-2-4-2 세미 박스 호흡 | 박스 호흡 경량화 버전 |
| 회복 | 5-5 공진 호흡 | 0.1Hz 자율신경 공진 주파수 |
| 회복 | 2-1-4-1 횡격막 복식호흡 | 횡격막 활성화 심호흡 |
| 각성 | 4-1-2-1 각성 호흡 | 교감신경 자극, 집중력·각성 유도 |

### 3. Gemini Flash AI 실시간 분석 & 피드백
- **슬롯 A**: 생체 수치 변동폭 기반 4단계 맞춤형 심박 분석 리포트 생성
- **슬롯 B**: 호흡 완주 후 피드백 + 오늘의 마인드풀니스 감성 문구 (`todaysQuote`) 생성

### 4. 상황 인지(Context-Aware) 캘린더 융합 케어
- 앱 내 일정 등록 기능 및 30분 전 로컬 알림 발송
- 일정 중요도 및 생체 컨디션 점수를 결합한 의사결정 트리 기반 최적 호흡 추천

### 5. 리추얼 히스토리 & 시각화
- 호흡 완주 기록 로컬 저장 및 서버 동기화
- 월별 아코디언 기록 뷰, 요일별 평균 HRV 차트 시각화

---

## 기술 스택 (Tech Stack)

### Frontend

| 항목 | 내용 |
| :--- | :--- |
| 프레임워크 | Flutter (Dart `>=3.0.0 <4.0.0`) |
| 지원 플랫폼 | Web, Android, iOS, Windows |
| 폰트 | Pretendard, GmarketSans |
| 주요 패키지 | `camera 0.10.5+9`, `http ^1.2.0`, `audioplayers ^6.0.0`, `shared_preferences ^2.5.5`, `permission_handler 11.3.1`, `flutter_local_notifications ^17.2.0`, `firebase_messaging ^15.1.5` |
| 배포 | Vercel (SPA 라우팅 설정 포함) |

### Backend

| 항목 | 내용 |
| :--- | :--- |
| 런타임 | Node.js v20+ |
| 프레임워크 | Express.js v4 |
| ORM | Prisma v6 |
| DB (개발/운영) | SQLite (`file:./dev.db`) |
| 인증 | JWT (`jsonwebtoken`) + bcrypt (`bcryptjs`) |
| AI 연동 | Google AI Studio Gemini Flash — 3.8 / 3.6 / 3.5 순차 폴백 (Free Tier) |
| 배포 | Render Web Service Singapore 리전 (`render.yaml` 포함) |

### 인프라 방침
**100% $0 무료 인프라 준수**: Vercel 무료 티어(Frontend), Render 무료 티어(Backend), Gemini API 무료 티어(AI) — 전액 $0 구성

---

## PPG 측정 알고리즘 및 학술 근거

### 측정 원리
손가락을 스마트폰 카메라와 LED 플래시에 밀착하면, 심장 박동에 따른 피하 미세혈관의 혈류량 변화로 헤모글로빈의 적색 광 흡수율이 미세하게 변동합니다. 초당 30프레임으로 연속 수집하여 20초 파형 데이터(samples 600개)를 복원하고 아래 공식으로 생체 지표를 산출합니다.

### 생체 지표 산출 공식

$$RR_i = t_{i+1} - t_i$$

$$\text{BPM} = \frac{60}{\overline{RR}}$$

$$\text{SDNN} = \sqrt{\frac{1}{N}\sum_{i=1}^{N}(RR_i - \overline{RR})^2} \quad \text{(ms)}$$

$$\text{RMSSD} = \sqrt{\frac{1}{N-1}\sum_{i=1}^{N-1}(RR_{i+1} - RR_i)^2} \quad \text{(ms)}$$

$$\text{Condition Score} = \text{Round}\Big(0.4 \times S_{\text{BPM}} + 0.6 \times S_{\text{HRV}}\Big)$$

### 컨디션 점수별 상태 및 추천 루틴

| 점수 구간 | 상태 | 추천 호흡 |
| :---: | :--- | :--- |
| 85 ~ 100점 | 최상 (Optimal) — 자율신경 밸런스 최상 | 5-5 공진 호흡 |
| 70 ~ 84점 | 양호 (Good) — 전반적 안정 / 몰입 추천 | 4-4-4-4 박스 호흡 |
| 50 ~ 69점 | 이완 필요 (Calm Needed) — 피로/긴장 축적 | 4-7-8 호흡 |
| 0 ~ 49점 | 경고 (High Stress) — 급성 긴장/스트레스 | 생리학적 한숨 |

### 학술 근거 논문
- **IEEE Transactions on Biomedical Engineering (2014)** — 12유도 ECG 대비 심박수 r = 0.98, HRV r = 0.95 임상 유효성 입증
- **Nature Scientific Reports (2018)** — 자율신경계 스트레스 지표(RMSSD, SDNN) 측정 유효성 검증
- **JMIR (2020)** — 디지털 필터링 시 R-R 간격 측정 오차 10ms 이내 보장

---

## 데이터베이스 스키마 (Prisma ORM)

| 모델 | 주요 필드 | 설명 |
| :--- | :--- | :--- |
| `User` | `id`, `email`, `name`, `authProvider` | 회원 정보 (email / guest) |
| `Measurement` | `bpm`, `hrvRmssd`, `hrvSdnn`, `conditionScore`, `signalQuality`, `samplesCount` | PPG 생체 측정 결과 |
| `BreathingLog` | `category`, `routineName`, `durationSeconds`, `completionRate` | 호흡 세션 완주 기록 |
| `Schedule` | `title`, `startTime`, `endTime`, `syncedToGoogle` | 앱 내 일정 등록 |
| `AiReport` | `headline`, `avgBpmAnalysis`, `overallGuide`, `weekStartDate` | Gemini AI 리포트 저장 |

---

## REST API 명세 (API Endpoints)

### 서버 헬스 체크 — `/api/health`

| Method | Endpoint | 설명 |
| :--- | :--- | :--- |
| GET | `/api/health` | 서버 동작 상태 및 DB 연결 확인 |
| GET | `/api/health/version` | API 버전 및 라이선스 정보 반환 |

### 인증 & 회원 관리 — `/api/auth`

| Method | Endpoint | 설명 |
| :--- | :--- | :--- |
| POST | `/api/auth/signup` | 회원가입 (이메일/비밀번호) |
| POST | `/api/auth/login` | 로그인 (JWT 토큰 발급) |
| POST | `/api/auth/guest` | 비회원 게스트 토큰 발급 |
| GET | `/api/auth/me` | 내 프로필 조회 |

### PPG 생체 측정 — `/api/measurements`

| Method | Endpoint | 설명 |
| :--- | :--- | :--- |
| POST | `/api/measurements` | 20초 파형 처리 → BPM, HRV, 컨디션 점수 산출 및 호흡 추천 연산 |

### 호흡 세션 기록 & 통계 — `/api/breathing-logs`, `/api/statistics`

| Method | Endpoint | 설명 |
| :--- | :--- | :--- |
| POST | `/api/breathing-logs` | 호흡 세션 완주 기록 저장 |
| GET | `/api/breathing-logs` | 최근 호흡 내역 목록 조회 |
| GET | `/api/statistics/summary` | 주간/월간 생체 및 호흡 통계 요약 |

### 일정 CRUD & 알림 — `/api/schedules`

| Method | Endpoint | 설명 |
| :--- | :--- | :--- |
| GET | `/api/schedules` | 등록된 일정 목록 조회 |
| POST | `/api/schedules` | 신규 일정 등록 및 30분 전 알림 연산 |
| DELETE | `/api/schedules/:id` | 일정 삭제 |

### Gemini Flash AI 리포트 — `/api/reports`

| Method | Endpoint | 설명 |
| :--- | :--- | :--- |
| POST | `/api/reports/analyze` | 생체 수치 기반 실시간 AI 4단계 심박 분석 리포트 생성 |
| POST | `/api/reports/feedback` | 호흡 완주 피드백 + `todaysQuote` 실시간 생성 |

---

## 인증 & 세션 정책

- **이름/닉네임**: 2자 이상 20자 이하
- **비밀번호**: 영문 + 숫자 포함, 8자 이상 64자 이하
- **게스트 세션**: 비회원 접속 시 디바이스 기반 토큰으로 독립 세션 유지
- **미연동 버튼**: 구글 로그인 등 미구현 기능 탭 시 무반응 처리 (`onTap: () {}`)

---

## 화면 구성 (Screens)

| 파일명 | 화면 설명 |
| :--- | :--- |
| `splash_screen.dart` | 앱 초기 로딩 및 세션 복원 |
| `onboarding_screen.dart` | 최초 실행 온보딩 안내 |
| `permission_request_screen.dart` | 카메라/알림 권한 요청 |
| `login_screen.dart` | 로그인 (이메일 / 게스트) |
| `signup_screen.dart` | 회원가입 |
| `home_screen.dart` | 홈 — 컨디션 대시보드 및 캘린더 일정 |
| `condition_measurement_screen.dart` | PPG 카메라 생체 측정 |
| `measurement_result_screen.dart` | 측정 결과 및 AI 리포트 확인 |
| `recommended_breathing_screen.dart` | 맞춤형 호흡 루틴 추천 |
| `breathing_exercise_screen.dart` | 호흡 가이드 수행 화면 |
| `breathing_completion_screen.dart` | 호흡 완료 피드백 및 `todaysQuote` |
| `log_screen.dart` | 주간/월별 생체 데이터 HRV 차트 |
| `ritual_history_screen.dart` | 월별 아코디언 호흡 완주 기록 |
| `add_schedule_modal.dart` | 일정 등록 모달 |
| `my_page_screen.dart` | 마이페이지 — 프로필 및 설정 |

---

## UI 표기 규격

### 8종 호흡 루틴 명칭 이원화

화면에 따라 정식 명칭(옵션 A)과 심플 명칭(옵션 B)을 구분하여 사용합니다.

| 번호 | 추천/수행/완료 화면 (정식 명칭) | Ritual 기록 화면 (심플 명칭) |
| :---: | :--- | :--- |
| 1 | 생리학적 한숨 | 생리학적 한숨 |
| 2 | 4-7-8 호흡 | 4-7-8 호흡 |
| 3 | 4-6 릴렉스 호흡 | 4-6 호흡 |
| 4 | 4-4-4-4 박스 호흡 | 4-4-4-4 호흡 |
| 5 | 4-2-4-2 세미 박스 호흡 | 4-2-4-2 호흡 |
| 6 | 5-5 공진 호흡 | 5-5 공진 호흡 |
| 7 | 2-1-4-1 횡격막 복식호흡 | 2-1-4-1 호흡 |
| 8 | 4-1-2-1 각성 호흡 | 4-1-2-1 호흡 |

### Ritual 기록 화면 아코디언 UI
- 펼침 상태 (`isExpanded = true`): 아래 화살표 (`Icons.keyboard_arrow_down_rounded`)
- 닫힘 상태 (`isExpanded = false`): 오른쪽 화살표 (`Icons.chevron_right_rounded`)
- 기록 리스트 우측: 재생 버튼 (`Icons.play_arrow_rounded`)

### 요일별 HRV 차트 바 색상

| 구분 | 색상 코드 |
| :--- | :--- |
| 최고 수치 요일 (Highest) | `Color(0xFFE4FBCB)` — 연한 민트 |
| 최저 수치 요일 (Lowest) | `Color(0xFFF9F6AF)` — 연한 옐로우 |
| 일반 요일 | `Color(0xFF474A52)` — 다크 슬레이트 그레이 |

---

## 프로젝트 구조 (Directory Structure)

```text
bpace/
├── frontend/                          # Flutter 멀티플랫폼 앱
│   ├── lib/
│   │   ├── main.dart                  # 앱 진입점 및 테마 설정
│   │   ├── screens/                   # 화면 15개
│   │   ├── services/                  # API 클라이언트, 인증, 알림, 리포트 서비스
│   │   ├── models/                    # 데이터 모델 (User, Measurement)
│   │   ├── widgets/                   # 공통 위젯 (BpaceLogo)
│   │   ├── theme/                     # AppColors, AppTextStyles
│   │   └── utils/                     # 유틸리티 함수
│   ├── assets/
│   │   ├── fonts/                     # Pretendard, GmarketSans 폰트
│   │   ├── images/                    # 앱 이미지 자원
│   │   └── audio/                     # 호흡 가이드 오디오
│   ├── vercel.json                    # Vercel SPA 라우팅 설정
│   └── pubspec.yaml                   # Flutter 의존성 명세
├── backend/                           # Node.js Express REST API 서버
│   ├── src/
│   │   ├── server.js                  # 서버 진입점
│   │   ├── app.js                     # Express 앱 설정 및 미들웨어
│   │   ├── routes/                    # API 라우터 7개
│   │   ├── controllers/               # 요청 핸들러
│   │   ├── services/                  # Gemini AI 서비스, 리포트 프롬프트
│   │   ├── middlewares/               # JWT 인증 미들웨어
│   │   └── utils/                     # 유틸리티 함수
│   ├── prisma/
│   │   ├── schema.prisma              # DB 스키마 (5개 모델)
│   │   └── migrations/                # 마이그레이션 파일
│   ├── render.yaml                    # Render 배포 Blueprint
│   ├── Dockerfile                     # Docker 컨테이너 설정
│   ├── .env.example                   # 환경변수 템플릿
│   └── package.json                   # Node.js 의존성 명세
├── GITHUB_RULES.md                    # 커밋 컨벤션 및 브랜치 전략
├── LICENSE                            # MIT License
└── README.md                          # 프로젝트 통합 문서
```

---

## 로컬 개발 및 실행 가이드 (Getting Started)

### 사전 요구사항
- Flutter SDK `>=3.0.0`
- Node.js `v20+`
- Gemini API Key ([https://aistudio.google.com/](https://aistudio.google.com/) 에서 무료 발급)

### 프론트엔드 (Flutter)
```bash
git clone https://github.com/yelimk/bpace.git
cd bpace/frontend
flutter pub get
flutter run
```

### 백엔드 (Node.js)
```bash
cd bpace/backend
cp .env.example .env
# .env 파일에 GEMINI_API_KEY 입력
npm install
npx prisma db push
npm run dev
```

### 환경변수 (.env)
```env
PORT=3000
NODE_ENV=development
DATABASE_URL="file:./dev.db"
JWT_SECRET="your_jwt_secret"
GEMINI_API_KEY="your_gemini_api_key"
```

---

## 깃허브 운영 규칙 (GitHub Rules)

커밋 컨벤션 및 브랜치 전략은 [GITHUB_RULES.md](./GITHUB_RULES.md) 문서를 참고하세요.

---

## 라이선스 (License)

MIT License — Copyright (c) 2026 yelimk (BPACE Project)
