# CODEX_CONTEXT.md
작성 시점: 2026-02-11 (로컬 로그 기준)

## Project Overview
- Resession은 "start -> focus run -> break -> end -> save" 루프를 빠르게 반복하도록 돕는 Flutter MVP 앱이다.
- 핵심 목표는 기록 부담을 낮추면서도 세션 통제감(일시정지/복귀/저장)을 제공하는 것이다.
- SSOT는 `ChangeNotifier` 기반 `SessionController` 1개이며, UI는 컨트롤러 상태를 반영한다.

## Current Status (Implemented)
- 플로우: `Home/Idle -> Focus -> Break -> End -> Save -> Home` 동작.
- 프리셋: `25/5`, `50/10`, `custom` 선택 가능, custom은 bottom sheet 입력 후 `Custom (x/y)`로 반영.
- 타이머 불변식: Break 중 Focus 동결, Break 공유 예산 유지(재진입 시 리셋 없음), remaining 0 clamp.
- Decision (MVP): Break 타이머가 0에 도달하면 사용자 입력 없이 자동으로 Focus로 복귀한다. (토글/A-B 없음)
- 시간 계산: `phaseStartedAt + baseRemaining` 기반 getter(`currentFocusRemainingSeconds`, `currentBreakRemainingSeconds`).
- 기록: `SessionRecord`를 `shared_preferences` 키 `resession_session_records_v1`로 저장/로드.
- Session title: Home 입력(`지금 할 일(선택)`) -> Start 전달 -> Save 시 record 반영 -> End/History/Home Recent에 표시(미입력 시 `Untitled`).
- History 화면: Home에서 진입 가능, 최신순 목록 + mm:ss(actual focus/break) + 최소 Insight(최근 최대 7개 평균 Focus) 표시.
- 공통 UI: `session_template`, `session_status_card`, `preset_selector`, `primary_cta_button` 재사용.

## Known Gaps / Risks
- 현재 브랜치에는 한 커밋에 여러 마이크로태스크 변경이 함께 포함된 이력이 있어 변경 추적성이 낮을 수 있다.
- iOS/Android 디바이스 실주행 검증은 보장하지 않으며, 현재 검증 경로는 macOS/Chrome 중심이다.
- History/Insight는 최소 구현이며, 고급 통계(기간 필터, 추세, 완료율 분해)는 미구현이다.
- 자동복귀는 MVP 결정이며, 사용자 선호 차이는 후속 사용자 테스트/데모 피드백으로 검증한다. (옵션 토글/A-B는 MVP 범위 밖)

## How to Run / Test
기준 경로:
```bash
cd /Users/mrtmi/Desktop/Mr_TMI/vibe/apps/resession
```

앱 실행 (로컬):
```bash
flutter pub get
flutter run -d macos
# 또는
flutter run -d chrome
```

품질 게이트:
```bash
dart format .
flutter analyze
flutter test
```

작성 시점 근거 로그:
- `flutter analyze`: No issues found!
- `flutter test`: All tests passed! (10 tests)
- `flutter run -d chrome --no-resident`: Application finished.

## Workflow Rules (finish -> verify -> commit -> push)
- 최소 변경 원칙: 요청 범위 밖 수정/리팩토링 금지.
- 작업 완료 기준: 기능 반영 + 필요한 테스트/검증 로그 확보.
- 완료마다 반드시 수행:
  1) `git add -A`
  2) Conventional Commit으로 1 작업 1 커밋
  3) 현재 브랜치 push (`git push` / 업스트림 없으면 `git push -u origin HEAD`)
- push 실패 시 즉시 `git remote -v` 확인 후 업스트림/리모트 문제를 해결하고 재시도.

## Next Tasks (Prioritized)
1) Drift 로그(v0.1 optional) 입력/저장 경로 추가 및 End/History 연동.
2) History Insight 확장(예: 오늘 총 Focus, 최근 N개 완료율) + 필터 최소 UI.
3) Session title UX 보강(길이 제한, 공백/중복 처리 가드레일, 관련 테스트 추가).
4) (Future) Auto-resume 토글/A-B는 MVP 이후에만 고려한다(사용자 테스트 결과 기반).
