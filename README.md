# 🫁 BPACE (Breath Pace & Care)

> **스마트폰 카메라 PPG 센서 기반 심박수·컨디션 측정 및 맞춤형 호흡 케어 웰니스 플랫폼**

---

## 📌 프로젝트 소개 (Project Overview)

**BPACE**는 별도의 헬스케어 웨어러블 장비 없이 **스마트폰 카메라 센서(PPG, 광혈류 측정)**만으로 사용자의 심박수(Heart Rate) 및 컨디션/스트레스 상태를 정밀하게 측정하고, 측정된 상태에 맞춰 최적화된 맞춤형 호흡 루틴(4-7-8 호흡, Box Breathing 등)을 제공하는 라이프 케어 솔루션입니다.

---

## 🛠️ 기술 스택 (Tech Stack)

- **Framework**: [Flutter](https://flutter.dev/) (Dart `>=3.0.0 <4.0.0`)
- **Supported Platforms**: Android, iOS, Web, Windows
- **Key Features**:
  - `camera`: PPG 신호 캡처용 카메라 센서 및 플래시 제어
  - `firebase_core`, `firebase_messaging`: FCM 푸시 알림 및 알림 스케줄링
  - `google_sign_in`: 소셜 로그인 인증
  - `shared_preferences`: 로컬 환경 설정 및 세션 저장

---

## 📂 프로젝트 구조 (Directory Structure)

```text
bpace/
├── frontend/                     # Flutter 애플리케이션 프로젝트
│   ├── lib/                      # 메인 소스 코드 (Screens, Widgets, Services, Models)
│   ├── assets/                   # 폰트, 이미지, 오디오 자원
│   ├── android/                  # Android 플랫폼 설정
│   ├── ios/                      # iOS 플랫폼 설정
│   ├── web/                      # Web 플랫폼 설정
│   └── test/                     # 단위 및 E2E 테스트 코드
├── GITHUB_RULES.md               # 깃허브 커밋, 브랜치 및 PR 협업 규칙
└── README.md                     # 프로젝트 대표 설명 문서 (현재 파일)
```

---

## 🚀 시작하기 (Getting Started)

### 사전 조건 (Prerequisites)
- Flutter SDK v3.0.0 이상 설치
- Android Studio / Xcode (모바일 에뮬레이터 또는 실기기 준비)

### 실행 방법 (Run Instructions)
```bash
# 1. 레포지토리 클론
git clone https://github.com/yelimk/bpace.git
cd bpace/frontend

# 2. 패키지 의존성 설치
flutter pub get

# 3. 애플리케이션 실행
flutter run
```

---

## 📜 깃허브 운영 규칙 (GitHub Rules)

팀 생산성과 원활한 코드 리뷰를 위해 정의된 커밋 메시지, 브랜치 전략 및 PR 규칙을 준수합니다.
자세한 규정은 [`GITHUB_RULES.md`](./GITHUB_RULES.md) 문서에서 확인하실 수 있습니다.
