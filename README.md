# Resession
한 줄 요약: 기록 부담을 낮추고 집중 흐름을 유지하도록 돕는 Flutter 기반 포커스 세션 MVP입니다.

> 스크린샷 자리(placeholder): UI 캡처 이미지 추가 예정 (`docs/assets/` 권장)

**3분 실행(권장 경로):**
```bash
cd /Users/mrtmi/Desktop/Mr_TMI/vibe/apps/resession
flutter pub get
flutter run -d macos
# 또는
flutter run -d chrome
```

## 1) 소개
Resession은 집중 세션을 빠르게 시작하고, 필요 시 휴식으로 전환한 뒤, 다시 집중으로 복귀해 종료/저장까지 이어지는 루프를 제공합니다. 목표는 입력 부담을 줄이면서도 사용자가 세션 흐름을 통제할 수 있게 하는 것입니다.

현재 MVP는 `Home/Idle -> Focus -> Break -> End -> Save -> Home` 세로 슬라이스에 집중합니다. 상태 관리는 `ChangeNotifier` 기반 `SessionController` 1개로 구성되어 있으며, 세션 데이터는 인메모리 모델(`SessionPreset`, `SessionRunState`, `SessionRecord`)을 사용합니다.

## 2) 핵심 사용자 플로우
- Home/Idle 화면 진입
- 프리셋 선택: `25/5`, `50/10`, `custom`
- `Start session`으로 Focus 시작
- `Pause`로 Break 전환
- `Resume`으로 Focus 복귀
- Focus 종료 시 End 화면 진입
- `Log / Save` 후 Home 복귀

## 3) 구현된 기능
- [x] MVP vertical slice: `Home -> Focus -> Break -> End -> Save -> Home`
- [x] 프리셋 선택: `25/5`, `50/10`, `custom` 모두 탭 가능(Idle에서 선택 반영)
- [x] 상태관리: `SessionController(ChangeNotifier)` 단일 컨트롤러
- [x] 인메모리 모델: `SessionPreset`, `SessionRunState`, `SessionRecord`
- [x] 공통 UI 위젯: 상태 카드 / 프리셋 칩 / CTA 버튼
- [x] 타이머 예산 로직 반영(Focus 동결, Break 공유 예산 유지)

## 4) 기술 메모
타이머는 `phase 시작 시각 + 기준 잔여시간` 계산 방식을 사용합니다.  
화면 표시는 `currentFocusRemainingSeconds`, `currentBreakRemainingSeconds` getter로 계산된 값을 사용합니다.  
Focus -> Break 전환 시 Focus 잔여시간을 동결합니다.  
Break -> Focus 전환 시 Break 잔여 예산을 차감한 상태로 유지합니다.  
Break 재진입 시 초기값으로 리셋되지 않고 남은 값에서 이어집니다.

## 5) 설치/실행
요구사항:
- Flutter SDK (stable)
- Dart SDK `^3.10.8` 호환
- macOS 실행 시 Xcode(Command Line Tools 포함) 권장

참고:
- iOS/Android는 아직 세팅 안 되어도 macOS/Chrome로 충분히 확인 가능합니다.

macOS 실행:
```bash
cd /Users/mrtmi/Desktop/Mr_TMI/vibe/apps/resession
flutter pub get
flutter run -d macos
```

Chrome 실행:
```bash
cd /Users/mrtmi/Desktop/Mr_TMI/vibe/apps/resession
flutter pub get
flutter run -d chrome
```

## 6) 테스트/정적분석
명령어:
```bash
cd /Users/mrtmi/Desktop/Mr_TMI/vibe/apps/resession
flutter analyze
flutter test
```

기대되는 출력/통과 조건:
- `flutter analyze`: 종료 코드 `0`, 출력에 `No issues found!` 포함
- `flutter test`: 종료 코드 `0`, 출력에 `All tests passed!` 포함

작성 시점 참고(2026-02-11):
- 회귀 테스트 포함 총 3개 테스트 기준으로 통과 로그를 확인함

## 7) 수동 검증 체크리스트
- Home에서 `50/10` 선택 -> `Start` -> `Pause` -> Break에서 2초 대기 -> `Resume`:
  - Focus가 Break 동안 추가 감소하지 않는지 확인
- 다시 `Pause`:
  - Break가 리셋되지 않고 남은 값에서 이어지는지 확인

## 8) 폴더 구조 요약
```text
lib/
  main.dart
  app/
    app.dart
  features/
    home/
      home_screen.dart
    session/
      session_controller.dart
      session_screen.dart
      break_screen.dart
      end_screen.dart
  ui/
    widgets/
      session_template.dart
      session_status_card.dart
      preset_selector.dart
      primary_cta_button.dart
test/
  widget_test.dart
```

## 9) 다음 작업(Backlog)
- custom 프리셋의 분/휴식 입력 UI 추가
- 세션 기록 영구 저장(로컬/DB) 도입
- 통계/insights 화면 확장

## 10) 라이선스/기타
- 라이선스: 저장소의 별도 라이선스 파일/표기를 따릅니다.
- 기타: 의존성 추가 없이 Flutter 기본 구성으로 MVP를 유지합니다.
