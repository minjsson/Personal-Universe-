# Personal Universe

## 1. 프로젝트 개요

Personal Universe는 사용자가 하나의 챌린지를 설정하고 매일 진행하면서,
완료에 따라 은하가 성장하는 SwiftUI 기반 iPhone 앱입니다.

주요 기능은 다음과 같습니다.

- 챌린지 생성 및 일별 진행
- 완료 / 놓침 / 예정 상태 관리
- 회고 작성 및 조회
- 챌린지 진행에 따른 은하 성장
- 성장 및 최종 완료 이벤트
- 로컬 알림
- Widget
- App Group을 통한 앱과 위젯 데이터 공유

## 2. 개발 배경

저는 예술 전공이며 Apple Developer Academy에서 개발을 처음 시작했고,
Swift와 SwiftUI를 챌린지를 하며 배우고 있습니다.

저는 개념을 먼저 모두 학습한 뒤 구현하기보다,
먼저 만들고 필요한 부분을 그 과정에서 학습하는 방식으로
개발하는 편입니다.

Personal Universe는 처음부터 전체 코드 구조를 제가 직접 설계한 프로젝트는 아닙니다.
특정 아키텍처를 기준으로 처음부터 설계하기보다,
기능을 만들고 문제를 해결하는 과정에서 AI와 계속 대화하며
구조를 정하고 코드를 작성하고 수정했습니다.

따라서 현재 코드에는 AI의 도움을 받아 짠 부분이 상당히 많습니다.

## 3. 이번 코드 리뷰에서 알고 싶은 것

현재 제가 실제로 어느 정도까지 코드를 이해하고 있는지,
그리고 앞으로 어느 수준까지 스스로 설계할 수 있어야 하는지 알고 싶습니다.

특히 AI와 함께 개발할 때,

- AI가 제안한 코드를 어느 정도까지 이해하고 있어야 하는지
- AI가 제안한 구조와 추상화를 어떻게 판단해야 하는지
- 현재 프로젝트에 적절한 구조와 추상화 수준은 어느 정도인지
- 특정 아키텍처를 사용하는 시점과 그 필요성을 어떻게 판단하는지
- 협업할 때 제 코드의 책임과 동작을 다른 개발자에게 설명하고
  신뢰를 얻으려면 어느 정도까지 이해하고 있어야 하는지

를 확인하고 싶습니다.

## 4. 프로젝트 구조

현재 프로젝트는 기능에 따라 아래와 같이 나누어져 있습니다.

### Model
데이터와 챌린지 상태를 관리합니다.

- `UniverseChallenge.swift` — 챌린지의 핵심 데이터와 진행 상태
- `ChallangeDay.swift` — 챌린지의 하루 단위 데이터
- `DayStatus.swift` — 하루의 상태 정의

### Views
앱의 주요 화면과 사용자 인터랙션을 담당합니다.

- `ContentView.swift` — 메인 화면
- `EnterChallengeView.swift` — 새로운 챌린지 생성
- `CurrentChallengeView.swift` — 현재 챌린지 진행
- `ChallengeProgressView.swift` — 챌린지 진행 상태 표현
- `ChallengeJourneyView.swift` — 챌린지의 진행 및 기록 확인
- `ReflectionView.swift` — 회고 작성
- `ReflectionDetailView.swift` — 저장된 회고 확인
- `MyUniverseView.swift` — 챌린지 기록과 은하 확인
- `GrowthEventView.swift` — 성장 이벤트 화면
- `CompletionEventView.swift` — 최종 완료 이벤트 화면

### Galaxy
챌린지 진행에 따른 은하의 시각적 표현을 구성합니다.

- `GalaxyView.swift` — 은하 전체 표현
- `GalaxyBody.swift` / `GalaxyBodyView.swift` — 은하 본체의 데이터와 표현
- `GalaxyModels.swift` — 은하 관련 모델 정의
- `GalaxyComponents.swift` — 은하를 구성하는 시각 요소
- `GalaxyStar.swift` — 별의 표현
- `TwinklingGalaxyStar.swift` — 반짝이는 별의 표현
- `GalaxyStyle.swift` — 은하 스타일 정의

### Universe
챌린지 진행에 따른 은하 성장과 이벤트를 관리합니다.

- `UniverseProgress.swift` — 진행도 계산
- `UniverseEvent.swift` — 성장 및 완료 이벤트 정의
- `UniverseEventView.swift` — 이벤트 표현

### Manager
앱의 시스템 기능을 관리합니다.

- `NotificationManager.swift` — 로컬 알림 관리
- `HapticManager.swift` — 햅틱 피드백 관리

### Background
앱의 배경 표현을 담당합니다.

- `SpaceBackground.swift` — 우주 배경 표현

### Widget
앱의 챌린지 데이터를 Widget에서 표시하기 위한 기능을 담당합니다.

- `WidgetSyncManager.swift` — 앱 데이터를 Widget용 데이터로 변환하고 공유
- `WidgetDataManager.swift` — 공유된 Widget 데이터 관리
- `WidgetUniverseData.swift` — Widget에서 사용하는 데이터 구조
- `WidgetUniverseEntry.swift` — Widget 표시를 위한 데이터 상태
- `WidgetProvider.swift` — Widget에 데이터를 제공
- `WidgetDeepLink.swift` — Widget에서 앱으로 이동하는 경로 관리
- `WidgetGalaxyView.swift` — Widget에서 사용하는 은하 표현
- `WidgetProgressSymbols.swift` — 진행 상태 심볼 표현
- `SmallWidgetView.swift` / `MediumWidgetView.swift` / `LargeWidgetView.swift` — Widget 크기별 화면
- `PersonalUniverseWidget.swift` — Widget 구성

### App

- `PersonalUniverseApp.swift` — 앱의 시작점과 앱 전반의 환경 설정
