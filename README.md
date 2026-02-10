# Resession (Flutter MVP)
Resession은 `start -> run -> break -> end -> save` 루프를 빠르게 돌며 집중 세션을 운영하는 Flutter MVP입니다.

- 포함 범위(MVP)
  - Home(Idle) 화면에서 프리셋 선택 후 세션 시작
  - Focus 카운트다운, Pause로 Break 전환, Resume으로 Focus 복귀
  - Focus 종료 시 End 화면 전환, `Log / Save`로 Home 복귀
  - 세션 기록은 현재 인메모리(`SessionRecord`)로만 유지
- 비포함 범위(Non-goals)
  - 영구 저장(DB/클라우드)
  - 인증/동기화/백엔드 연동
  - 상세 인사이트 화면 및 통계 시각화
  - Drift log 고도화(현재는 MVP 범위 밖)

## 데모/레퍼런스
- Figma: [Resession-MVP-v0.1](https://www.figma.com/design/Abr8taz3MIqu5ENuaVwqBb/Resession-MVP-v0.1?node-id=28-4&t=NdaHx3bNBupBeUp3-1)
- 현재 구현 플로우
  - `Home(Idle) -> Focus(Running) -> Break -> End -> Log/Save -> Home`

## 빠른 시작(로컬 실행)
- 요구사항
  - Flutter SDK(stable) 설치
  - Dart SDK `^3.10.8` 호환(현재 `pubspec.yaml` 기준)
  - macOS 데스크톱 실행 시 Xcode(Command Line Tools 포함) 권장
  - iOS 빌드가 필요하면 CocoaPods 설치 필요
  - 개발 타깃은 `macOS` 또는 `Chrome` 사용 가능

- 설치/검증/실행 명령(복붙용)
```bash
flutter pub get
flutter analyze
flutter test
flutter run -d macos
# 또는
flutter run -d chrome
```

- iOS 실기기 연결(선택 사항)
```bash
flutter devices
flutter run -d <ios-device-id>
```

## 프로젝트 구조
```text
lib/
  main.dart
  app/app.dart
  features/
    home/home_screen.dart
    session/
      session_controller.dart
      session_screen.dart
      break_screen.dart
      end_screen.dart
  ui/widgets/
    session_template.dart
    session_status_card.dart
    preset_selector.dart
    primary_cta_button.dart
test/
  widget_test.dart
```

- 핵심 파일 역할
  - `lib/main.dart`: 앱 엔트리, `ResessionApp` 실행
  - `lib/app/app.dart`: `MaterialApp`/테마 설정, phase 기반 루트 화면 선택
  - `lib/features/home/...`: Idle(Home) 화면 구성
  - `lib/features/session/...`: 세션 상태머신/타이머(`session_controller.dart`) 및 Focus/Break/End 화면
  - `lib/ui/widgets/...`: 공통 UI 조합(상태 카드, 프리셋 칩, CTA 버튼)
  - `test/...`: 위젯 스모크 + 기본 세션 플로우 전환 테스트

## 기능 스펙 요약(MVP)
- 프리셋
  - `25/5`, `50/10`, `custom` 선택 가능
  - 선택 상태가 UI에서 즉시 반영됨
- 상태머신
  - `idle -> focus -> breakTime -> focus(재개) -> ended`
  - Focus 시간이 0이 되면 End 화면으로 전환
- 저장
  - 현재: `SessionRecord` 인메모리 저장(`Log / Save` 시 append)
  - 이후 계획(선택): 로컬 영구 저장 + 히스토리 화면 연결

## 개발 원칙(개발공부 지침 반영)
- 증거 기반으로 작업하고, 실행한 명령/결과를 기준으로 판단합니다.
- 최소 변경 원칙을 지켜 작은 범위로 수정하고 빠르게 검증합니다.
- 마이크로 태스크 단위로 구현하고, 각 단계에서 `analyze/test`를 확인합니다.
- 새 의존성/큰 리팩토링은 필요성이 명확할 때만 제안합니다.
- 커밋 규칙(권장): `1커밋 = 1마이크로태스크`.

## 다음 작업(Backlog)
- custom 프리셋의 실제 입력 UI(분/휴식) 추가
- 저장된 세션 1줄 히스토리(최근 기록) 노출
- Drift log(옵션) 최소 입력 스텁 연결
