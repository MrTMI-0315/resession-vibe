# Resession
한 줄 요약: 기록 부담을 낮추고 집중 흐름을 유지하도록 돕는 Flutter 기반 포커스 세션 MVP입니다.

![Resession Screenshot Placeholder](./docs/screenshot-placeholder.png)

## 1) 소개
Resession은 짧은 집중 세션을 시작하고, 필요할 때 휴식으로 전환한 뒤, 다시 집중으로 복귀해 마무리까지 이어지는 흐름을 제공합니다. 핵심은 사용자가 복잡한 입력 없이도 `시작 -> 진행 -> 휴식 -> 종료 -> 저장` 사이클을 반복할 수 있게 하는 것입니다.

현재 저장은 인메모리 기반이며, 상태관리는 `ChangeNotifier` 기반 `SessionController` 1개로 구성되어 있습니다. iOS/Android 세팅이 없어도 macOS/Chrome 실행으로 기능 확인이 가능합니다.

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
- [x] 프리셋 선택: `25/5`, `50/10`, `custom` 모두 탭 가능 (Idle에서 즉시 반영)
- [x] 단일 상태관리: `SessionController(ChangeNotifier)`
- [x] 모델 구성: `SessionPreset`, `SessionRunState`, `SessionRecord` (인메모리)
- [x] 공통 UI 위젯: 상태 카드 / 프리셋 칩 / CTA 버튼
- [x] 타이머 예산 로직 보정 완료 (Focus/Break 예산 보존)
- [x] `flutter analyze`, `flutter test` 통과
- [x] macOS 스모크 런 성공

## 4) 기술 메모
타이머는 `phase 시작 시각 + 기준 잔여시간` 방식으로 계산합니다.  
화면에는 `currentFocusRemainingSeconds`, `currentBreakRemainingSeconds` getter 값을 표시합니다.  
Focus -> Break 전환 시 Focus 잔여시간을 동결합니다.  
Break -> Focus 전환 시 Break 잔여 예산을 차감한 상태로 유지합니다.  
따라서 Break 재진입 시 초기값으로 리셋되지 않고 남은 예산에서 이어집니다.

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
```bash
cd /Users/mrtmi/Desktop/Mr_TMI/vibe/apps/resession
flutter analyze
flutter test
```

현재 상태:
- `flutter analyze`: No issues found
- `flutter test`: All tests passed (3 tests)

## 7) 수동 검증 체크리스트
- Home에서 `50/10` 선택 -> `Start` -> `Pause` -> Break에서 2초 대기 -> `Resume`:
  - Focus가 Break 동안 추가 감소하지 않는지 확인
- 다시 `Pause`:
  - Break가 초기값으로 리셋되지 않고 남은 값에서 이어지는지 확인

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
```

## 9) 다음 작업(Backlog)
- custom 프리셋의 분/휴식 입력 UI 추가
- 세션 기록의 영구 저장(로컬/DB) 도입
- 통계/insights 화면 확장

## 10) 라이선스/기타
- 라이선스: 현재 저장소에 별도 라이선스 표기가 없으면 기본적으로 명시되지 않은 상태입니다.
- 기타: 이 프로젝트는 의존성 추가 없이 Flutter 기본 구성으로 MVP를 유지합니다.
