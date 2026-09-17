# BPACE (Breath Pace & Care)

> **스마트폰 카메라 PPG 센서 기반 심박수·컨디션 측정 및 맞춤형 호흡 케어 웰니스 플랫폼**

---

## 주요 서비스 제출 및 배포 링크 (Submission Links)

- **웹 앱 서비스 (Frontend Web)**: [https://bpace.vercel.app](https://bpace.vercel.app)
- **백엔드 클라우드 API (Backend)**: [https://bpace.onrender.com](https://bpace.onrender.com)
- **GitHub 저장소 (Repository)**: [https://github.com/yelimk/bpace](https://github.com/yelimk/bpace)

---

## 프로젝트 소개 (Project Overview)

**BPACE**는 별도의 헬스케어 웨어러블 장비 없이 **스마트폰 카메라 센서(PPG, 광혈류 측정)**만으로 사용자의 심박수(BPM) 및 컨디션/스트레스 상태(HRV)를 정밀 측정하고, 측정된 생체 데이터와 **구글 캘린더 일정 상황**에 맞춰 최적화된 맞춤형 호흡 루틴(생리학적 한숨, 4-7-8 호흡, Box Breathing 등 8종) 및 Gemini 2.0 Flash AI 분석 리포트를 제공하는 웰니스 라이프케어 솔루션입니다.

---

## 핵심 주요 기능 (Key Features)

1. **스마트폰 카메라 PPG 생체 측정**
   - 20초간 초당 30프레임(600샘플) 신호 수집 -> 심박수(BPM), 심박변이도(HRV SDNN/RMSSD), 0~100점 컨디션 점수 정밀 산출
2. **의학 근거 기반 5대 카테고리 8종 맞춤 호흡 루틴**
   - **진정**: 생리학적 한숨 (이중 들숨 + 긴 날숨)
   - **이완**: 4-7-8 호흡, 4-6 릴렉스 호흡
   - **집중**: 4-4-4-4 박스 호흡 (미 해군 NAVY SEALs), 4-2-4-2 세미 박스
   - **회복**: 5.5-5.5 공진 호흡 (0.1Hz 자율신경 공진), 2-1-4-1 횡격막 복식호흡
   - **각성**: 4-1-2-1 각성 호흡
3. **Gemini 2.0 Flash AI 실시간 생체 분석 & 피드백**
   - 슬롯 A: 생체 수치 변동폭 기반 4단계 맞춤 심박 분석 리포트
   - 슬롯 B: 호흡 완주 결과 피드백 + 마인드풀니스 감성 문구 (`todaysQuote`) 생성
4. **상황 인지(Context-Aware) 캘린더 융합 케어**
   - 중요 미팅/발표 30분 전 선제적 알림 -> 상황별 융합 의사결정 트리를 통한 최적 호흡 추천
5. **리추얼 히스토리 & 월별 아코디언 기록 관리**
   - 주간/월간 생체 데이터 추이 및 차트 시각화, 완주 기록 로컬/서버 동기화

---

## 기술 스택 및 무과금 인프라 (Tech Stack & Zero-Cost Infra)

- **Frontend**: [Flutter](https://flutter.dev/) (Dart `>=3.0.0 <4.0.0`) - Web, Android, iOS, Windows
- **Backend**: Node.js (v20+) / Express.js
- **Database & ORM**: Prisma ORM / SQLite (개발) & PostgreSQL (운영)
- **AI Engine**: Google AI Studio Gemini 2.0 Flash Free Tier
- **Deployment**: Vercel (Web Frontend), Render Web Service (Backend API)
- **100% $0 무료 인프라 준수 (Zero-Cost Policy)**: 백엔드 서버(Render Free Tier), DB, AI API 모두 전액 무료 티어로 구축 및 연동 완료.

---

## PPG 측정 알고리즘 및 과학적/학술적 근거 (PPG Algorithm)

### 1. 측정 원리 (Contact PPG Mechanism)
손가락을 스마트폰 카메라와 LED 플래시에 밀착하면, 심장 박동에 따른 피하 미세혈관의 혈류량 변화로 헤모글로빈의 녹색/적색 광 흡수율이 미세하게 변동합니다. 초당 30프레임(30fps)으로 연속 수집하여 실제 심전도(ECG)와 상응하는 20초 파형 샘플 데이터(`samples`)를 복원합니다.

### 2. 학술 임상 검증 논문
- **IEEE Transactions on Biomedical Engineering (2014)**: 12유도 심전도(ECG) 대비 심박수 $r = 0.98$, HRV $r = 0.95$ 이상의 임상 유효성 입증.
- **Nature Scientific Reports (2018)**: 자율신경계 스트레스 지표(RMSSD, SDNN) 측정 유효성 검증.
- **JMIR (2020)**: 디지털 필터링 시 R-R 간격 측정 오차 10ms 이내 보장.

### 3. 생체 지표 정밀 산출 공식
- **R-R 간격 ($RR_i$)**: 연속된 파형 피크 시점 차이 ($RR_i = t_{i+1} - t_i$)
- **심박수 (BPM)**: $\text{BPM} = 60 / \overline{RR}$
- **SDNN (전반 조절력)**: $\text{SDNN} = \sqrt{\frac{1}{N}\sum_{i=1}^{N}(RR_i - \overline{RR})^2}$ (ms)
- **RMSSD (부교감 신경 이완도)**: $\text{RMSSD} = \sqrt{\frac{1}{N-1}\sum_{i=1}^{N-1}(RR_{i+1} - RR_i)^2}$ (ms)

### 4. 의학적 가중치 융합 컨디션 점수 (0~100점)
$$\text{Condition Score} = \text{Round}\Big( 0.4 \times S_{\text{BPM}} + 0.6 \times S_{\text{HRV}} \Big)$$

| 점수 구간 | 상태 등급 | 신체 상태 | 추천 호흡 카테고리 |
| :---: | :---: | :--- | :--- |
| **85 ~ 100점** | **최상 (Optimal)** | 자율신경 밸런스 최상 | 5.5-5.5 공진 호흡 |
| **70 ~ 84점** | **양호 (Good)** | 전반적 안정 / 몰입 추천 | 4-4-4-4 박스 호흡 |
| **50 ~ 69점** | **이완 필요 (Calm Needed)** | 피로/긴장 축적 | 4-7-8 호흡 |
| **0 ~ 49점** | **경고 (High Stress)** | 급성 긴장/스트레스 | 생리학적 한숨 |

---

## REST API 엔드포인트 명세서 (API Specifications)

### 1. 서버 헬스 체크 (`/api/health`)
- `GET /api/health`: 서버 동작 상태 및 DB 연결 확인
- `GET /api/health/version`: API 버전 및 라이선스 정보 반환

### 2. 인증 & 회원 관리 (`/api/auth`)
- `POST /api/auth/signup`: 회원가입 (이메일/비밀번호)
- `POST /api/auth/login`: 로그인 (JWT 토큰 발급)
- `POST /api/auth/guest`: 비회원 게스트 토큰 발급
- `GET /api/auth/me`: 내 프로필 조회

### 3. PPG 생체 측정 (`/api/measurements`)
- `POST /api/measurements`: 20초 파형 처리 -> BPM, HRV(SDNN/RMSSD), 컨디션 점수 산출 및 추천 연산

### 4. 호흡 세션 기록 & 통계 (`/api/breathing-logs`, `/api/statistics`)
- `POST /api/breathing-logs`: 호흡 세션 완주 기록 저장
- `GET /api/breathing-logs`: 최근 호흡 내역 목록 조회
- `GET /api/statistics/summary`: 주간/월간 생체 및 호흡 통계 요약

### 5. 일정 CRUD & 알림 (`/api/schedules`)
- `GET /api/schedules`: 등록된 일정 목록 조회
- `POST /api/schedules`: 신규 일정 등록 및 30분 전 알림 연산
- `DELETE /api/schedules/:id`: 일정 삭제

### 6. Gemini 2.0 Flash AI 리포트 (`/api/reports`)
- `POST /api/reports/analyze`: 생체 측정 수치 기반 실시간 AI 4단계 심박 분석 리포트 생성
- `POST /api/reports/feedback`: 호흡 완주 피드백 + 오늘의 한마디 (`todaysQuote`) 실시간 생성

---

## 인증 및 세션 정책 (Authentication Policy)

1. **이름/닉네임**: 2자 이상 ~ 20자 이하
2. **비밀번호**: 영문 + 숫자 포함 8자 이상 ~ 64자 이하
3. **게스트 세션**: 비회원 접속 시 디바이스 토큰 기반 독립 세션 유지
4. **미연동 버튼 방침**: 구글 로그인 등 미구현 기능 탭 시 스낵바 팝업 없이 무반응(`onTap: () {}`) 처리

---

## 8종 호흡 루틴 UI 표기 이원화 및 디자인 규격 (Breathing Routine UI & Design Rules)

### 1. 화면별 호흡 명칭 이원화 규격
- **추천/수행/완료 화면**: 정식 명칭 (옵션 A) 사용
- **Ritual 기록 화면**: 심플 명칭 (옵션 B) 사용

| 번호 | **추천/수행/완료 화면 (정식 명칭 - 옵션 A)** | **Ritual 기록 화면 (심플 명칭 - 옵션 B)** |
| :---: | :--- | :--- |
| **1** | **생리학적 한숨** | **생리학적 한숨** |
| **2** | **4-7-8 호흡** | **4-7-8 호흡** |
| **3** | **4-6 릴렉스 호흡** | **4-6 호흡** |
| **4** | **4-4-4-4 박스 호흡** | **4-4-4-4 호흡** |
| **5** | **4-2-4-2 세미 박스 호흡** | **4-2-4-2 호흡** |
| **6** | **5-5 공진 호흡** | **5-5 공진 호흡** |
| **7** | **2-1-4-1 횡격막 복식호흡** | **2-1-4-1 호흡** |
| **8** | **4-1-2-1 각성 호흡** | **4-1-2-1 호흡** |

### 2. Ritual 기록 화면 아코디언 UI 규격
- **월별 아코디언 헤더 화살표 (`2026년 9월` 등)**:
  - **펼침 상태 (`isExpanded = true`)**: 아래 화살표 (`Icons.keyboard_arrow_down_rounded`)
  - **닫힘 상태 (`isExpanded = false`)**: 오른쪽 화살표 (`Icons.chevron_right_rounded`)
- **기록 리스트 우측 버튼**: 재생 버튼 (`Icons.play_arrow_rounded`) 유지.

### 3. 요일별 평균 HRV 차트 바 색상 규격
- **최고 수치 요일 (Highest)**: 연한 민트 톤 (`Color(0xFFE4FBCB)`) & 상단 닷 포인트
- **최저 수치 요일 (Lowest)**: 연한 옐로우 톤 (`Color(0xFFF9F6AF)`) & 상단 닷 포인트
- **일반 요일 (Mon~Sun 나머지 일반 회색 막대)**: 단일 통일 다크 슬레이트 그레이 (`Color(0xFF474A52)`)
- 샘플 시뮬레이션 및 실시간 데이터 측정 연산 시 모두 동일하게 적용.

---

## 프로젝트 구조 (Directory Structure)

```text
bpace/
├── frontend/                     # Flutter 멀티플랫폼 앱 (Web/Mobile/Desktop)
│   ├── lib/                      # 화면(Screens), 위젯(Widgets), 서비스(Services)
│   ├── assets/                   # 이미지, 폰트, 오디오 자원
│   └── web/                      # Vercel 웹 배포 설정
├── backend/                      # Node.js Express REST API 서버
│   ├── src/                      # API 라우터, 컨트롤러, AI 서비스
│   ├── prisma/                   # DB 스키마 & 마이그레이션
│   └── render.yaml               # Render 클라우드 배포 manifest
├── GITHUB_RULES.md               # 깃허브 커밋/브랜치 운영 규격 문서
└── README.md                     # 프로젝트 통합 대표 설명 문서
```

---

## 로컬 개발 및 실행 가이드 (Getting Started)

### 프론트엔드 (Frontend - Flutter)
```bash
git clone https://github.com/yelimk/bpace.git
cd bpace/frontend
flutter pub get
flutter run
```

### 백엔드 (Backend - Node.js)
```bash
cd bpace/backend
npm install
npx prisma db push
npm run dev
```

---

## 깃허브 운영 규칙 (GitHub Rules)

팀 생산성과 코드 품질을 위해 작성된 커밋 컨벤션 및 브랜치 전략은 [`GITHUB_RULES.md`](./GITHUB_RULES.md) 문서에 독립 보존되어 있습니다.
